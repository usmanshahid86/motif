// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {BitDSMServiceManager} from "../../src/core/BitDSMServiceManager.sol";
import {console} from "forge-std/console.sol";
contract UpgradeBitDSMServiceManager is Script {
    uint256 deployerPrivateKey;
    address deployer;
    address constant _PROXY_ADMIN = 0x71e4eFEcF796bBBC562f639ADde036784F67a563;
    address constant _BITCOIN_POD_MANAGER_PROXY = 0x3FAB0A58446da7a0703c0856A7c05abfa5a0F964;
    address constant _APP_REGISTRY = 0xD2a6d4e2F8FaF4Ee980be7Ff43Fb9e47b496b475;
    address constant _BITDSM_REGISTRY = 0x9619E0B51531ba2607d55422D66b14c570d5DE7a;
    address constant _SERVICE_MANAGER_PROXY = 0x3E091B2318356b1AA1D5F0Bd846E956b48beB238; 
    address constant _REWARDS_COORDINATOR = 0xAcc1fb458a1317E886dB376Fc8141540537E68fE;
    address constant _DELEGATION_MANAGER = 0xA44151489861Fe9e3055d95adC98FbD462B948e7;
    address constant _AVS_DIRECTORY = 0x055733000064333CaDDbC92763c58BF0192fFeBf;
    address constant _BITDSM_REGISTRY_PROXY = 0x9619E0B51531ba2607d55422D66b14c570d5DE7a;
    function upgradeBitDSMServiceManager() public {
        // Deploy new implementation
        BitDSMServiceManager serviceManagerImpl = new BitDSMServiceManager(
            _AVS_DIRECTORY,
            _BITDSM_REGISTRY_PROXY,
            _REWARDS_COORDINATOR,
            _DELEGATION_MANAGER
        );
        // initialize the new implementation
        serviceManagerImpl.setBitcoinPodManager(_BITCOIN_POD_MANAGER_PROXY);    
        
        bytes memory upgradeCallData = abi.encodeWithSignature(
            "upgrade(address,address)", 
            _SERVICE_MANAGER_PROXY,
            address(serviceManagerImpl)
        );

        // Call upgrade on proxy admin
        (bool success,) = _PROXY_ADMIN.call(upgradeCallData);
        require(success, "Upgrade failed");
        // display the new implementation address
        console.log("BitDSMServiceManager upgraded successfully");
        console.log("New implementation address: %s", address(serviceManagerImpl));

    }
    function run() external {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        upgradeBitDSMServiceManager();
        vm.stopBroadcast();
    }
}