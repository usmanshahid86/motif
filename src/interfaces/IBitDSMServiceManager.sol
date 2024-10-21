// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";

interface IBITDSMServiceManager is IServiceManager {
    enum TaskStatus { Created, Challenged, Completed, Failed }

    event TaskCreated(bytes32 indexed taskHash, address indexed creator);
    event TaskChallenged(bytes32 indexed taskHash, address indexed challenger);
    event TaskResolved(bytes32 indexed taskHash, TaskStatus status);

    function createTask(bytes32 _taskHash) external;
    function challengeTask(bytes32 _taskHash) external;
    function resolveTask(bytes32 _taskHash, TaskStatus _resolution) external;
    function getTaskStatus(bytes32 _taskHash) external view returns (TaskStatus);
    function isTaskExpired(bytes32 _taskHash) external view returns (bool);
    function updateTaskThresholds(
        uint256 _taskCreationThreshold,
        uint256 _taskChallengeThreshold,
        uint256 _taskResolutionThreshold
    ) external;
    function updateTaskExpirationBlocks(uint256 _taskExpirationBlocks) external;
}

