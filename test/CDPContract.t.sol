// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/CDPContract.sol";
import "../src/Bod.sol";
import "../src/BodManager.sol";

contract CDPContractTest is Test {
    CDPContract public cdpContract;
    BodManager public bodManager;
    Bod public bod;
    address public owner;

    function setUp() public {
        owner = address(this);

        bodManager = new BodManager();
        bodManager.initialize(owner);

        address bodAddress = bodManager.createBod("testBitcoinAddress");
        bod = Bod(bodAddress);

        bytes32 btcTxHash = keccak256("btc_tx_hash");
        bodManager.lockBitcoin(btcTxHash, 100 ether);

        cdpContract = new CDPContract(address(bod));
    }

    function testMintStablecoin() public {
        uint256 mintAmount = 50 ether;
        cdpContract.mintStablecoin(mintAmount);
        assertEq(cdpContract.balanceOf(owner), mintAmount, "Stablecoin balance should be correct");
    }

    function testBurnStablecoin() public {
        uint256 mintAmount = 50 ether;
        cdpContract.mintStablecoin(mintAmount);

        uint256 burnAmount = 20 ether;
        cdpContract.burnStablecoin(burnAmount);
        assertEq(cdpContract.balanceOf(owner), mintAmount - burnAmount, "Stablecoin balance should be correct after burning");
    }

    function testCannotMintExceedingCollateral() public {
        uint256 maxMintAmount = (100 ether * 100) / cdpContract.COLLATERAL_RATIO();
        vm.expectRevert("CDPContract: Exceeds maximum mintable amount");
        cdpContract.mintStablecoin(maxMintAmount + 1);
    }

    function testLiquidation() public {
        uint256 mintAmount = 60 ether; // This will put the CDP below the liquidation threshold
        cdpContract.mintStablecoin(mintAmount);

        cdpContract.liquidate();
        assertTrue(cdpContract.totalSupply() < mintAmount, "Total supply should decrease after liquidation");
    }

    function testCannotUnlockWithOutstandingDebt() public {
        cdpContract.mintStablecoin(10 ether);
        vm.expectRevert("CDPContract: Cannot unlock while stablecoins are in circulation");
        cdpContract.unlockBod();
    }
}
