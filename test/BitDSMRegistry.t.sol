// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitDSMRegistry.sol";

contract BitDSMRegistryTest is Test {
    BitDSMRegistry public registry;
    address public owner;
    address public operator;
    bytes public validBtcPublicKey;

    function setUp() public {
        owner = address(this);
        operator = address(0x1234);
        validBtcPublicKey = hex"02a0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde";

        registry = new BitDSMRegistry();
        registry.initialize(owner);
    }

    function testRegisterOperator() public {
        vm.prank(operator);
        registry.registerOperator(validBtcPublicKey);

        assertTrue(registry.isOperatorRegistered(operator));
        assertEq(registry.getOperatorBtcPublicKey(operator), validBtcPublicKey);
    }

    function testCannotRegisterTwice() public {
        vm.startPrank(operator);
        registry.registerOperator(validBtcPublicKey);
        
        vm.expectRevert("Operator already registered");
        registry.registerOperator(validBtcPublicKey);
        vm.stopPrank();
    }

    function testDeregisterOperator() public {
        vm.startPrank(operator);
        registry.registerOperator(validBtcPublicKey);
        registry.deregisterOperator();
        vm.stopPrank();

        assertFalse(registry.isOperatorRegistered(operator));
    }

    function testCannotDeregisterUnregisteredOperator() public {
        vm.prank(operator);
        vm.expectRevert("Operator not registered");
        registry.deregisterOperator();
    }

    function testInvalidBtcPublicKeyLength() public {
        bytes memory invalidKey = hex"01a0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde00";
        vm.prank(operator);
        vm.expectRevert("Invalid Bitcoin public key length");
        registry.registerOperator(invalidKey);
    }

    function testPauseAndUnpause() public {
        registry.pause();
        
        vm.prank(operator);
        vm.expectRevert("Pausable: paused");
        registry.registerOperator(validBtcPublicKey);

        registry.unpause();

        vm.prank(operator);
        registry.registerOperator(validBtcPublicKey);
        assertTrue(registry.isOperatorRegistered(operator));
    }

    function testOnlyOwnerCanPauseAndUnpause() public {
        vm.prank(operator);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.pause();

        vm.prank(operator);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.unpause();
    }
}

