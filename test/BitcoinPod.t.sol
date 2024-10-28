// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Test} from "forge-std/Test.sol";
import {BitDSMRegistry} from "../src/core/BitDSMRegistry.sol";
import {BitcoinPodManager} from "../src/core/BitcoinPodManager.sol";
import {BitcoinPod} from "../src/core/BitcoinPod.sol";
import {AppRegistry} from "../src/core/AppRegistry.sol";

contract BitcoinPodManagerTest is Test {
    BitDSMRegistry public bitDSMRegistry;
    BitcoinPodManager public podManager;
    AppRegistry public appRegistry;
    address public owner;

    address public operator;
    address public user;
    bytes public operatorBtcPubKey;
    bytes public userBtcAddress;

    function setUp() public {
        bitDSMRegistry = new BitDSMRegistry();
        bitDSMRegistry.initialize(address(this));

        appRegistry = new AppRegistry();
        owner = address(this);
        appRegistry.initialize(owner);

        podManager = new BitcoinPodManager();
        podManager.initialize(address(appRegistry), address(bitDSMRegistry));

        operator = address(0x1);
        user = address(0x2);
        operatorBtcPubKey = hex"02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5dc";
        userBtcAddress = hex"76a914ca29dfa9e97fa4f0623742e4f7b90f81bfe5671b88ac";
    }

    function testOperatorRegistration() public {
        vm.startPrank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);
        vm.stopPrank();

        assertTrue(bitDSMRegistry.isOperatorRegistered(operator), "Operator should be registered");
        assertEq(bitDSMRegistry.getOperatorBtcPublicKey(operator), operatorBtcPubKey, "Operator BTC public key should match");
    }

    function testPodCreation() public {
        // First, register the operator
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);

        // Now, create a pod as the user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);

        address podAddress = podManager.userToPod(user);
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
        // Register operator
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);

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
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);
        
        address podAddress = podManager.userToPod(user);
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
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);
        
        address podAddress = podManager.userToPod(user);
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

    function testOperatorCanMintAndBurn() public {
        // Register operator and create pod
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);
        
        address podAddress = podManager.userToPod(user);
        BitcoinPod pod = BitcoinPod(podAddress);

        vm.startPrank(operator);
        
        // Test mint
        podManager.mintBitcoin(podAddress, 100);
        assertEq(pod.getBitcoinBalance(), 100, "Balance should be 100 after minting");

        // Test burn
        podManager.burnBitcoin(podAddress, 50);
        assertEq(pod.getBitcoinBalance(), 50, "Balance should be 50 after burning");

        vm.stopPrank();
    }

    function testPodCreationAndOwnership() public {
        // Register operator
        vm.prank(operator);
        bitDSMRegistry.registerOperator(operatorBtcPubKey);

        // Create pod as user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress);

        // Get the pod address
        address podAddress = podManager.userToPod(user);

        // Check if the pod address is a contract
        assertTrue(podAddress.code.length > 0, "Pod address should be a contract");
    }
}
