// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IBitcoinPodManager {
    struct BitcoinDepositRequest {
        bytes32 transactionId;
        uint256 amount;
        bool isPending;
    }
    event PodCreated(address indexed user, address indexed pod, address indexed operator);
    event PodDelegated(address indexed pod, address indexed appContract);
    event PodUndelegated(address indexed pod);
    
    event BitcoinMinted(address indexed pod, uint256 amount);
    event BitcoinBurned(address indexed pod, uint256 amount);
    
    event VerifyBitcoinDepositRequest(address indexed pod, address indexed operator, BitcoinDepositRequest bitcoinDepositRequest);
    event BitcoinDepositConfirmed(address indexed pod, uint256 amount);
    event BitcoinWithdrawnFromPod(address indexed pod, bytes withdrawAddress);

    event BitcoinWithdrawalPSBTRequest(address indexed pod, address indexed operator, bytes withdrawAddress);
    event BitcoinWithdrawalCompleteTxRequest(address indexed pod, address indexed operator, bytes preSignedBitcoinTx);
    
    function getBitcoinDepositRequest(address pod) external view returns (BitcoinDepositRequest memory);
    function getBitcoinWithdrawalAddress(address pod) external view returns (bytes memory );

    function createPod(address operator, bytes memory btcAddress) external returns (address);
    function delegatePod(address pod, address appContract) external;
    function undelegatePod(address pod) external;
    
    //function _mintBitcoin(address pod, uint256 amount) internal;
    //function _burnBitcoin(address pod, uint256 amount) internal;
    
    function lockPod(address pod) external;
    function unlockPod(address pod) external;
    
    function verifyBitcoinDepositRequest(address pod, bytes32 transactionId, uint256 amount) external;
    function confirmBitcoinDeposit(address pod, bytes32 transactionId, uint256 amount) external;

    function withdrawBitcoinPSBTRequest(address pod, bytes memory withdrawAddress) external;
    function withdrawBitcoinCompleteTxRequest(address pod, bytes memory preSignedWithdrawTransaction, bytes memory withdrawAddress) external;
    function withdrawBitcoinAsTokens(address pod) external;

    function setSignedBitcoinWithdrawTransactionPod(address pod, bytes memory signedBitcoinWithdrawTransaction) external;
}
