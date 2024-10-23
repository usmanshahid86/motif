// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IAVSDirectory} from "@eigenlayer-middleware/src/interfaces/IAVSDirectory.sol";
import {IDelegationManager} from "@eigenlayer-middleware/src/interfaces/IDelegationManager.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";
import {AppRegistry} from "../src/core/AppRegistry.sol";
import {BitcoinPodManager} from "../src/core/BitcoinPodManager.sol";
import {BitDSMRegistry} from "../src/core/BitDSMRegistry.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableProxyLib} from "./utils/UpgradeableProxyLib.sol";

import {Quorum, StrategyParams, IStrategy} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";

contract DeployBitDSM is Script {
    using UpgradeableProxyLib for address;

    uint256 deployerPrivateKey;
    address deployer;

    ProxyAdmin public proxyAdmin;
    IAVSDirectory public avsDirectory;
    IDelegationManager public delegationManager;

    Quorum quorum;
    uint256 thresholdWeight = 6667;

    AppRegistry public appRegistry;
    BitcoinPodManager public bitcoinPodManager;
    BitDSMRegistry public bitDSMRegistry;

    function _loadEigenlayerAddresses(string memory targetEnv) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/eigenlayer_addresses.json");
        string memory json = vm.readFile(path);

        avsDirectory = IAVSDirectory(json.readAddress(string(abi.encodePacked(".", targetEnv, ".avsDirectory"))));
        delegationManager = IDelegationManager(json.readAddress(string(abi.encodePacked(".", targetEnv, ".delegationManager"))));

        StrategyParams[] memory strategies = abi.decode(
            json.parseRaw(string(abi.encodePacked(".", targetEnv, ".strategies"))),
            (StrategyParams[])
        );

        for (uint256 i = 0; i < strategies.length; i++) {
            quorum.strategies.push(strategies[i]);
        }
    }

    function run(string memory network, string memory metadataUri) external {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        _loadEigenlayerAddresses(network);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin();

        // Deploy AppRegistry
        AppRegistry appRegistryImpl = new AppRegistry();
        TransparentUpgradeableProxy appRegistryProxy = new TransparentUpgradeableProxy(
            address(appRegistryImpl),
            address(proxyAdmin),
            abi.encodeCall(AppRegistry.initialize, (deployer))
        );
        appRegistry = AppRegistry(address(appRegistryProxy));

        // Deploy BitDSMRegistry
        BitDSMRegistry bitDSMRegistryImpl = new BitDSMRegistry();
        TransparentUpgradeableProxy bitDSMRegistryProxy = new TransparentUpgradeableProxy(
            address(bitDSMRegistryImpl),
            address(proxyAdmin),
            abi.encodeCall(BitDSMRegistry.initialize, (deployer))
        );
        bitDSMRegistry = BitDSMRegistry(address(bitDSMRegistryProxy));

        // Deploy BitcoinPodManager
        BitcoinPodManager bitcoinPodManagerImpl = new BitcoinPodManager();
        TransparentUpgradeableProxy bitcoinPodManagerProxy = new TransparentUpgradeableProxy(
            address(bitcoinPodManagerImpl),
            address(proxyAdmin),
            abi.encodeCall(BitcoinPodManager.initialize, (address(appRegistry), address(bitDSMRegistry)))
        );
        bitcoinPodManager = BitcoinPodManager(address(bitcoinPodManagerProxy));

        // Deploy ECDSAStakeRegistry
        ECDSAStakeRegistry stakeRegistryImpl = new ECDSAStakeRegistry(delegationManager);
        TransparentUpgradeableProxy stakeRegistryProxy = new TransparentUpgradeableProxy(
            address(stakeRegistryImpl),
            address(proxyAdmin),
            ""
        );

        // Deploy BitDSMServiceManager
        BitDSMServiceManager serviceManagerImpl = new BitDSMServiceManager(
            address(avsDirectory),
            address(stakeRegistryProxy),
            address(delegationManager)
        );

        TransparentUpgradeableProxy serviceManagerProxy = new TransparentUpgradeableProxy(
            address(serviceManagerImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(BitDSMServiceManager.initialize.selector, deployer)
        );

        // Initialize the ECDSAStakeRegistry
        ECDSAStakeRegistry(address(stakeRegistryProxy)).initialize(
            address(serviceManagerProxy),
            thresholdWeight,
            quorum
        );

        BitDSMServiceManager serviceManager = BitDSMServiceManager(address(serviceManagerProxy));
        serviceManager.updateAVSMetadataURI(metadataUri);

        vm.stopBroadcast();

        console.log("ProxyAdmin: ", address(proxyAdmin));
        console.log("AppRegistry Proxy: ", address(appRegistry));
        console.log("BitDSMRegistry Proxy: ", address(bitDSMRegistry));
        console.log("BitcoinPodManager Proxy: ", address(bitcoinPodManager));
        console.log("ECDSAStakeRegistry Proxy: ", address(stakeRegistryProxy));
        console.log("BitDSMServiceManager Proxy: ", address(serviceManagerProxy));
    }
}
