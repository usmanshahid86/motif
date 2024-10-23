// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "../interfaces/IBitDSMServiceManager.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BitDSMServiceManager is ECDSAServiceManagerBase, IBitDSMServiceManager {
    // State variables
    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTaskHashes;

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _delegationManager
    ) ECDSAServiceManagerBase(
        _avsDirectory,
        _stakeRegistry,
        address(0), // BitDSM doesn't need to deal with payments
        _delegationManager
    ) {}

    function createNewTask(string memory name) external {
        Task memory newTask;
        newTask.name = name;
        newTask.taskCreatedBlock = uint32(block.number);

        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum = latestTaskNum + 1;
    }

    function confirmDeposit(
        Task calldata task,
        uint32 referenceTaskIndex,
        bytes calldata signature
    ) external {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender),
            "Operator must be registered"
        );
        require(
            keccak256(abi.encode(task)) == allTaskHashes[referenceTaskIndex],
            "Invalid task"
        );

        bytes32 messageHash = keccak256(abi.encodePacked("Confirm deposit for: ", task.name));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid signature");

        emit DepositConfirmed(referenceTaskIndex, task, msg.sender);
    }
}
