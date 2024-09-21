pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BodManager} from "../src/BodManager.sol";

contract DeployBodManager is Script {
    BodManager public bodManager;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the BodManager
        bodManager = new BodManager();

        console.log("BodManager deployed at:", address(bodManager));

        vm.stopBroadcast();
    }
}
