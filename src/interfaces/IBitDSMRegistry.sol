// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";
import "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";

interface IBitDSMRegistry is ECDSAStakeRegistryEventsAndErrors {
    event OperatorRegistered(address indexed operator, bytes btcPublicKey);
    event OperatorDeregistered(address indexed operator);

    function registerOperatorWithSignature(
        ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
        address _signingKey,
        bytes calldata btcPublicKey
    ) external;

    function deregisterOperator() external;
    function isOperatorRegistered(address operator) external view returns (bool);
    function getOperatorBtcPublicKey(address operator) external view returns (bytes memory);

    function pause() external;
    function unpause() external;
}
