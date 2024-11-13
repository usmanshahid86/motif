// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitDSMRegistry.sol";
import "../src/core/BitcoinPodManager.sol";
import "../src/core/BitcoinPod.sol";
import {AppRegistry} from "../src/core/AppRegistry.sol";
import {IBitDSMRegistry} from "../src/interfaces/IBitDSMRegistry.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";
import {IDelegationManager} from "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {IStrategy} from "@eigenlayer/src/contracts/interfaces/IStrategy.sol";
import {Quorum, StrategyParams} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";

contract MockServiceManager {
    // solhint-disable-next-line
    function deregisterOperatorFromAVS(address) external {}

    function registerOperatorToAVS(
        address,
        ISignatureUtils.SignatureWithSaltAndExpiry memory // solhint-disable-next-line
    ) external {}
}

contract MockDelegationManager {
    function operatorShares(address, address) external pure returns (uint256) {
        return 1000; // Return a dummy value for simplicity
    }

    function getOperatorShares(
        address,
        address[] memory strategies
    ) external pure returns (uint256[] memory) {
        uint256[] memory response = new uint256[](strategies.length);
        for (uint256 i; i < strategies.length; i++) {
            response[i] = 1000;
        }
        return response; // Return a dummy value for simplicity
    }
}



contract BitcoinPodManagerTest is Test {
    BitDSMRegistry public bitDSMRegistry;
    BitcoinPodManager public podManager;
    AppRegistry public appRegistry;
    address public owner;
    MockDelegationManager public delegationManager;
    MockServiceManager public serviceManager;
    address public operator;
    address public user;
    bytes public operatorBtcPubKey;
    bytes public userBtcAddress;

    function setUp() public {
        delegationManager = new MockDelegationManager();
        serviceManager = new MockServiceManager();
        
        bitDSMRegistry = new BitDSMRegistry(IDelegationManager(address(delegationManager)));
       
        // initialize strategy
        IStrategy mockStrategy = IStrategy(address(0x1234));
        Quorum memory quorum = Quorum({strategies: new StrategyParams[](1)});
        quorum.strategies[0] = StrategyParams({
            strategy: mockStrategy,
            multiplier: 10_000
        });
        
        bitDSMRegistry.initialize(address(serviceManager), 100, quorum); 

        appRegistry = new AppRegistry();
        owner = address(this);
        appRegistry.initialize(owner);

        podManager = new BitcoinPodManager();
        podManager.initialize(address(appRegistry), address(bitDSMRegistry), address(0));

        operator = address(0x1);
        user = address(0x2);
        operatorBtcPubKey = hex"02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5dc";
        userBtcAddress = hex"76a914ca29dfa9e97fa4f0623742e4f7b90f81bfe5671b88ac";
    }

    function testOperatorRegistration() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.startPrank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);
        vm.stopPrank();

        assertTrue(bitDSMRegistry.operatorRegistered(operator), "Operator should be registered");
        assertEq(bitDSMRegistry.getOperatorBtcPublicKey(operator), operatorBtcPubKey, "Operator BTC public key should match");
    }

    function testPodCreation() public {
        // First, register the operator
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Now, create a pod as the user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);

        address podAddress = podManager.getUserPod(user);
        assertTrue(podAddress != address(0), "Pod should be created");

        BitcoinPod pod = BitcoinPod(podAddress);
        assertEq(pod.owner(), user, "Pod owner should be the user");
        assertEq(pod.getOperator(), operator, "Pod operator should be set correctly");
        assertEq(pod.getBitcoinAddress(), userBtcAddress, "Bitcoin address should be set correctly");
        assertEq(pod.getOperatorBtcPubKey(), operatorBtcPubKey, "Operator BTC public key should be set correctly");
    }

    function testCannotCreatePodWithUnregisteredOperator() public {
        vm.prank(user);
        vm.expectRevert("Invalid operator");
        podManager.createPod(operator, userBtcAddress);
    }

    function testCannotCreateMultiplePods() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;  
        // Register operator
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Create first pod
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);

        // Try to create second pod
        vm.prank(user);
        vm.expectRevert("User already has a pod");
        podManager.createPod(operator, userBtcAddress);
    }

    function testUserCannotMintBurnOrDeposit() public {
        // Register operator and create pod
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);
        
        address podAddress = podManager.getUserPod(user);
        BitcoinPod pod = BitcoinPod(podAddress);

        vm.startPrank(user);
        
        // Test mint
        vm.expectRevert("Only manager can call this function");
        pod.mint(operator, 100);

        // Test burn
        vm.expectRevert("Only manager can call this function");
        pod.burn(operator, 50);

        // Remove the deposit test as it's not part of the BitcoinPod contract

        vm.stopPrank();
    }

    function testArbitraryAddressCannotMintOrBurn() public {
        // Register operator and create pod
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator,operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);
        
        address podAddress = podManager.getUserPod(user);
        BitcoinPod pod = BitcoinPod(podAddress);

        address arbitraryAddress = address(0x1234);
        vm.startPrank(arbitraryAddress);
        
        // Test mint
        vm.expectRevert("Only manager can call this function");
        pod.mint(operator, 100);

        // Test burn
        vm.expectRevert("Only manager can call this function");
        pod.burn(operator, 50);

        vm.stopPrank();
    }

    function testPodCreationAndOwnership() public {
        // Register operator
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Create pod as user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);

        // Get the pod address
        address podAddress = podManager.getUserPod(user);

        // Check if the pod address is a contract
        assertTrue(podAddress.code.length > 0, "Pod address should be a contract");
    }
}