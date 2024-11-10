// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Script} from "forge-std/Script.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {console} from "forge-std/console.sol";

contract VerifyOwnership is Script {
    address constant _PROXY_ADMIN = 0x71e4eFEcF796bBBC562f639ADde036784F67a563;
    address constant _SERVICE_MANAGER_PROXY = 0x3E091B2318356b1AA1D5F0Bd846E956b48beB238;

    function run() external view {
        // Get ProxyAdmin instance
        ProxyAdmin proxyAdmin = ProxyAdmin(_PROXY_ADMIN);
        
        // Get current implementation address
        address implementationAddr = proxyAdmin.getProxyImplementation(
            TransparentUpgradeableProxy(payable(_SERVICE_MANAGER_PROXY))
        );
        
        // Get proxy instance (points to implementation logic)
        BitDSMServiceManager proxy = BitDSMServiceManager(_SERVICE_MANAGER_PROXY);
        
        // Get implementation instance (direct access)
        BitDSMServiceManager implementation = BitDSMServiceManager(implementationAddr);
        
        // Check ownership
        console.log("ProxyAdmin owner:", proxyAdmin.owner());
        console.log("Proxy admin address:", _PROXY_ADMIN);
        console.log("Implementation address:", implementationAddr);
        console.log("Proxy contract address:", _SERVICE_MANAGER_PROXY);
        
        // Check contract ownership (through proxy)
        console.log("Contract owner (through proxy):", proxy.owner());
        
        // Check implementation ownership (direct)
        console.log("Implementation owner:", implementation.owner());
    }
}
