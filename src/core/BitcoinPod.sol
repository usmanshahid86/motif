// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IBitcoinPod.sol";

contract BitcoinPod is IBitcoinPod, OwnableUpgradeable {
    address public operator;
    bytes public operatorBtcPubKey;
    bytes public bitcoinAddress;
    uint256 public bitcoinBalance;
    bool public locked;
    address public immutable manager;
    bytes public signedBitcoinWithdrawTransaction;


    modifier onlyOperator(address _operator) {
        require(_operator == operator, "Only designated operator can perform this action");
        _;
    }
    modifier lockedPod() {
        require(!locked, "Pod is locked");
        _;
    }

    constructor(address _owner, address _operator, bytes memory _operatorBtcPubKey, bytes memory _btcAddress, address _manager) {
        _transferOwnership(_owner);
        operator = _operator;
        operatorBtcPubKey = _operatorBtcPubKey;
        bitcoinAddress = _btcAddress;
        manager = _manager;
        locked = false;
    }

    function getBitcoinAddress() external view returns (bytes memory) {
        return bitcoinAddress;
    }

    function getOperatorBtcPubKey() external view returns (bytes memory) {
        return operatorBtcPubKey;
    }

    function getOperator() external view returns (address) {
        return operator;
    }

    function getBitcoinBalance() external view returns (uint256) {
        return bitcoinBalance;
    }
    function getSignedBitcoinWithdrawTransaction() external view returns (bytes memory) {
        return signedBitcoinWithdrawTransaction;
    }
    function setSignedBitcoinWithdrawTransaction(bytes memory _signedBitcoinWithdrawTransaction) external onlyManager {
        signedBitcoinWithdrawTransaction = _signedBitcoinWithdrawTransaction;
    }
    function lock() external onlyManager lockedPod {
        locked = true;
    }

    function unlock() external onlyManager {
        locked = false;
    }

    function isLocked() external view returns (bool) {
        return locked;
    }

    function mint(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) lockedPod {

        bitcoinBalance += amount;
    }

    function burn(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) lockedPod {
        require(bitcoinBalance >= amount, "Insufficient balance");
        bitcoinBalance -= amount;
    }

}
