// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/BodManager.sol";

contract BodManagerTest is Test {
    BodManager public bodManager;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        bodManager = new BodManager();
        bodManager.initialize(owner);
    }

    function testCreateBod() public {
        vm.prank(user1);
        address bodAddress = bodManager.createBod();
        assertTrue(bodAddress != address(0), "Bod should be created");
        assertTrue(bodManager.hasBod(user1), "User1 should have a Bod");
    }

    function testCannotCreateMultipleBods() public {
        vm.startPrank(user1);
        bodManager.createBod();
        vm.expectRevert("BodManager: Sender already has a bod");
        bodManager.createBod();
        vm.stopPrank();
    }

    function testLockBitcoin() public {
        vm.startPrank(user1);
        bodManager.createBod();
        bytes32 btcTxHash = keccak256("btc_tx_hash");
        bodManager.lockBitcoin(btcTxHash, 1 ether);
        vm.stopPrank();

        Bod bod = bodManager.ownerToBod(user1);
        assertEq(bod.lockedBitcoin(), 1 ether, "Bitcoin should be locked in the Bod");
    }

    function testCannotLockBitcoinWithoutBod() public {
        vm.prank(user2);
        vm.expectRevert("BodManager: Sender does not have a bod");
        bodManager.lockBitcoin(bytes32(0), 1 ether);
    }
}
