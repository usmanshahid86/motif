// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Script, console} from "forge-std/Script.sol";
import {Bod} from "../src/Bod.sol";

contract DeployBod is Script {
    Bod public bod;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the Bod contract
        bod = new Bod();

        // Initialize the Bod contract
        // Replace these addresses with actual addresses for bodOwner and bodManager
        address bodOwner = address(0x1234); // Replace with actual address
        address bodManager = address(0x5678); // Replace with actual address
        bod.initialize(bodOwner, bodManager, "defaultBitcoinAddress");

        console.log("Bod deployed at:", address(bod));
        console.log("Bod initialized with owner:", bodOwner);
        console.log("Bod initialized with manager:", bodManager);

        vm.stopBroadcast();
    }
}
