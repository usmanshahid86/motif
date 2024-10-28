// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitDSMRegistry.sol";
import "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";

contract BitDSMRegistryTest is Test {
    BitDSMRegistry public registry;
    address public owner;
    address public operator;
    bytes public validBtcPublicKey;
    IDelegationManager public mockDelegationManager;

    function setUp() public {
        owner = address(this);
        operator = address(0x1234);
        validBtcPublicKey = hex"02a0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde";

        mockDelegationManager = IDelegationManager(address(new MockDelegationManager()));
        registry = new BitDSMRegistry(mockDelegationManager);
        registry.initialize(address(this), 1000, Quorum({strategies: new StrategyParams[](0)}));
    }

    function testRegisterOperator() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory sig;
        vm.prank(operator);
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);

        assertTrue(registry.isOperatorRegistered(operator));
        assertEq(registry.getOperatorBtcPublicKey(operator), validBtcPublicKey);
    }

    function testCannotRegisterTwice() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory sig;
        vm.startPrank(operator);
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);
        
        vm.expectRevert("Operator already registered");
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);
        vm.stopPrank();
    }

    function testDeregisterOperator() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory sig;
        vm.startPrank(operator);
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);
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
        ISignatureUtils.SignatureWithSaltAndExpiry memory sig;
        bytes memory invalidKey = hex"01a0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde00";
        vm.prank(operator);
        vm.expectRevert("Invalid Bitcoin public key length");
        registry.registerOperatorWithSignature(sig, operator, invalidKey);
    }

    function testPauseAndUnpause() public {
        registry.pause();
        
        ISignatureUtils.SignatureWithSaltAndExpiry memory sig;
        vm.prank(operator);
        vm.expectRevert("Pausable: paused");
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);

        registry.unpause();

        vm.prank(operator);
        registry.registerOperatorWithSignature(sig, operator, validBtcPublicKey);
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

contract MockDelegationManager is IDelegationManager {
    function delegatedTo(address) external pure returns (address) {
        return address(0);
    }
    // Implement other required functions...
}
