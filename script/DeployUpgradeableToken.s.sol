// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/governance/Token.sol";
import "../src/governance/TokenTimelock.sol";
 // Your existing ProxyAdmin address
    address constant PROXY_ADMIN = 0x71e4eFEcF796bBBC562f639ADde036784F67a563;  // Replace with your ProxyAdmin address
contract DeployUpgradeableToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

       // Verify ProxyAdmin exists and deployer has admin rights
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN);
        require(proxyAdmin.owner() == deployer, "Deployer is not ProxyAdmin owner");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        BitDSMToken implementation = new BitDSMToken();
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            BitDSMToken.initialize.selector,
            msg.sender, // initialOwner
            msg.sender);  // initialSupplyDistributor

        // Deploy transparent proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        // The token is now deployed at the proxy address
        BitDSMToken token = BitDSMToken(payable(address(proxy)));

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