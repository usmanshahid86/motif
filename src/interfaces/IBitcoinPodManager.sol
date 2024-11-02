// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IBitcoinPodManager {
    struct BitcoinDepositRequest {
        bytes32 transactionId;
        uint256 amount;
        bool isPending;
    };

    event PodCreated(address indexed user, address indexed pod, address indexed operator);
    event PodDelegated(address indexed pod, address indexed appContract);
    event PodUndelegated(address indexed pod);
    
    event BitcoinMinted(address indexed pod, uint256 amount);
    event BitcoinBurned(address indexed pod, uint256 amount);
    
    event verifyBitcoinDepositRequest(address indexed pod, address indexed operator, BitcoinDepositRequest bitcoinDepositRequest);
    event BitcoinDepositConfirmed(address indexed pod, uint256 amount);
    
    event withdrawBitcoinRequest(address indexed pod, address indexed operator, bytes withdrawAddress);

    function createPod(address operator, bytes memory btcAddress) external returns (address);
    function delegatePod(address pod, address appContract) external;
    function undelegatePod(address pod) external;
    
    function _mintBitcoin(address pod, uint256 amount) internal;
    function _burnBitcoin(address pod, uint256 amount) internal;
    
    function lockPod(address pod) external;
    function unlockPod(address pod) external;
    
    function verifyBitcoinDepositRequest(address pod, bytes32 transactionId, uint256 amount) external;
    function confirmBitcoinDeposit(address pod, bytes32 transactionId) external;

    function withdrawBitcoinRequest(address pod, bytes memory withdrawAddress) external;
    function withdrawBitcoin(address pod) external;
}
