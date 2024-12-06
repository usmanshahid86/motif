// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/governance/Token.sol";
import "../src/governance/TokenTimelock.sol";

contract DeployUpgradeableToken is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy implementation
        BitDSMToken implementation = new BitDSMToken();

        // Deploy ProxyAdmin
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            BitDSMToken.initialize.selector,
            msg.sender);  // initialOwner

        // Deploy transparent proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        // The token is now deployed at the proxy address
        BitDSMToken token = BitDSMToken(address(proxy));

        // Enable Timelock
        // Setup timelock roles
        address[] memory proposers = new address[](1);
        proposers[0] = msg.sender;
        
        address[] memory executors = new address[](1);
        executors[0] = msg.sender;
        
        // Deploy timelock
        TokenTimelock timelockContract = new TokenTimelock(
            2 days, // Minimum delay
            proposers,
            executors,
            msg.sender // Admin
        );

        // Transfer token ownership to timelock
        token.transferOwnership(address(timelockContract));

        // Setup initial guardians (minimum 3 required)
        //token.scheduleAddGuardian(msg.sender);
        //token.scheduleAddGuardian(address(0x123)); // Add second guardian
        //token.scheduleAddGuardian(address(0x456)); // Add third guardian

        // Note: Guardian additions will need to be executed after the timelock delay
        // This should be done in a separate transaction after GUARDIAN_TIMELOCK_DELAY (3 days)
        vm.stopBroadcast();
        console.log("Token Implementation deployed to:", address(implementation));
        console.log("Proxy Admin deployed to:", address(proxyAdmin));
        console.log("Token Proxy deployed to:", address(proxy));
        console.log("Timelock deployed to:", address(timelockContract));
    }
} 