// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/unaudited/ECDSAStakeRegistry.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IBitDSMRegistry.sol";

contract BitDSMRegistry is ECDSAStakeRegistry, PausableUpgradeable, IBitDSMRegistry {
    mapping(address => bytes) private operatorToBtcPublicKey;
    mapping(address => bool) private _operatorRegistered;
    
    constructor(IDelegationManager _delegationManager) ECDSAStakeRegistry(_delegationManager) {}

    function initialize(
        address _serviceManager,
        uint256 _thresholdWeight,
        Quorum memory _quorum
    ) public initializer {
        __ECDSAStakeRegistry_init(_serviceManager, _thresholdWeight, _quorum);
        __Pausable_init();
    }

    // This function is already virtual in the parent contract
    function _registerOperatorWithSig(
        address _operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey
    ) internal virtual override {
        super._registerOperatorWithSig(_operator, _operatorSignature, _signingKey);
        // Add our custom logic here
        emit OperatorRegistered(_operator, operatorToBtcPublicKey[_operator]);
    }

    function registerOperatorWithSignature(
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey
    ) external override {
        _registerOperatorWithSig(msg.sender, _operatorSignature, _signingKey);
    }

    // For non-virtual functions, we create new functions with different names
    function deregisterOperator() external override(ECDSAStakeRegistry, IBitDSMRegistry) {
        // Instead of calling the contract directly, use the parent contract's implementation
        ECDSAStakeRegistry.deregisterOperator.call();
    }

    function isOperatorRegistered(address operator) public view returns (bool) {
        return _operatorRegistered[operator] && operatorToBtcPublicKey[operator].length > 0;
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
