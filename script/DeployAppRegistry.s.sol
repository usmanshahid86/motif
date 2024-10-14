// script/DeployAppRegistry.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/core/AppRegistry.sol";

contract DeployAppRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        AppRegistry appRegistry = new AppRegistry();
        appRegistry.initialize(deployerAddress);

        vm.stopBroadcast();

        console.log("AppRegistry deployed at:", address(appRegistry));
    }
}

