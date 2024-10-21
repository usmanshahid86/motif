// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "./interfaces/IBitDSMServiceManager.sol";

contract BitDSMServiceManager is ECDSAServiceManagerBase, IBitDSMServiceManager {
    // State variables
    uint256 public constant QUORUM_THRESHOLD_NUMERATOR = 2;
    uint256 public constant QUORUM_THRESHOLD_DENOMINATOR = 3;
    uint256 public taskCreationThreshold;
    uint256 public taskChallengeThreshold;
    uint256 public taskResolutionThreshold;
    uint256 public taskExpirationBlocks;

    // Structs
    enum TaskType { ConfirmDeposit, WithdrawRequest }

    struct Task {
        TaskType taskType;
        address creator;
        uint256 creationBlock;
        TaskStatus status;
        bytes data; // Additional data specific to the task type
    }

    // Mappings
    mapping(bytes32 => Task) public tasks;

    // Events
    event TaskCreated(bytes32 indexed taskHash, address indexed creator, TaskType taskType);
    event TaskChallenged(bytes32 indexed taskHash, address indexed challenger);
    event TaskResolved(bytes32 indexed taskHash, TaskStatus status);

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _paymentCoordinator,
        address _delegationManager,
        uint256 _taskCreationThreshold,
        uint256 _taskChallengeThreshold,
        uint256 _taskResolutionThreshold,
        uint256 _taskExpirationBlocks
    ) ECDSAServiceManagerBase(_avsDirectory, _stakeRegistry, _paymentCoordinator, _delegationManager) {
        taskCreationThreshold = _taskCreationThreshold;
        taskChallengeThreshold = _taskChallengeThreshold;
        taskResolutionThreshold = _taskResolutionThreshold;
        taskExpirationBlocks = _taskExpirationBlocks;
    }

    function createTask(TaskType _taskType, bytes memory _data) external {
        require(ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(msg.sender) >= taskCreationThreshold, "Insufficient stake to create task");
        
        bytes32 taskHash = keccak256(abi.encodePacked(_taskType, msg.sender, block.number, _data));
        require(tasks[taskHash].creator == address(0), "Task already exists");

        tasks[taskHash] = Task({
            taskType: _taskType,
            creator: msg.sender,
            creationBlock: block.number,
            status: TaskStatus.Created,
            data: _data
        });

        emit TaskCreated(taskHash, msg.sender, _taskType);
    }

    function challengeTask(bytes32 _taskHash) external {
        require(ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(msg.sender) >= taskChallengeThreshold, "Insufficient stake to challenge task");
        require(tasks[_taskHash].creator != address(0), "Task does not exist");
        require(tasks[_taskHash].status == TaskStatus.Created, "Task cannot be challenged");

        tasks[_taskHash].status = TaskStatus.Challenged;
        emit TaskChallenged(_taskHash, msg.sender);
    }

    function resolveTask(bytes32 _taskHash, TaskStatus _resolution) external {
        require(ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(msg.sender) >= taskResolutionThreshold, "Insufficient stake to resolve task");
        Task storage task = tasks[_taskHash];
        require(task.creator != address(0), "Task does not exist");
        require(task.status == TaskStatus.Challenged, "Task is not in challenged state");
        require(_resolution == TaskStatus.Completed || _resolution == TaskStatus.Failed, "Invalid resolution status");

        if (_resolution == TaskStatus.Completed) {
            if (task.taskType == TaskType.ConfirmDeposit) {
                // Logic for confirming deposit
            } else if (task.taskType == TaskType.WithdrawRequest) {
                // Logic for processing withdraw request
            }
        }

        task.status = _resolution;
        emit TaskResolved(_taskHash, _resolution);
    }

    function getTaskStatus(bytes32 _taskHash) external view returns (TaskStatus) {
        return tasks[_taskHash].status;
    }

    function isTaskExpired(bytes32 _taskHash) public view returns (bool) {
        return block.number >= tasks[_taskHash].creationBlock + taskExpirationBlocks;
    }

    function updateTaskThresholds(
        uint256 _taskCreationThreshold,
        uint256 _taskChallengeThreshold,
        uint256 _taskResolutionThreshold
    ) external onlyOwner {
        taskCreationThreshold = _taskCreationThreshold;
        taskChallengeThreshold = _taskChallengeThreshold;
        taskResolutionThreshold = _taskResolutionThreshold;
    }

    function updateTaskExpirationBlocks(uint256 _taskExpirationBlocks) external onlyOwner {
        taskExpirationBlocks = _taskExpirationBlocks;
    }

}
