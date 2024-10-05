// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ECDSAServiceManagerBase} from
    "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {ECDSAStakeRegistry} from "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import {IServiceManager} from "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";
import {ECDSAUpgradeable} from
    "@openzeppelin-upgrades/contracts/utils/cryptography/ECDSAUpgradeable.sol";

import "./BodManager.sol";
import "./CDPContract.sol";
/**
 * @title Primary entrypoint for procuring services from HelloWorld.
 * @author Eigen Labs, Inc.
 */


contract BitDSMAVS is ECDSAServiceManagerBase {
    using ECDSAUpgradeable for bytes32;

     /* STORAGE */
    // the latest task index
    uint32 public latestTaskNum;
    BodManager public immutable bodManager;
    CDPContract public immutable cdpContract;
    
   
    // mapping of task indices to all tasks hashes
    // when a task is created, task hash is stored here,
    // and responses need to pass the actual task,
    // which is hashed onchain and checked against this mapping
    mapping(uint32 => bytes32) public allTaskHashes;
    // mapping of task indices to hash of abi.encode(taskResponse, taskResponseMetadata)
   // mapping(address => mapping(uint32 => bytes)) public allTaskResponses;

    /* MODIFIERS */
   // modifier onlyOperator() {
     //   require(
       //     ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender),
         //   "Operator must be the caller"
       // );
       // _;
   // }
    mapping(uint32 => LockBitcoinTask) public lockBitcoinTasks;

    struct LockBitcoinTask {
        address bodOwner;
        bytes32 btcTxHash;
        uint256 amount;
        bool executed;
    }

    event NewLockBitcoinTaskCreated(uint32 taskId, address bodOwner, bytes32 btcTxHash, uint256 amount);
    event LockBitcoinTaskExecuted(uint32 taskId);

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _delegationManager,
        address _bodManager,
        address _cdpContract
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            address(0), // hello-world doesn't need to deal with payments
            _delegationManager
        )
    {
        bodManager = BodManager(_bodManager);
        cdpContract = CDPContract(_cdpContract);
    }

    /* FUNCTIONS */
    // NOTE: this function creates new task, assigns it a taskId
    function createLockBitcoinTask(bytes32 btcTxHash, uint256 amount) external {
        require(bodManager.hasBod(msg.sender), "Sender does not have a BOD");
        
        LockBitcoinTask memory newTask = LockBitcoinTask({
            bodOwner: msg.sender,
            btcTxHash: btcTxHash,
            amount: amount,
            executed: false
        });

        uint32 taskId = latestTaskNum++;
        lockBitcoinTasks[taskId] = newTask;
        allTaskHashes[taskId] = keccak256(abi.encode(newTask));

        emit NewLockBitcoinTaskCreated(taskId, msg.sender, btcTxHash, amount);
    }

    function executeLockBitcoinTask(uint32 taskId) external onlyOwner {
        LockBitcoinTask storage task = lockBitcoinTasks[taskId];
        require(!task.executed, "Task already executed");
        require(keccak256(abi.encode(task)) == allTaskHashes[taskId], "Task data mismatch");

        bodManager.lockBitcoin(task.btcTxHash, task.amount);
        task.executed = true;

        emit LockBitcoinTaskExecuted(taskId);
    }
}
