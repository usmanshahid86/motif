// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
//import "../../src/governance/TokenV2.sol";

contract UpgradeToken is Script {
    function run() external {
        address proxyAddress = address(0x0000000000000000000000000000000000000000); // Your proxy address
        address proxyAdminAddress = address(0x0000000000000000000000000000000000000000); // Your ProxyAdmin address
        
        vm.startBroadcast();

        // Deploy new implementation
        // BitDSMTokenV2 newImplementation = new BitDSMTokenV2();

        // // Upgrade through ProxyAdmin
        // ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        // proxyAdmin.upgrade(
        //     TransparentUpgradeableProxy(payable(proxyAddress)),
        //     address(newImplementation)
        // );

        vm.stopBroadcast();
    }
} 