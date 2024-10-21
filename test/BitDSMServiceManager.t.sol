// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitDSMServiceManager.sol";
import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "@eigenlayer/contracts/interfaces/IAVSDirectory.sol";

contract MockAVSDirectory is IAVSDirectory {
    function registerOperatorToAVS(address, ISignatureUtils.SignatureWithSaltAndExpiry memory) external pure {}
    function deregisterOperatorFromAVS(address) external pure {}
    function updateAVSMetadataURI(string memory) external pure {}
}

contract BitDSMServiceManagerTest is Test {
    BitDSMServiceManager public serviceManager;
    address public owner;
    address public operator1;
    address public operator2;

    function setUp() public {
        owner = address(this);
        operator1 = address(0x1);
        operator2 = address(0x2);

        MockAVSDirectory mockAVSDirectory = new MockAVSDirectory();
        serviceManager = new BitDSMServiceManager(
            address(mockAVSDirectory),
            address(0), // mock stake registry
            address(0), // mock payment coordinator
            address(0), // mock delegation manager
            100, // taskCreationThreshold
            200, // taskChallengeThreshold
            300, // taskResolutionThreshold
            1000 // taskExpirationBlocks
        );

        // Set up operator stakes
        vm.mockCall(
            address(serviceManager),
            abi.encodeWithSelector(BitDSMServiceManager.operatorStake.selector, operator1),
            abi.encode(150)
        );
        vm.mockCall(
            address(serviceManager),
            abi.encodeWithSelector(BitDSMServiceManager.operatorStake.selector, operator2),
            abi.encode(250)
        );
    }

    function testCreateTask() public {
        bytes memory data = abi.encode("test data");
        vm.prank(operator1);
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);

        bytes32 taskHash = keccak256(abi.encodePacked(BitDSMServiceManager.TaskType.ConfirmDeposit, operator1, block.number, data));
        (BitDSMServiceManager.TaskType taskType, address creator, uint256 creationBlock, BitDSMServiceManager.TaskStatus status, bytes memory taskData) = serviceManager.tasks(taskHash);

        assertEq(uint(taskType), uint(BitDSMServiceManager.TaskType.ConfirmDeposit));
        assertEq(creator, operator1);
        assertEq(uint(status), uint(BitDSMServiceManager.TaskStatus.Created));
        assertEq(taskData, data);
    }

    function testCreateTaskInsufficientStake() public {
        bytes memory data = abi.encode("test data");
        vm.prank(address(0x3)); // Address with no stake
        vm.expectRevert("Insufficient stake to create task");
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);
    }

    function testChallengeTask() public {
        bytes memory data = abi.encode("test data");
        vm.prank(operator1);
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);

        bytes32 taskHash = keccak256(abi.encodePacked(BitDSMServiceManager.TaskType.ConfirmDeposit, operator1, block.number, data));

        vm.prank(operator2);
        serviceManager.challengeTask(taskHash);

        (, , , BitDSMServiceManager.TaskStatus status, ) = serviceManager.tasks(taskHash);
        assertEq(uint(status), uint(BitDSMServiceManager.TaskStatus.Challenged));
    }

    function testChallengeNonExistentTask() public {
        bytes32 taskHash = keccak256("nonexistent");
        vm.prank(operator2);
        vm.expectRevert("Task does not exist");
        serviceManager.challengeTask(taskHash);
    }

    function testResolveTask() public {
        bytes memory data = abi.encode("test data");
        vm.prank(operator1);
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);

        bytes32 taskHash = keccak256(abi.encodePacked(BitDSMServiceManager.TaskType.ConfirmDeposit, operator1, block.number, data));

        vm.prank(operator2);
        serviceManager.challengeTask(taskHash);

        vm.prank(operator2);
        serviceManager.resolveTask(taskHash, BitDSMServiceManager.TaskStatus.Completed);

        (, , , BitDSMServiceManager.TaskStatus status, ) = serviceManager.tasks(taskHash);
        assertEq(uint(status), uint(BitDSMServiceManager.TaskStatus.Completed));
    }

    function testResolveUnchallengedTask() public {
        bytes memory data = abi.encode("test data");
        vm.prank(operator1);
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);

        bytes32 taskHash = keccak256(abi.encodePacked(BitDSMServiceManager.TaskType.ConfirmDeposit, operator1, block.number, data));

        vm.prank(operator2);
        vm.expectRevert("Task is not in challenged state");
        serviceManager.resolveTask(taskHash, BitDSMServiceManager.TaskStatus.Completed);
    }

    function testUpdateTaskThresholds() public {
        serviceManager.updateTaskThresholds(150, 250, 350);
        assertEq(serviceManager.taskCreationThreshold(), 150);
        assertEq(serviceManager.taskChallengeThreshold(), 250);
        assertEq(serviceManager.taskResolutionThreshold(), 350);
    }

    function testUpdateTaskExpirationBlocks() public {
        serviceManager.updateTaskExpirationBlocks(2000);
        assertEq(serviceManager.taskExpirationBlocks(), 2000);
    }

    function testIsTaskExpired() public {
        bytes memory data = abi.encode("test data");
        vm.prank(operator1);
        serviceManager.createTask(BitDSMServiceManager.TaskType.ConfirmDeposit, data);

        bytes32 taskHash = keccak256(abi.encodePacked(BitDSMServiceManager.TaskType.ConfirmDeposit, operator1, block.number, data));

        assertFalse(serviceManager.isTaskExpired(taskHash));

        vm.roll(block.number + 1001); // Move 1001 blocks forward
        assertTrue(serviceManager.isTaskExpired(taskHash));
    }
}

