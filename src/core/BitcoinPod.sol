// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBitcoinPod.sol";

contract BitcoinPod is IBitcoinPod, OwnableUpgradeable {
    address public operator;
    bytes public operatorBtcPubKey;
    bytes public bitcoinAddress;
    uint256 public bitcoinBalance;
    bool public locked;
    address public immutable manager;

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    modifier onlyOperator(address _operator) {
        require(_operator == operator, "Only designated operator can perform this action");
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

    function lock() external onlyManager {
        locked = true;
    }

    function unlock() external onlyManager {
        locked = false;
    }

    function isLocked() external view returns (bool) {
        return locked;
    }

    function mint(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) {
        bitcoinBalance += amount;
    }

    function burn(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) {
        require(bitcoinBalance >= amount, "Insufficient balance");
        bitcoinBalance -= amount;
    }
}
