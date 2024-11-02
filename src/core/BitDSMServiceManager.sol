// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "../interfaces/IBitDSMServiceManager.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BitcoinDepositRequest, IBitcoinPodManager} from "../interfaces/IBitcoinPodManager.sol";
import "../src/core/BitcoinPodManager.sol";
import "../src/core/BitDSMRegistry.sol";
contract BitDSMServiceManager is ECDSAServiceManagerBase, IBitDSMServiceManager {
    // State variables
    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTaskHashes;

    modifier onlyRegisteredOperator(address operator) {
        require(
            BitDSMRegistry(_bitDSMRegistry).operatorRegistered(operator),
            "Operator must be registered"
        );
        _;
    }

    constructor(
        address _avsDirectory,
        address _bitDSMRegistry,
        address _rewardsCoordinator,
        address _delegationManager
    ) ECDSAServiceManagerBase(
        _avsDirectory,
        _bitDSMRegistry,
        _rewardsCoordinator,
        _delegationManager
    ) {}
    function initialize(address _owner) public initializer {
        __ServiceManagerBase_init(_owner, address(0));
    } 

    function confirmDeposit(
        address pod,
        bytes calldata signature
    ) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can confirm deposit"
        );
        require(
            podToBitcoinDepositRequest[pod].length > 0,
            "No deposit requests to confirm"
        );
        BitcoinDepositRequest memory bitcoinDepositRequest = podToBitcoinDepositRequest[pod];
        require(
            !bitcoinDepositRequest.isPending,
            "Deposit already verified"
        );
        bytes32 messageHash = keccak256(abi.encodePacked(pod, msg.sender, bitcoinDepositRequest));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid signature");
        IBitcoinPodManager.confirmBitcoinDeposit(pod, bitcoinDepositRequest.transactionId);
    }

    function confirmWithdrawal(address pod, bytes caldata transaction, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can confirm withdrawal"
        );
        require(
            podToWithdrawalAddress[pod] != bytes(0),
            "No withdrawal request to confirm"
        );
        bytes memory withdrawAddress = podToWithdrawalAddress[pod];
        
        bytes32 messageHash = keccak256(abi.encodePacked(pod, transaction, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid signature");
        IBitcoinPodManager.withdrawBitcoin(pod);
    }


}
