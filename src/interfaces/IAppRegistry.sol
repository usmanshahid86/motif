// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IAppRegistry
 * @notice Interface for managing application registrations in the BitDSM protocol
 * @dev Implements app registration, deregistration and status tracking functionality
 *
 * The IAppRegistry interface provides the following key functionality:
 * - App registration with signature verification
 * - App deregistration by owner
 * - Registration status checks
 * - Salt cancellation for security
 * - Metadata URI updates
 */

interface IAppRegistry {
     
    /**
     * @notice Enum representing the registration status of an app
     * @param UNREGISTERED App is not registered
     * @param REGISTERED App is registered
     */
    enum AppRegistrationStatus { UNREGISTERED, REGISTERED }
    /**
     * @notice Emitted when registration status changes
     * @param app The address of the app
     * @param status The new registration status
     */
     event AppRegistrationStatusUpdated(address indexed app, AppRegistrationStatus status);
    
    /**
     * @notice Emitted when metadata URI is updated
     * @param app The address of the app
     * @param metadataURI The new metadata URI
     */
    event AppMetadataURIUpdated(address indexed app, string metadataURI);

    /**
     * @notice Registers a new app with signature verification
     * @param app The address of the app to register
     * @param signature The signature proving ownership
     * @param salt Unique value to prevent replay attacks
     * @param expiry Timestamp when signature expires
     */
    function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry) external;
    /**
     * @notice Deregisters an app from the registry
     * @param app The address of the app to deregister
     */
    function deregisterApp(address app) external;
    
    /**
     * @notice Checks if an app is registered
     * @param app The address of the app to check
     * @return bool True if registered, false otherwise
     */
    function isAppRegistered(address app) external view returns (bool);
    
    /**
     * @notice Cancels a salt for an app
     * @param salt The salt to cancel
     */
    
    function cancelSalt(bytes32 salt) external;
    /**
     * @notice Updates the metadata URI for an app
     * @param metadataURI The new metadata URI
     */
    
    function updateAppMetadataURI(string calldata metadataURI) external;
    /**
     * @notice Calculates the EIP-712 digest hash for app registration
     * @param app The address of the app
     * @param salt The salt value
     * @param expiry The expiration timestamp
     * @return bytes32 The calculated digest hash
     */
    function calculateAppRegistrationDigestHash(
        address app,
        address appRegistry,
        bytes32 salt,
        uint256 expiry
    ) external view returns (bytes32);

   
}
