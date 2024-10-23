// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";

interface IBitDSMServiceManager is IServiceManager {
    struct Task {
        string name;
        uint32 taskCreatedBlock;
    }

    event NewTaskCreated(uint32 indexed taskId, Task task);
    event DepositConfirmed(uint32 indexed taskId, Task task, address operator);

    function createNewTask(string memory name) external;
    function confirmDeposit(Task calldata task, uint32 referenceTaskIndex, bytes calldata signature) external;
}
