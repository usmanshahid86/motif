// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitDSMServiceManager.sol";
import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "@eigenlayer/src/contracts/interfaces/IAVSDirectory.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MockAVSDirectory is IAVSDirectory {
    function registerOperatorToAVS(address, ISignatureUtils.SignatureWithSaltAndExpiry memory) external pure {}
    function deregisterOperatorFromAVS(address) external pure {}
    function updateAVSMetadataURI(string memory) external pure {}
    function OPERATOR_AVS_REGISTRATION_TYPEHASH() external pure returns (bytes32) {
        return bytes32(0);
    }
    function calculateOperatorAVSRegistrationDigestHash(
        address operator,
        address avs,
        bytes32 salt,
        uint256 expiry
    ) external pure returns (bytes32) {
        return bytes32(0);
    }
    function operatorSaltIsSpent(address operator, bytes32 salt) external pure returns (bool) {
        return false;
    }
}

contract MockECDSAStakeRegistry {
    function operatorRegistered(address) external pure returns (bool) {
        return true;
    }
}

contract BitDSMServiceManagerTest is Test {
    using ECDSA for bytes32;

    BitDSMServiceManager public serviceManager;
    MockAVSDirectory public mockAVSDirectory;
    MockECDSAStakeRegistry public mockStakeRegistry;
    address public owner;
    address public operator1;
    address public operator2;
    uint256 private operator1PrivateKey;

    function setUp() public {
        owner = address(this);
        operator1PrivateKey = 0x1; // This is the private key for operator1
        operator1 = vm.addr(operator1PrivateKey);
        operator2 = address(0x2);

        mockAVSDirectory = new MockAVSDirectory();
        mockStakeRegistry = new MockECDSAStakeRegistry();
        serviceManager = new BitDSMServiceManager(
            address(mockAVSDirectory),
            address(mockStakeRegistry),
            address(0), // mock delegation manager
            address(0) // mock rewards coordinator 
        );
    }

    function testCreateNewTask() public {
        // string memory taskName = "Test Task";
        // uint32 initialTaskNum = serviceManager.latestTaskNum();

        // serviceManager.createNewTask(taskName);

        // assertEq(serviceManager.latestTaskNum(), initialTaskNum + 1);
        // bytes32 taskHash = serviceManager.allTaskHashes(initialTaskNum);
        // assertNotEq(taskHash, bytes32(0), "Task hash should not be empty");
    }

    function testConfirmDeposit() public {
        // string memory taskName = "Test Task";
        // serviceManager.createNewTask(taskName);
        // uint32 taskIndex = serviceManager.latestTaskNum() - 1;

        // IBitDSMServiceManager.Task memory task;
        // task.name = taskName;
        // task.taskCreatedBlock = uint32(block.number);

        // bytes32 messageHash = keccak256(abi.encodePacked("Confirm deposit for: ", taskName));
        // bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(operator1PrivateKey, ethSignedMessageHash);
        // bytes memory signature = abi.encodePacked(r, s, v);

        // vm.prank(operator1);
        // serviceManager.confirmDeposit(task, taskIndex, signature);

        // We can't directly check the result of confirmDeposit as it only emits an event
        // In a real scenario, you might want to add a way to check if a deposit was confirmed
    }

    function testConfirmDepositInvalidTask() public {
        // string memory taskName = "Test Task";
        // serviceManager.createNewTask(taskName);
        // uint32 taskIndex = serviceManager.latestTaskNum() - 1;

        // IBitDSMServiceManager.Task memory task;
        // task.name = "Invalid Task Name";
        // task.taskCreatedBlock = uint32(block.number);

        // bytes memory signature = new bytes(65);

        // vm.prank(operator1);
        // vm.expectRevert("Invalid task");
        // serviceManager.confirmDeposit(task, taskIndex, signature);
    }

    function testConfirmDepositInvalidSignature() public {
        // string memory taskName = "Test Task";
        // serviceManager.createNewTask(taskName);
        // uint32 taskIndex = serviceManager.latestTaskNum() - 1;

        // IBitDSMServiceManager.Task memory task;
        // task.name = taskName;
        // task.taskCreatedBlock = uint32(block.number);

        // bytes32 messageHash = keccak256(abi.encodePacked("Confirm deposit for: ", taskName));
        // bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x2, ethSignedMessageHash); // Sign with a different private key
        // bytes memory invalidSignature = abi.encodePacked(r, s, v);

        // vm.prank(operator1);
        // vm.expectRevert("Invalid signature");
        // serviceManager.confirmDeposit(task, taskIndex, invalidSignature);
    }
}
