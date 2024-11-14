# IAppRegistry
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/interfaces/IAppRegistry.sol)

Interface for managing application registrations in the BitDSM protocol

*Implements app registration, deregistration and status tracking functionality
The IAppRegistry interface provides the following key functionality:
- App registration with signature verification
- App deregistration by owner
- Registration status checks
- Salt cancellation for security
- Metadata URI updates*


## Functions
### registerApp

Registers a new app with signature verification


```solidity
function registerApp(address app, bytes memory signature, bytes32 salt, uint256 expiry) external;
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


```solidity
function deregisterApp(address app) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app to deregister|


### isAppRegistered

Checks if an app is registered


```solidity
function isAppRegistered(address app) external view returns (bool);
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


```solidity
function cancelSalt(bytes32 salt) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|The salt to cancel|


### updateAppMetadataURI

Updates the metadata URI for an app


```solidity
function updateAppMetadataURI(string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|The new metadata URI|


### calculateAppRegistrationDigestHash

Calculates the EIP-712 digest hash for app registration


```solidity
function calculateAppRegistrationDigestHash(address app, address appRegistry, bytes32 salt, uint256 expiry)
    external
    view
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app|
|`appRegistry`|`address`||
|`salt`|`bytes32`|The salt value|
|`expiry`|`uint256`|The expiration timestamp|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32 The calculated digest hash|


## Events
### AppRegistrationStatusUpdated
Emitted when registration status changes


```solidity
event AppRegistrationStatusUpdated(address indexed app, AppRegistrationStatus status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app|
|`status`|`AppRegistrationStatus`|The new registration status|

### AppMetadataURIUpdated
Emitted when metadata URI is updated


```solidity
event AppMetadataURIUpdated(address indexed app, string metadataURI);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`app`|`address`|The address of the app|
|`metadataURI`|`string`|The new metadata URI|

## Enums
### AppRegistrationStatus
Enum representing the registration status of an app


```solidity
enum AppRegistrationStatus {
    UNREGISTERED,
    REGISTERED
}
```

