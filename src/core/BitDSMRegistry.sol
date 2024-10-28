// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IBitDSMRegistry.sol";

contract BitDSMRegistry is ECDSAStakeRegistry, PausableUpgradeable, IBitDSMRegistry {
    mapping(address => bytes) private operatorToBtcPublicKey;

    constructor(IDelegationManager _delegationManager) ECDSAStakeRegistry(_delegationManager) {}

    function initialize(
        address _serviceManager,
        uint256 _thresholdWeight,
        Quorum memory _quorum
    ) public initializer {
        __ECDSAStakeRegistry_init(_serviceManager, _thresholdWeight, _quorum);
        __Pausable_init();
    }

    function registerOperatorWithSignature(
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey,
        bytes calldata btcPublicKey
    ) external whenNotPaused {
        super.registerOperatorWithSignature(_operatorSignature, _signingKey);
        _registerBtcPublicKey(msg.sender, btcPublicKey);
    }

    function _registerBtcPublicKey(address operator, bytes calldata btcPublicKey) internal {
        require(btcPublicKey.length == 33, "Invalid Bitcoin public key length");
        require(operatorToBtcPublicKey[operator].length == 0, "BTC public key already registered");

        operatorToBtcPublicKey[operator] = btcPublicKey;
        emit OperatorRegistered(operator, btcPublicKey);
    }

    function deregisterOperator() external override(ECDSAStakeRegistry, IBitDSMRegistry) {
        super.deregisterOperator();
        delete operatorToBtcPublicKey[msg.sender];
        emit OperatorDeregistered(msg.sender);
    }

    function isOperatorRegistered(address operator) public view override(ECDSAStakeRegistry, IBitDSMRegistry) returns (bool) {
        return super.isOperatorRegistered(operator) && operatorToBtcPublicKey[operator].length > 0;
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
