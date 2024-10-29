// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";

interface IBitDSMRegistry {
    event OperatorBtcKeyRegistered(address indexed operator, bytes btcPublicKey);
    event OperatorBtckeyDeregistered(address indexed operator);
    
    
    /// @notice Registers a new operator using a provided signature, signing key, and Bitcoin public key
    /// @param _operatorSignature Contains the operator's signature, salt, and expiry
    /// @param _signingKey The signing key to add to the operator's history
    /// @param btcPublicKey The Bitcoin public key associated with the operator
    function registerOperatorWithSignature(
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey,
        bytes calldata btcPublicKey
    ) external;
    
    function deregisterOperator() external;
    function isOperatorBtcKeyRegistered(address operator) external view returns (bool);
    function getOperatorBtcPublicKey(address operator) external view returns (bytes memory);
}

