// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBitDSMRegistry {
    event OperatorRegistered(address indexed operator, bytes btcPublicKey);
    event OperatorDeregistered(address indexed operator);

    function registerOperator(bytes calldata btcPublicKey) external;
    function deregisterOperator() external;
    function isOperatorRegistered(address operator) external view returns (bool);
    function getOperatorBtcPublicKey(address operator) external view returns (bytes memory);
}

