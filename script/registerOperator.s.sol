// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IAVSDirectory} from "@eigenlayer/src/contracts/interfaces/IAVSDirectory.sol";
import {IDelegationManager, OperatorDetails} from "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import {IRewardsCoordinator} from "@eigenlayer/src/contracts/interfaces/IRewardsCoordinator.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";


//@NOTE Script to register an operator to AVS deployed on Holesky. Assuming the operator is already registered with EigenLayer
//@NOTE Register Operatoe with EigenLayer using https://docs.eigenlayer.xyz/eigenlayer/operator-guides/operator-installation

contract RegisterOperator is Script {
    using ECDSA for bytes32;
    
    IAVSDirectory public avsDirectory;
    IDelegationManager public delegationManager;
    ECDSAStakeRegistry public stakeRegistry;
    BitDSMServiceManager public serviceManager;

    address public client;
    address public operatorEigen;
    uint256 private operatorEigenPrivateKey;

  function _loadDeployedContractAddresses(string memory targetEnv) internal {
        string memory root = vm.projectRoot();
        string memory pathEigen = string.concat(root, "/script/eigenlayer_addresses.json");
        string memory jsonEigen = vm.readFile(pathEigen);

        avsDirectory = IAVSDirectory(jsonEigen.readAddress(string(abi.encodePacked(".", targetEnv, ".avsDirectory"))));
        delegationManager = IDelegationManager(jsonEigen.readAddress(string(abi.encodePacked(".", targetEnv, ".delegationManager"))));

        string memory path_avs = string.concat(root, "/script/bitdsm_addresses.json");
        string memory jsonAVS = vm.readFile(path);

        stakeRegistry = ECDSAStakeRegistry(jsonAVS.readAddress(string(abi.encodePacked(".", "ECDSAStakeRegistryProxy"))));
        serviceManager = BitDSMServiceManager(jsonAVS.readAddress(string(abi.encodePacked(".", "BitDSMServiceManagerProxy"))));
  }

    function run() external {
        // Load the client private key
        uint256 clientPrivateKey = vm.envUint("CLIENT_PRIVATE_KEY");
        client = vm.addr(clientPrivateKey);
        
        // Transaction to test New task creation on BitDSMServiceManager
        // Start broadcasting transactions
        vm.startBroadcast(clientPrivateKey);
        // Set contract address and ABI (if needed)
        BitDSMServiceManager bitDSMServiceManager = BitDSMServiceManager(serviceManager);
        // Test the createNewTask function
        bitDSMServiceManager.createNewTask("Test Task");
        // End broadcasting transactions
        vm.stopBroadcast();


        // register Operator to AVS
        // Need The operator's private key registered with EigenLayer to send the transaction 
        operatorPrivateKey = vm.envUint("OPERATOR_PRIVATE_KEY");
        operator1 = vm.addr(operator1PrivateKey);
        
        // Load operator signing key. This key will be used for signing the tasks
        uint256 private opedratorSigningPrivateKey = vm.envUint("OPERATOR_SIGNING_PRIVATE_KEY");
        address public operatorSigning = vm.addr(operatorSigningPrivateKey);

        vm.log("Registering Operator to AVS"); 
        vm.Log(operatorPrivateKey);
        vm.log(operator1);
        vm.log(operatorSigning);
        vm.log(operatorSigningPrivateKey);
    }
}