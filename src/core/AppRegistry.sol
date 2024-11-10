// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../Interfaces/IAppRegistry.sol";
import "../libraries/EIP1271SignatureUtils.sol";

/**
 * @title AppRegistry
 * @notice A registry contract for managing application registrations in the BitDSM protocol
 * @dev Implements EIP-1271 signature verification for secure app registration
 *
 * The AppRegistry contract provides the following key functionality:
 * - Secure app registration using EIP-1271 signatures
 * - App deregistration by owner
 * - Registration status tracking
 *
 * Security features:
 * - Reentrancy protection on state-modifying functions
 * - Expiry-based signature validation
 * - Salt tracking to prevent replay attacks
 * - Owner-only deregistration
 * - Circuit breaker (pause) functionality
 */

contract AppRegistry is 
    IAppRegistry, 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    
    // @notice Mapping of app address to registration status
    mapping(address => AppRegistrationStatus) public appStatus;
    // @notice Mapping of app address and salt to usage status
    mapping(address => mapping(bytes32 => bool)) public appSaltIsSpent;
    // @notice EIP-712 typehash for app registration
    bytes32 private constant APP_REGISTRATION_TYPEHASH = keccak256("AppRegistration(address app,address appRegistry, bytes32 salt,uint256 expiry)");
    // @notice EIP-712 typehash for domain separator
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    // @notice Unique domain separator for this contract instance
    bytes32 private immutable DOMAIN_SEPARATOR;

    /**
     * @notice Constructor to initialize the domain separator
     */
    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("BitDSM")), block.chainid, address(this)));
    }

    /**
     * @notice Initialization function to set the initial owner and initialize Ownable, Pausable, and ReentrancyGuard
     * @param initialOwner The address of the initial owner
     * @dev This function performs the following:
     * - Validates that initialOwner is not zero address
     * - Initializes the Ownable, Pausable, and ReentrancyGuard contracts
     * - Transfers ownership to initialOwner
     */
    function initialize(address initialOwner) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        transferOwnership(initialOwner);
    }

    /**
     * @inheritdoc IAppRegistry
     * @dev This function performs the following:
     * - Validates that the app is not already registered
     * - Validates that the salt has not been spent
     * - Validates that the signature is valid for the provided expiry
     * - Updates the app's registration status
     * - Emits an AppRegistrationStatusUpdated event
     */
    function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry) 
        external 
        override 
        whenNotPaused 
        nonReentrant 
    {
        require(expiry >= block.timestamp, "AppRegistry: signature expired");
        require(appStatus[app] == AppRegistrationStatus.UNREGISTERED, "AppRegistry: app already registered");
        require(!appSaltIsSpent[app][salt], "AppRegistry: salt already spent");

        bytes32 digestHash = calculateAppRegistrationDigestHash(app, msg.sender, salt, expiry);

        EIP1271SignatureUtils.checkSignature_EIP1271(app, digestHash, signature);

        appStatus[app] = AppRegistrationStatus.REGISTERED;
        appSaltIsSpent[app][salt] = true;

        emit AppRegistrationStatusUpdated(app, AppRegistrationStatus.REGISTERED);
    }

    /**
     * @inheritdoc IAppRegistry
     * @dev This function performs the following:
     * - Validates that the app is registered
     * - Updates the app's registration status
     * - Emits an AppRegistrationStatusUpdated event
     */
    function deregisterApp(address app) 
        external 
        override 
        onlyOwner 
        whenNotPaused 
    {
        require(appStatus[app] == AppRegistrationStatus.REGISTERED, "AppRegistry: app not registered");

        appStatus[app] = AppRegistrationStatus.UNREGISTERED;

        emit AppRegistrationStatusUpdated(app, AppRegistrationStatus.UNREGISTERED);
    }

    /**
     * @inheritdoc IAppRegistry
     */
    function isAppRegistered(address app) external view override returns (bool) {
        return appStatus[app] == AppRegistrationStatus.REGISTERED;
    }

    /**
     * @inheritdoc IAppRegistry
     * @dev This function performs the following:
     * - Validates that the salt has not been spent
     * - Updates the salt's usage status
     */
    function cancelSalt(bytes32 salt) external override {
        require(!appSaltIsSpent[msg.sender][salt], "AppRegistry: cannot cancel spent salt");
        appSaltIsSpent[msg.sender][salt] = true;
    }

    /**
     * @inheritdoc IAppRegistry
     * @dev This function performs the following:
     * - Validates that the app is registered
     * - Emits an AppMetadataURIUpdated event
     */
    function updateAppMetadataURI(string calldata metadataURI) external override {
        require(appStatus[msg.sender] == AppRegistrationStatus.REGISTERED, "AppRegistry: app not registered");
        emit AppMetadataURIUpdated(msg.sender, metadataURI);
    }
    // @inheritdoc IAppRegistry
    function calculateAppRegistrationDigestHash(
        address app,
        address appRegistry,
        bytes32 salt,
        uint256 expiry
    ) public view override returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(APP_REGISTRATION_TYPEHASH, app, appRegistry, salt, expiry));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /**
     * @notice Pauses the contract
     * @dev This function performs the following:
     * - Validates that the caller is the owner
     * - Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev This function performs the following:
     * - Validates that the caller is the owner
     * - Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}