// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@eigenlayer/contracts/permissions/PauserRegistry.sol";
import {IDelegationManager} from "@eigenlayer/contracts/interfaces/IDelegationManager.sol";
import {IAVSDirectory} from "@eigenlayer/contracts/interfaces/IAVSDirectory.sol";
import {IStrategyManager, IStrategy} from "@eigenlayer/contracts/interfaces/IStrategyManager.sol";
import {StrategyBaseTVLLimits} from "@eigenlayer/contracts/strategies/StrategyBaseTVLLimits.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {Quorum, StrategyParams} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";
import {BitDSMAVS} from "../src/BitDSMAVS.sol";
import "@eigenlayer/test/mocks/EmptyContract.sol";
import "@eigenlayer-middleware/src/ServiceManagerBase.sol";
import "../src/ERC20Mock.sol";
import "../src/BodManager.sol";
import "../src/Bod.sol";
import "../src/CDPContract.sol";
import "forge-std/StdJson.sol";
import "forge-std/console.sol";
import {Utils} from "./utils/Utils.sol";

contract BitDSMDeployer is Script, Utils {
    // ERC20 and Strategy: we need to deploy this erc20, create a strategy for it, and whitelist this strategy in the strategy manager

    ERC20Mock public erc20Mock;
    StrategyBaseTVLLimits public erc20MockStrategy;

    // BitDSM contracts
    ProxyAdmin public bitDSMProxyAdmin;
    PauserRegistry public bitDSMPauserReg;
    
    ECDSAStakeRegistry public stakeRegistryProxy;
    ECDSAStakeRegistry public stakeRegistryImplementation;

    BitDSMAVS public bitDSMAVSProxy;
    BitDSMAVS public bitDSMAVSImplementation;

    function run() external {
        // Manually pasted addresses of Eigenlayer contracts
        address strategyManagerAddr = 0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6;
        address delegationManagerAddr = 0xA44151489861Fe9e3055d95adC98FbD462B948e7;
        address avsDirectoryAddr = 0x055733000064333CaDDbC92763c58BF0192fFeBf;
        address eigenLayerProxyAdminAddr = 0xDB023566064246399b4AE851197a97729C93A6cf;
        address eigenLayerPauserRegAddr = 0x85Ef7299F8311B25642679edBF02B62FA2212F06;
        address baseStrategyImplementationAddr = 0xFb83e1D133D0157775eC4F19Ff81478Df1103305;

        IStrategyManager strategyManager = IStrategyManager(strategyManagerAddr);
        IDelegationManager delegationManager = IDelegationManager(delegationManagerAddr);
        IAVSDirectory avsDirectory = IAVSDirectory(avsDirectoryAddr);
        ProxyAdmin eigenLayerProxyAdmin = ProxyAdmin(eigenLayerProxyAdminAddr);
        PauserRegistry eigenLayerPauserReg = PauserRegistry(eigenLayerPauserRegAddr);
        StrategyBaseTVLLimits baseStrategyImplementation = StrategyBaseTVLLimits(baseStrategyImplementationAddr);

        address bitDSMCommunityMultisig = msg.sender;
        address bitDSMPauser = msg.sender;

        vm.startBroadcast();
        _deployERC20AndStrategyAndWhitelistStrategy(
            eigenLayerProxyAdmin,
            eigenLayerPauserReg,
            baseStrategyImplementation,
            strategyManager
        );
        _deployBitDSMContracts(
            delegationManager,
            avsDirectory,
            baseStrategyImplementation,
            bitDSMCommunityMultisig,
            bitDSMPauser
        );
        vm.stopBroadcast();
    }

    function _deployERC20AndStrategyAndWhitelistStrategy(
        ProxyAdmin eigenLayerProxyAdmin,
        PauserRegistry eigenLayerPauserReg,
        StrategyBaseTVLLimits baseStrategyImplementation,
        IStrategyManager strategyManager
    ) internal {
        erc20Mock = new ERC20Mock();
        // Deploy the ERC20 strategy with TVL limits
        erc20MockStrategy = StrategyBaseTVLLimits(
            address(
                new TransparentUpgradeableProxy(
                    address(baseStrategyImplementation),
                    address(eigenLayerProxyAdmin),
                    abi.encodeWithSelector(
                        StrategyBaseTVLLimits.initialize.selector,
                        1 ether, // maxPerDeposit
                        100 ether, // maxDeposits
                        IERC20(erc20Mock),
                        eigenLayerPauserReg
                    )
                )
            )
        );
        IStrategy[] memory strats = new IStrategy[](1);
        strats[0] = erc20MockStrategy;
        bool[] memory thirdPartyTransfersForbiddenValues = new bool[](1);
        thirdPartyTransfersForbiddenValues[0] = false;
        strategyManager.addStrategiesToDepositWhitelist(
            strats,
            thirdPartyTransfersForbiddenValues
        );
    }

    function _deployBitDSMContracts(
        IDelegationManager delegationManager,
        IAVSDirectory avsDirectory,
        IStrategy baseStrategyImplementation,
        address bitDSMCommunityMultisig,
        address bitDSMPauser
    ) internal {
        // Deploy proxy admin for ability to upgrade proxy contracts
        bitDSMProxyAdmin = new ProxyAdmin(msg.sender);

        // Deploy pauser registry
        {
            address[] memory pausers = new address[](2);
            pausers[0] = bitDSMPauser;
            pausers[1] = bitDSMCommunityMultisig;
            bitDSMPauserReg = new PauserRegistry(
                pausers,
                bitDSMCommunityMultisig
            );
        }

        EmptyContract emptyContract = new EmptyContract();

        // First, deploy upgradeable proxy contracts that will point to the implementations.
        bitDSMAVSProxy = BitDSMAVS(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(bitDSMProxyAdmin),
                    ""
                )
            )
        );
        stakeRegistryProxy = ECDSAStakeRegistry(
            address(
                new TransparentUpgradeableProxy(
                    address(emptyContract),
                    address(bitDSMProxyAdmin),
                    ""
                )
            )
        );

         

       // Second, deploy the implementation contracts, using the proxy contracts as inputs
        {
            stakeRegistryImplementation = new ECDSAStakeRegistry(
                delegationManager
            );

            bitDSMProxyAdmin.upgrade(
                TransparentUpgradeableProxy(payable(address(stakeRegistryProxy))),
                address(stakeRegistryImplementation)
            );
        }
        {

            // Create an array with one StrategyParams element
            StrategyParams memory strategyParams = StrategyParams({
                strategy: baseStrategyImplementation,
                multiplier: 10_000
            });

            StrategyParams[] memory quorumsStrategyParams = new StrategyParams[](1);
            quorumsStrategyParams[0] = strategyParams;

            Quorum memory quorum = Quorum(
                quorumsStrategyParams
            );

            bitDSMProxyAdmin.upgradeAndCall(
                TransparentUpgradeableProxy(payable(address(stakeRegistryProxy))),
                address(stakeRegistryImplementation),
                abi.encodeWithSelector(
                    ECDSAStakeRegistry.initialize.selector,
                    address(bitDSMAVSProxy),
                    1,
                    quorum
                )
            );
        }

        bitDSMAVSImplementation = new BitDSMAVS(
            avsDirectory,
            IRegistryCoordinator(address(stakeRegistryProxy)),
            IStakeRegistry(address(stakeRegistryProxy)),
            address(new BodManager()),
            address(new CDPContract(address(new Bod())))
        );
        // Upgrade the proxy contracts to use the correct implementation contracts and initialize them.
        bitDSMProxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(
                payable(address(bitDSMAVSProxy))
            ),
            address(bitDSMAVSImplementation),
            abi.encodeWithSelector(
                BitDSMAVS.initialize.selector,
                avsDirectory,
                IRegistryCoordinator(address(stakeRegistryProxy)),
                IStakeRegistry(address(stakeRegistryProxy)),
                address(new BodManager()),
                address(new CDPContract(address(new Bod())))
            )
        );

        // WRITE JSON DATA
        string memory parent_object = "parent object";

        string memory deployed_addresses = "addresses";
        vm.serializeAddress(
            deployed_addresses,
            "BitDSMAVSProxy",
            address(bitDSMAVSProxy)
        );
        vm.serializeAddress(
            deployed_addresses,
            "BitDSMAVSImplementation",
            address(bitDSMAVSImplementation)
        );
        vm.serializeAddress(
            deployed_addresses,
            "ECDSAStakeRegistry",
            address(stakeRegistryProxy)
        );
        
        string memory deployed_addresses_output = vm.serializeAddress(
            deployed_addresses,
            "ECDSAStakeRegistryImplementation",
            address(stakeRegistryImplementation)
        );

        // Serialize all the data
        string memory finalJson = vm.serializeString(
            parent_object,
            deployed_addresses,
            deployed_addresses_output
        );

        writeOutput(finalJson, "bit_dsm_avs_holesky_deployment_output");
    }
}