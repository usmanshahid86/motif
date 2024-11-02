// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";

interface IBitDSMServiceManager is IServiceManager {
    
    event BitcoinWithdrawalTransactionSigned(address indexed pod, address indexed operator, uint256 amount);

    function confirmDeposit(address pod, bytes calldata signature) external;
    function withdrawBitcoinPSBT(address pod, uint256 amount, bytes calldata psbtTransaction, bytes calldata  signature) external;
    function withdrawBitcoinCompleteTx(address pod, uint256 amount, bytes calldata completeTx, bytes calldata  signature) external;
}
