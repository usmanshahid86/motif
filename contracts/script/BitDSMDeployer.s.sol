// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Test.sol";
import {Utils} from "./utils/Utils.sol";
import {BitDSMDeploymentLib} from "./utils/BitDSMDeploymentLib.sol";
import {CoreDeploymentLib} from "./utils/CoreDeploymentLib.sol";
import {UpgradeableProxyLib} from "./utils/UpgradeableProxyLib.sol";
import {BodManager} from "../src/BodManager.sol";
import {Bod} from "../src/Bod.sol";
import {CDPContract} from "../src/CDPContract.sol";


import {
    Quorum,
    StrategyParams,
    IStrategy
} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";

// # To deploy and verify our contract
// forge script script/BitDSMDeployer.s.sol:BitDSMDeployer --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
contract BitDSMDeployer is Script, Utils {
    using CoreDeploymentLib for *;
    using UpgradeableProxyLib for address;

    address private deployer;
    address proxyAdmin;
    CoreDeploymentLib.DeploymentData coreDeployment;
    BitDSMDeploymentLib.DeploymentData bitdsmDeployment;
    address private bodManagerAddress;
    address private cdpContractAddress;

    Quorum internal quorum;

    function setUp() public virtual {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        vm.label(deployer, "Deployer");

        coreDeployment = CoreDeploymentLib.readDeploymentJson("deployments/core/", block.chainid);
        
        // Assuming the bodManager and cdpContractAddress is already deployed
        // Initialize the contract addresses
        bodManagerAddress = 0x0EAe257D92b0244F4239713c4980Fc15aC2052B8;
        cdpContractAddress = 0xD77e13C8cA101da550D00A00Ca4FD6009398f8Ee;

        // Initialize restaking Strategies
        // equal weights assigned. keep the sum_multiplier = 10,000
        quorum.strategies.push(
             StrategyParams({strategy: IStrategy(address(0x05037A81BD7B4C9E0F7B430f1F2A22c31a2FD943)), multiplier: 2_000}) //lsETH
        ); 

        quorum.strategies.push(
             StrategyParams({strategy: IStrategy(address(0x3A8fBdf9e77DFc25d09741f51d3E181b25d0c4E0)), multiplier: 2_000}) //rETH
        );
        quorum.strategies.push(
             StrategyParams({strategy: IStrategy(address(0x7673a47463F80c6a3553Db9E54c8cDcd5313d0ac)), multiplier: 2_000}) //ankerETH
        );        
        quorum.strategies.push(
             StrategyParams({strategy: IStrategy(address(0x7D704507b76571a51d9caE8AdDAbBFd0ba0e63d3)), multiplier: 2_000}) //stETH
        );
        quorum.strategies.push(
        StrategyParams({strategy: IStrategy(address(0x80528D6e9A2BAbFc766965E0E26d5aB08D9CFaF9)), multiplier: 2_000}) //wETH
        );
          
     
    }

    function run() external {
        // deploying the BodManager / Bod / CDCP contract
       // vm.startBroadcast(deployer);
       // deploy_bod_manager_and_create_bod();
       // vm.stopBroadcast();

        
        vm.startBroadcast(deployer);
        proxyAdmin = UpgradeableProxyLib.deployProxyAdmin();

        bitdsmDeployment =
           BitDSMDeploymentLib.deployContracts(proxyAdmin, bodManagerAddress, cdpContractAddress, coreDeployment, quorum);
        vm.stopBroadcast();

        verifyDeployment();
        BitDSMDeploymentLib.writeDeploymentJson(bitdsmDeployment);
    }

    function deploy_bod_manager_and_create_bod() public {
        // Deploy the BodManager contract
        BodManager bodManager = new BodManager();
        bodManager.initialize(deployer);
        bodManagerAddress = address(bodManager);
        console2.log("BodManager deployed at:", address(bodManager));

        // Deploy the Bod contract
        Bod bod = new Bod();
        bod.initialize(deployer, address(bodManager), "btc_address_placeholder");
        console2.log("Bod deployed at:", address(bod));

        // After deploying Bod and before locking Bitcoin
        console2.log("Creating Bod for deployer...");
        bodManager.createBod("bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");

        console2.log("Locking Bitcoin in Bod...");
        uint256 bitcoinAmount = 2; // 2 BTC in satoshis
        bytes32 dummyTxHash = bytes32(uint256(103934764389048578)); // Dummy transaction hash
        bodManager.lockBitcoin(dummyTxHash, bitcoinAmount);
        //get lockedBitcoin
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        console2.log("Locked Bitcoin amount:", lockedBitcoin);

        console2.log("Bitcoin locked in Bod");


        // Deploy the CDP contract
        CDPContract cdp = new CDPContract(address(bod));
        cdpContractAddress = address(cdp);
        console2.log("CDP deployed at:", address(cdp));

        // Mint some stablecoin
        uint256 mintAmount = 1; // Example amount to mint
        cdp.mintStablecoin(mintAmount);

        // Log the balance of the deployer
        uint256 stablecoinBalance = cdp.balanceOf(deployer);
        console2.log("Stablecoin balance of deployer:", stablecoinBalance);
    }

 

    function verifyDeployment() internal view {
        require(
            bitdsmDeployment.stakeRegistry != address(0), "StakeRegistry address cannot be zero"
        );
        require(
            bitdsmDeployment.bitDSMServiceManager != address(0),
            "HelloWorldServiceManager address cannot be zero"
        );
        require(proxyAdmin != address(0), "ProxyAdmin address cannot be zero");
        require(
            coreDeployment.delegationManager != address(0),
            "DelegationManager address cannot be zero"
        );
        require(coreDeployment.avsDirectory != address(0), "AVSDirectory address cannot be zero");
    }
}
