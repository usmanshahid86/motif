// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {BitDSMAVS} from "../src/BitDSMAVS.sol";
import {MockAVSDeployer} from "@eigenlayer-middleware/test/utils/MockAVSDeployer.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/Test.sol";
import {BitDSMDeploymentLib} from "../script/utils/BitDSMDeploymentLib.sol";
import {CoreDeploymentLib} from "../script/utils/CoreDeploymentLib.sol";
import {UpgradeableProxyLib} from "../script/utils/UpgradeableProxyLib.sol";

import {
    Quorum,
    StrategyParams,
    IStrategy
} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";

contract BitDSMTaskManagerSetup is MockAVSDeployer {
    Quorum internal quorum;

    struct Operator {
        Vm.Wallet key;
        Vm.Wallet signingKey;
    }

    struct TrafficGenerator {
        Vm.Wallet key;
    }

    Operator[] internal operators;
    TrafficGenerator internal generator;

    BitDSMDeploymentLib.DeploymentData internal bitdsmDeployment;
    CoreDeploymentLib.DeploymentData internal coreDeployment;
    CoreDeploymentLib.DeploymentConfigData coreConfigData;

    function setUp() public virtual {
        operators.push(
            Operator({
                key: vm.createWallet("operator"),
                signingKey: vm.createWallet("operator_signing_wallet")
            })
        );

        generator = TrafficGenerator({key: vm.createWallet("generator_wallet")});

        address proxyAdmin = UpgradeableProxyLib.deployProxyAdmin();

        coreConfigData =
            CoreDeploymentLib.readDeploymentConfigValues("test/mockData/config/core/", 1337); // TODO: Fix this to correct path
        coreDeployment = CoreDeploymentLib.deployContracts(proxyAdmin, coreConfigData);

        quorum.strategies.push(
            StrategyParams({strategy: IStrategy(address(420)), multiplier: 10_000})
        );

        bitdsmDeployment =
            BitDSMDeploymentLib.deployContracts(proxyAdmin, proxyAdmin, proxyAdmin, coreDeployment, quorum);
        labelContracts(coreDeployment, bitdsmDeployment);
    }

    function labelContracts(
        CoreDeploymentLib.DeploymentData memory coreDeploymenttest,
        BitDSMDeploymentLib.DeploymentData memory bitdsmDeploymenttest
    ) internal {
        vm.label(coreDeploymenttest.delegationManager, "DelegationManager");
        vm.label(coreDeploymenttest.avsDirectory, "AVSDirectory");
        vm.label(coreDeploymenttest.strategyManager, "StrategyManager");
        vm.label(coreDeploymenttest.eigenPodManager, "EigenPodManager");
        vm.label(coreDeploymenttest.rewardsCoordinator, "RewardsCoordinator");
        vm.label(coreDeploymenttest.eigenPodBeacon, "EigenPodBeacon");
        vm.label(coreDeploymenttest.pauserRegistry, "PauserRegistry");
        vm.label(coreDeploymenttest.wethStrategy, "WETHStrategy");

        vm.label(bitdsmDeploymenttest.bitDSMServiceManager, "BitDSMServiceManager");
        vm.label(bitdsmDeploymenttest.stakeRegistry, "StakeRegistry");
        vm.label(bitdsmDeploymenttest.wethStrategy, "WETHStrategy");
    }
}

contract BitDSMServiceManagerInitialization is BitDSMTaskManagerSetup {
    function testInitialization() public view {
        assertTrue(bitdsmDeployment.stakeRegistry != address(0), "Not deployed");
        assertTrue(bitdsmDeployment.bitDSMServiceManager != address(0), "Not deployed");
        assertTrue(coreDeployment.delegationManager != address(0), "Not deployed");
        assertTrue(coreDeployment.avsDirectory != address(0), "Not deployed");
        assertTrue(coreDeployment.strategyManager != address(0), "Not deployed");
        assertTrue(coreDeployment.eigenPodManager != address(0), "Not deployed");
    }
}
