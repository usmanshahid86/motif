// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IAppRegistry.sol";
import "../libraries/EIP1271SignatureUtils.sol";

contract AppRegistry is 
    IAppRegistry, 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    mapping(address => AppRegistrationStatus) public appStatus;
    mapping(address => mapping(bytes32 => bool)) public appSaltIsSpent;

    bytes32 private constant APP_REGISTRATION_TYPEHASH = keccak256("AppRegistration(address app,bytes32 salt,uint256 expiry)");
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 private immutable DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("BitDSM")), block.chainid, address(this)));
    }

    function initialize(address initialOwner) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        transferOwnership(initialOwner);
    }

    function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry) 
        external 
        override 
        whenNotPaused 
        nonReentrant 
    {
        require(expiry >= block.timestamp, "AppRegistry: signature expired");
        require(appStatus[app] == AppRegistrationStatus.UNREGISTERED, "AppRegistry: app already registered");
        require(!appSaltIsSpent[app][salt], "AppRegistry: salt already spent");

        bytes32 digestHash = calculateAppRegistrationDigestHash(app, salt, expiry);

        EIP1271SignatureUtils.checkSignature_EIP1271(app, digestHash, signature);

        appStatus[app] = AppRegistrationStatus.REGISTERED;
        appSaltIsSpent[app][salt] = true;

        emit AppRegistrationStatusUpdated(app, AppRegistrationStatus.REGISTERED);
    }

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

    function isAppRegistered(address app) external view override returns (bool) {
        return appStatus[app] == AppRegistrationStatus.REGISTERED;
    }

    function cancelSalt(bytes32 salt) external override {
        require(!appSaltIsSpent[msg.sender][salt], "AppRegistry: cannot cancel spent salt");
        appSaltIsSpent[msg.sender][salt] = true;
    }

    function updateAppMetadataURI(string calldata metadataURI) external override {
        require(appStatus[msg.sender] == AppRegistrationStatus.REGISTERED, "AppRegistry: app not registered");
        emit AppMetadataURIUpdated(msg.sender, metadataURI);
    }

    function calculateAppRegistrationDigestHash(
        address app,
        bytes32 salt,
        uint256 expiry
    ) public view override returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(APP_REGISTRATION_TYPEHASH, app, salt, expiry));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}