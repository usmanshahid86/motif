# AppRegistry
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/core/AppRegistry.sol)

**Inherits:**
[IAppRegistry](/src/interfaces/IAppRegistry.sol/interface.IAppRegistry.md), Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable

A registry contract for managing application registrations in the BitDSM protocol

*Implements EIP-1271 signature verification for secure app registration
The AppRegistry contract provides the following key functionality:
- Secure app registration using EIP-1271 signatures
- App deregistration by owner
- Registration status tracking
Security features:
- Reentrancy protection on state-modifying functions
- Expiry-based signature validation
- Salt tracking to prevent replay attacks
- Owner-only deregistration
- Circuit breaker (pause) functionality*


## State Variables
### appStatus

```solidity
mapping(address => AppRegistrationStatus) public appStatus;
```


### appSaltIsSpent

```solidity
mapping(address => mapping(bytes32 => bool)) public appSaltIsSpent;
```


### APP_REGISTRATION_TYPEHASH

```solidity
bytes32 private constant APP_REGISTRATION_TYPEHASH =
    keccak256("AppRegistration(address app,address appRegistry, bytes32 salt,uint256 expiry)");
```


### DOMAIN_TYPEHASH

```solidity
bytes32 private constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
```


### DOMAIN_SEPARATOR

```solidity
bytes32 private immutable DOMAIN_SEPARATOR;
```


## Functions
### constructor

Constructor to initialize the domain separator


```solidity
constructor();
```

### initialize

Initialization function to set the initial owner and initialize Ownable, Pausable, and ReentrancyGuard

*This function performs the following:
- Validates that initialOwner is not zero address
- Initializes the Ownable, Pausable, and ReentrancyGuard contracts
- Transfers ownership to initialOwner*


```solidity
function initialize(address initialOwner) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialOwner`|`address`|The address of the initial owner|


### registerApp

Registers a new app with signature verification

*This function performs the following:
- Validates that the app is not already registered
- Validates that the salt has not been spent
- Validates that the signature is valid for the provided expiry
- Updates the app's registration status
- Emits an AppRegistrationStatusUpdated event*


```solidity
function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry)
    external
    override
    whenNotPaused
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app to register|
|`signature`|`bytes`|The signature proving ownership|
|`salt`|`bytes32`|Unique value to prevent replay attacks|
|`expiry`|`uint256`|Timestamp when signature expires|


### deregisterApp

Deregisters an app from the registry

*This function performs the following:
- Validates that the app is registered
- Updates the app's registration status
- Emits an AppRegistrationStatusUpdated event*


```solidity
function deregisterApp(address app) external override onlyOwner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app to deregister|


### isAppRegistered

Checks if an app is registered


```solidity
function isAppRegistered(address app) external view override returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if registered, false otherwise|


### cancelSalt

Cancels a salt for an app

*This function performs the following:
- Validates that the salt has not been spent
- Updates the salt's usage status*


```solidity
function cancelSalt(bytes32 salt) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|The salt to cancel|


### updateAppMetadataURI

Updates the metadata URI for an app

*This function performs the following:
- Validates that the app is registered
- Emits an AppMetadataURIUpdated event*


```solidity
function updateAppMetadataURI(string calldata metadataURI) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|The new metadata URI|


### calculateAppRegistrationDigestHash


```solidity
function calculateAppRegistrationDigestHash(address app, address appRegistry, bytes32 salt, uint256 expiry)
    public
    view
    override
    returns (bytes32);
```

### pause

Pauses the contract

*This function performs the following:
- Validates that the caller is the owner
- Pauses the contract*


```solidity
function pause() external onlyOwner;
```

### unpause

Unpauses the contract

*This function performs the following:
- Validates that the caller is the owner
- Unpauses the contract*


```solidity
function unpause() external onlyOwner;
```

