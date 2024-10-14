// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IAppRegistry {
    function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry) external;
    function deregisterApp(address app) external;
    function isAppRegistered(address app) external view returns (bool);
    function cancelSalt(bytes32 salt) external;
    function updateAppMetadataURI(string calldata metadataURI) external;

    function calculateAppRegistrationDigestHash(
        address app,
        bytes32 salt,
        uint256 expiry
    ) external view returns (bytes32);

    event AppRegistrationStatusUpdated(address indexed app, AppRegistrationStatus status);
    event AppMetadataURIUpdated(address indexed app, string metadataURI);

    enum AppRegistrationStatus { UNREGISTERED, REGISTERED }
}
