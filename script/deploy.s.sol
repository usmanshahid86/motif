// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/BodManager.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the BodManager contract
        BodManager bodManager = new BodManager();
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        bodManager.initialize(deployer);

        console.log("BodManager deployed at:", address(bodManager));

        vm.stopBroadcast();
    }
}
