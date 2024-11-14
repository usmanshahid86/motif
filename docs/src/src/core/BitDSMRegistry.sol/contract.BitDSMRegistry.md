# BitDSMRegistry
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/core/BitDSMRegistry.sol)

**Inherits:**
[ECDSAStakeRegistry](/src/libraries/ECDSAStakeRegistry.sol/abstract.ECDSAStakeRegistry.md), PausableUpgradeable, [IBitDSMRegistry](/src/interfaces/IBitDSMRegistry.sol/interface.IBitDSMRegistry.md)


## State Variables
### _operatorToBtcPublicKey
mapping of operator addresses to their BTC public keys


```solidity
mapping(address => bytes) private _operatorToBtcPublicKey;
```


## Functions
### constructor

constructor for the BitDSMRegistry


```solidity
constructor(IDelegationManager _delegationManager) ECDSAStakeRegistry(_delegationManager);
```

### initialize

Initializes the BitDSMRegistry contract


```solidity
function initialize(address _serviceManager, uint256 _thresholdWeight, Quorum memory _quorum) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_serviceManager`|`address`|The address of the service manager|
|`_thresholdWeight`|`uint256`|The threshold weight in basis points|
|`_quorum`|`Quorum`|The quorum struct containing the details of the quorum thresholds|


### registerOperatorWithSignature

Registers a new operator using a provided signature and signing key

*caller must be the operator itself*


```solidity
function registerOperatorWithSignature(
    ISignatureUtils.SignatureWithSaltAndExpiry memory _operatorSignature,
    address _signingKey,
    bytes calldata btcPublicKey
) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_operatorSignature`|`ISignatureUtils.SignatureWithSaltAndExpiry`|Contains the operator's ECDSA signature, salt, and expiry|
|`_signingKey`|`address`|The signing key to add to the operator's history|
|`btcPublicKey`|`bytes`|The Bitcoin public key to register for the operator|


### deregisterOperator

Deregisters an operator and removes their Bitcoin public key

*Only interface for deregistering an operator with BitDSM AVS*


```solidity
function deregisterOperator() external override(ECDSAStakeRegistry, IBitDSMRegistry);
```

### isOperatorBtcKeyRegistered

Checks if an operator has a registered Bitcoin public key


```solidity
function isOperatorBtcKeyRegistered(address operator) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Address of the operator to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the operator has a registered Bitcoin public key, false otherwise|


### getOperatorBtcPublicKey

Retrieves the Bitcoin public key for a registered operator


```solidity
function getOperatorBtcPublicKey(address operator) external view returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Address of the operator to retrieve the key for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|The Bitcoin public key associated with the operator|


### pause

pause the contract


```solidity
function pause() external onlyOwner;
```

### unpause

unpause the contract


```solidity
function unpause() external onlyOwner;
```

