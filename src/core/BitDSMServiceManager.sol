// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import "../interfaces/IBitDSMServiceManager.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IBitcoinPodManager.sol";
import "../interfaces/IBitDSMRegistry.sol";
import "../interfaces/IBitcoinPod.sol";


contract BitDSMServiceManager is ECDSAServiceManagerBase, IBitDSMServiceManager {
    // State variables
    address public immutable bitcoinPodManager;

    modifier onlyRegisteredOperator(address operator) {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(operator),
            "Operator must be registered"
        );
        _;
    }

    constructor(
        address _avsDirectory,
        address _bitDSMRegistry,
        address _rewardsCoordinator,
        address _delegationManager,
        address _bitcoinPodManager
    ) ECDSAServiceManagerBase(
        _avsDirectory,
        _bitDSMRegistry,
        _rewardsCoordinator,
        _delegationManager
    ) {

        bitcoinPodManager = _bitcoinPodManager;
    }
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
      //  require(
        //    podToBitcoinDepositRequest[pod].length > 0,
          //  "No deposit requests to confirm"
       // );
        IBitcoinPodManager.BitcoinDepositRequest memory bitcoinDepositRequest = 
        IBitcoinPodManager(bitcoinPodManager).getBitcoinDepositRequest(pod);
        //require(
//
  //           "Deposit already verified"
    //    );
        bytes32 messageHash = keccak256(abi.encodePacked(pod, msg.sender, bitcoinDepositRequest.amount, bitcoinDepositRequest.transactionId, true));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid Operator signature");
        IBitcoinPodManager(bitcoinPodManager).confirmBitcoinDeposit(pod, bitcoinDepositRequest.transactionId, bitcoinDepositRequest.amount ) ;
    }

    function withdrawBitcoinPSBT(address pod, uint256 amount, bytes calldata psbtTransaction, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can process withdrawal"
        );
        // check if the pod has a withdrawal request
       // require(IBitcoinPodManager(bitcoinPodManager).getBitcoinWithdrawalAddress(pod) != address(0), "No withdrawal request");
        // verify the operator sign over psbt
        bytes memory withdrawAddress = IBitcoinPodManager(bitcoinPodManager).getBitcoinWithdrawalAddress(pod);
        bytes32 messageHash = keccak256(abi.encodePacked(pod, amount, psbtTransaction, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        require(signer == msg.sender, "Invalid Operator signature");

        // store the psbt in the pod
        IBitcoinPod(pod).setSignedBitcoinWithdrawTransaction(psbtTransaction);
        // emit the event
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }

    function withdrawBitcoinCompleteTx(address pod, uint256 amount, bytes calldata completeTx, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can process withdrawal"
        );
        // get withdraw address from the pod
        bytes memory withdrawAddress = IBitcoinPodManager(bitcoinPodManager).getBitcoinWithdrawalAddress(pod);
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
        IBitcoinPod(pod).setSignedBitcoinWithdrawTransaction(completeTx);
        // emit the event
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }


    function confirmWithdrawal(address pod, bytes calldata transaction, bytes calldata signature) external {
        require(
            IBitcoinPod(pod).getOperator() == msg.sender,
            "Only operator that owns the pod can confirm withdrawal"
        );
       require(
           IBitcoinPodManager(bitcoinPodManager).getBitcoinWithdrawalAddress(pod).length != 0,
           "No withdrawal request to confirm"
        );

        bytes memory withdrawAddress = IBitcoinPodManager(bitcoinPodManager).getBitcoinWithdrawalAddress(pod);
    

        bytes32 messageHash = keccak256(abi.encodePacked(pod, transaction, withdrawAddress));
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        require(signer == msg.sender, "Invalid signature");
        IBitcoinPodManager(bitcoinPodManager).withdrawBitcoinAsTokens(pod);
    }


}
