// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/core/BitDSMRegistry.sol";

contract DeployBitDSMRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        BitDSMRegistry registry = new BitDSMRegistry();
        registry.initialize(deployerAddress);

        vm.stopBroadcast();

        console.log("BitDSMRegistry deployed at:", address(registry));
    }
}

