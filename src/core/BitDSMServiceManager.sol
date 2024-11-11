// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import "../interfaces/IBitDSMServiceManager.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IBitcoinPodManager.sol";
import "../interfaces/IBitDSMRegistry.sol";
import "../interfaces/IBitcoinPod.sol";

/**
 * @title BitDSM Service Manager
 * @dev This contract manages Bitcoin DSM (Decentralized Service Manager) operations
 * @notice Extends ECDSAServiceManagerBase to handle Bitcoin pod operations and deposits
 * 
 * Key components:
 * - Manages Bitcoin pod operations through IBitcoinPodManager
 * - Handles deposit confirmations from operators
 * - Integrates with EigenLayer for staking and delegation
 * 
 * Dependencies:
 * - ECDSAServiceManagerBase: Base contract for ECDSA service management
 * - IBitcoinPodManager: Interface for Bitcoin pod management
 * - IBitDSMRegistry: Registry interface for BitDSM services and handling EigenLayer staking and delegation
 */
contract BitDSMServiceManager is ECDSAServiceManagerBase, IBitDSMServiceManager {
    // State variables
    IBitcoinPodManager _bitcoinPodManager;

    modifier onlyRegisteredOperator(address operator) {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(operator),
            "Operator must be registered"
        );
        _;
    }
    /**
     * @notice Constructor for BitDSMServiceManager contract
     * @dev Initializes the contract with required dependencies from EigenLayer and BitDSM
     * @param _avsDirectory Address of the EigenLayer AVS Directory contract
     * @param _bitDSMRegistry Address of the BitDSM Registry contract for operator management
     * @param _rewardsCoordinator Address of the rewards coordinator contract
     * @param _delegationManager Address of EigenLayer's delegation manager contract
     * 
     */
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

    /**
     * @notice Initializes the BitDSMServiceManager contract
     * @param _owner Address of the owner of the contract
     * @param _rewardsInitiator Address of the rewards initiator
     * @param bitcoinPodManager Address of the BitcoinPodManager contract
     */
    function initialize(address _owner, address _rewardsInitiator, address bitcoinPodManager) public initializer {
        __ServiceManagerBase_init(_owner, _rewardsInitiator);
        _bitcoinPodManager = IBitcoinPodManager(bitcoinPodManager);
    }

    function setBitcoinPodManager(address bitcoinPodManager) external {
        _bitcoinPodManager = IBitcoinPodManager(bitcoinPodManager);
    }

    /**
    * @inheritdoc IBitDSMServiceManager
     */
    function confirmDeposit(
        address pod,
        bytes calldata signature
    ) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can confirm deposit"
        );
      //  require(
        //    podToBitcoinDepositRequest[pod].length > 0,
          //  "No deposit requests to confirm"
       // );
        IBitcoinPodManager.BitcoinDepositRequest memory bitcoinDepositRequest = 
        _bitcoinPodManager.getBitcoinDepositRequest(pod);

        bytes32 messageHash = keccak256(abi.encodePacked(pod, msg.sender, bitcoinDepositRequest.amount, bitcoinDepositRequest.transactionId, true));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid Operator signature");
        _bitcoinPodManager.confirmBitcoinDeposit(pod, bitcoinDepositRequest.transactionId, bitcoinDepositRequest.amount ) ;
    }

   /**
    * @inheritdoc IBitDSMServiceManager
     */
    function withdrawBitcoinPSBT(address pod, uint256 amount, bytes calldata psbtTransaction, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can process withdrawal"
        );
        // check if the pod has a withdrawal request
       require(_bitcoinPodManager.getBitcoinWithdrawalAddress(pod).length != 0, "No withdrawal request");
        // verify the operator sign over psbt
        bytes memory withdrawAddress = _bitcoinPodManager.getBitcoinWithdrawalAddress(pod);
        bytes32 messageHash = keccak256(abi.encodePacked(pod, amount, psbtTransaction, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        require(signer == msg.sender, "Invalid Operator signature");

        // store the psbt in the pod
        _bitcoinPodManager.setSignedBitcoinWithdrawTransactionPod(pod, psbtTransaction);
        // emit the event
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }

    /**
    * @inheritdoc IBitDSMServiceManager
     */
    function withdrawBitcoinCompleteTx(address pod, uint256 amount, bytes calldata completeTx, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can process withdrawal"
        );
        // get withdraw address from the pod
        bytes memory withdrawAddress = _bitcoinPodManager.getBitcoinWithdrawalAddress(pod);
            // decode the transaction
        // check if the transaction is a withdrawal transaction
        // check if the withdrawal address appear as the recipient in the transaction 
        // and amount is greater than 0
        // verify the operator sign over completeTx 
        bytes32 messageHash = keccak256(abi.encodePacked(pod, amount, completeTx, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        require(signer == msg.sender, "Invalid Operator signature");

        // send the completeTx to the pod owner
        _bitcoinPodManager.setSignedBitcoinWithdrawTransactionPod(pod, completeTx);
        // emit the event
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }

     /**
    * @inheritdoc IBitDSMServiceManager
     */
    function confirmWithdrawal(address pod, bytes calldata transaction, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can confirm withdrawal"
        );
       require(
           _bitcoinPodManager.getBitcoinWithdrawalAddress(pod).length != 0,
           "No withdrawal request to confirm"
        );

        bytes memory withdrawAddress = _bitcoinPodManager.getBitcoinWithdrawalAddress(pod);
    
        bytes32 messageHash = keccak256(abi.encodePacked(pod, transaction, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid signature");
        _bitcoinPodManager.withdrawBitcoinAsTokens(pod);
    }


}
