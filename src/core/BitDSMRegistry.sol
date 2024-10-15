// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IBitDSMRegistry.sol";

contract BitDSMRegistry is Initializable, OwnableUpgradeable, PausableUpgradeable, IBitDSMRegistry {
    mapping(address => bytes) private operatorToBtcPublicKey;

    function initialize(address initialOwner) public initializer {
        __Ownable_init();
        transferOwnership(initialOwner);
        __Pausable_init();
    }

    function registerOperator(bytes calldata btcPublicKey) external whenNotPaused {
        require(btcPublicKey.length == 33, "Invalid Bitcoin public key length");
        require(operatorToBtcPublicKey[msg.sender].length == 0, "Operator already registered");

        operatorToBtcPublicKey[msg.sender] = btcPublicKey;
        emit OperatorRegistered(msg.sender, btcPublicKey);
    }

    function deregisterOperator() external {
        require(operatorToBtcPublicKey[msg.sender].length > 0, "Operator not registered");

        delete operatorToBtcPublicKey[msg.sender];
        emit OperatorDeregistered(msg.sender);
    }

    function isOperatorRegistered(address operator) external view returns (bool) {
        return operatorToBtcPublicKey[operator].length > 0;
    }

    function getOperatorBtcPublicKey(address operator) external view returns (bytes memory) {
        require(operatorToBtcPublicKey[operator].length > 0, "Operator not registered");
        return operatorToBtcPublicKey[operator];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

