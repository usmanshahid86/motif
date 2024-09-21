// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/BodManager.sol";
import "../src/Bod.sol";
import "../src/CDPContract.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the BodManager contract
        BodManager bodManager = new BodManager();
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        bodManager.initialize(deployer);

        console.log("BodManager deployed at:", address(bodManager));

        // Deploy the Bod contract
        Bod bod = new Bod();
        bod.initialize(deployer, address(bodManager), "btc_address_placeholder");

        console.log("Bod deployed at:", address(bod));

        // After deploying Bod and before locking Bitcoin
        console.log("Creating Bod for deployer...");
        bodManager.createBod("bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");

        console.log("Locking Bitcoin in Bod...");
        uint256 bitcoinAmount = 2; // 2 BTC in satoshis
        bytes32 dummyTxHash = bytes32(uint256(1)); // Dummy transaction hash
        bodManager.lockBitcoin(dummyTxHash, bitcoinAmount);
        //get lockedBitcoin
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        console.log("Locked Bitcoin amount:", lockedBitcoin);

        console.log("Bitcoin locked in Bod");

        // Deploy the CDP contract
        CDPContract cdp = new CDPContract(address(bod));

        console.log("CDP deployed at:", address(cdp));

        // Mint some stablecoin
        uint256 mintAmount = 1; // Example amount to mint
        cdp.mintStablecoin(mintAmount);

        // Log the balance of the deployer
        uint256 stablecoinBalance = cdp.balanceOf(deployer);
        console.log("Stablecoin balance of deployer:", stablecoinBalance);


        vm.stopBroadcast();
    }
}
