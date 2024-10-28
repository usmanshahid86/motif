// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/core/BitDSMRegistry.sol";
import "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";

contract DeployBitDSMRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Mock DelegationManager address - replace with actual address in production
        address mockDelegationManager = address(0x1234567890123456789012345678901234567890);

        vm.startBroadcast(deployerPrivateKey);

        BitDSMRegistry registry = new BitDSMRegistry(IDelegationManager(mockDelegationManager));
        registry.initialize(
            deployerAddress,
            1000, // Example threshold weight
            Quorum({strategies: new StrategyParams[](0)}) // Example empty quorum
        );

        vm.stopBroadcast();

        console.log("BitDSMRegistry deployed at:", address(registry));
    }
}
