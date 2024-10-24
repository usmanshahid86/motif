// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IAVSDirectory} from "@eigenlayer/src/contracts/interfaces/IAVSDirectory.sol";
import {IDelegationManager} from "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import {IRewardsCoordinator} from "@eigenlayer/src/contracts/interfaces/IRewardsCoordinator.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";

contract TestBitDSMServiceManager is Script {
    using ECDSA for bytes32;
    
    IAVSDirectory public avsDirectory;
    IDelegationManager public delegationManager;
     ECDSAStakeRegistry public stakeRegistry;
    BitDSMServiceManager public serviceManager;

    address public client;
    address public operator1;
    uint256 private operator1PrivateKey;

  function _loadDeployedContractAddresses(string memory targetEnv) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/eigenlayer_addresses.json");
        string memory json = vm.readFile(path);

        avsDirectory = IAVSDirectory(json.readAddress(string(abi.encodePacked(".", targetEnv, ".avsDirectory"))));
        delegationManager = IDelegationManager(json.readAddress(string(abi.encodePacked(".", targetEnv, ".delegationManager"))));

        string memory path_avs = string.concat(root, "/script/bitdsm_addresses.json");
        string memory jsonAVS = vm.readFile(path);

        stakeRegistry = ECDSAStakeRegistry(jsonAVS.readAddress(string(abi.encodePacked(".", "ECDSAStakeRegistryProxy"))));
        serviceManager = BitDSMServiceManager(jsonAVS.readAddress(string(abi.encodePacked(".", "BitDSMServiceManagerProxy"))));
  }



    function run() external {
        // Load the client private key
        uint256 clientPrivateKey = vm.envUint("CLIENT_PRIVATE_KEY");
        client = vm.addr(clientPrivateKey);
        // Start broadcasting transactions
        vm.startBroadcast(clientPrivateKey);

        // Set contract address and ABI (if needed)
        BitDSMServiceManager bitDSMServiceManager = BitDSMServiceManager(serviceManager);

        // Test the createNewTask function
        bitDSMServiceManager.createNewTask("Test Task");

        // register Operator to EigenLayer and AVS
        operator1PrivateKey = vm.envUint("OPERATOR_PRIVATE_KEY");
        operator1 = vm.addr(operator1PrivateKey);

        // End broadcasting transactions
        vm.stopBroadcast();
    }
}