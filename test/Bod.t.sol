// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/Bod.sol";

contract BodTest is Test {
    Bod public bod;
    address public owner;
    address public bodManager;

    function setUp() public {
        owner = address(this);
        bodManager = address(0x1);

        bod = new Bod();
        bod.initialize(owner, bodManager);
    }

    function testInitialize() public view {
        assertEq(bod.bodOwner(), owner, "Bod owner should be set correctly");
        assertEq(bod.bodManager(), bodManager, "Bod manager should be set correctly");
    }

    function testLockBitcoin() public {
        bytes32 btcTxHash = keccak256("btc_tx_hash");
        uint256 amount = 1 ether;

        vm.prank(bodManager);
        bod.lockBitcoin(btcTxHash, amount);

        assertEq(bod.lockedBitcoin(), amount, "Locked Bitcoin amount should be correct");
    }

    function testLockAndUnlock() public {
        vm.prank(owner);
        bod.lock();
        assertTrue(bod.isLocked(), "Bod should be locked");

        vm.prank(owner);
        bod.unlock();
        assertFalse(bod.isLocked(), "Bod should be unlocked");
    }

    function testCannotLockBitcoinWhenLocked() public {
        vm.prank(owner);
        bod.lock();

        bytes32 btcTxHash = keccak256("btc_tx_hash");
        uint256 amount = 1 ether;

        vm.prank(bodManager);
        vm.expectRevert("Bod: locked");
        bod.lockBitcoin(btcTxHash, amount);
    }
}
