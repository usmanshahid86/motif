# IBitcoinPod
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/interfaces/IBitcoinPod.sol)

Interface for individual Bitcoin pods that handle Bitcoin deposits and withdrawals

*This interface defines the core functionality for Bitcoin pods including:
- Balance tracking
- Withdrawal transaction handling
- Pod locking/unlocking mechanisms
- Pod owner management*


## Functions
### getBitcoinAddress

Returns the Bitcoin address of the pod

*This is the address where Bitcoin deposits are received on the Bitcoin Chain*


```solidity
function getBitcoinAddress() external view returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytes The Bitcoin address as a byte array|


### getOperatorBtcPubKey

Returns the Bitcoin public key of the operator associated with this pod

*This operator key is used to generate the multisig Bitcoin address*


```solidity
function getOperatorBtcPubKey() external view returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytes The Bitcoin public key as a byte array|


### getOperator

Returns the Ethereum address of the operator associated with this pod

*This is the address of the operator who can perform sensitive actions*


```solidity
function getOperator() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The operator's Ethereum address|


### getBitcoinBalance

Returns the current Bitcoin balance tracked in the pod

*This balance is updated through minting and burning actions*


```solidity
function getBitcoinBalance() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The current Bitcoin balance|


### getSignedBitcoinWithdrawTransaction

Returns the signed Bitcoin withdrawal transaction stored in the pod

*This transaction is used in the process of withdrawing Bitcoin from the pod*

*The transaction can either be a partially signed PSBT created by the operator or a completely signed raw transaction depending on the withdrawal path taken by the client*


```solidity
function getSignedBitcoinWithdrawTransaction() external view returns (bytes memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|bytes The signed Bitcoin transaction as a byte array|


### setSignedBitcoinWithdrawTransaction

Sets the signed Bitcoin withdrawal psbt or raw transaction in the pod

*This transaction is used by the client to create and broadcast the final signed transaction on the Bitcoin Network*


```solidity
function setSignedBitcoinWithdrawTransaction(bytes memory _signedBitcoinWithdrawTransaction) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_signedBitcoinWithdrawTransaction`|`bytes`|The signed Bitcoin transaction as a byte array|


### lock

Locks the pod to prevent further withdrawals

*This is a security measure to prevent unauthorized withdrawals*

*The pod can only be locked by the BitcoinPodManager*


```solidity
function lock() external;
```

### unlock

Unlocks the pod to allow withdrawals

*This is used when the pod is ready to be used again*

*The pod can only be unlocked by the BitcoinPodManager*


```solidity
function unlock() external;
```

### isLocked

Checks if the pod is currently locked

*This is used to ensure the pod is not locked before performing actions*


```solidity
function isLocked() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the pod is locked, false otherwise|


### mint

Adds Bitcoin value to the pod

*This is used to set the Bitcoin balance in the pod*


```solidity
function mint(address operator, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Address of the operator performing the minting|
|`amount`|`uint256`|The amount of Bitcoin tokens to mint|


### burn

Removes Bitcoin token value from the pod

*This is used to clear the Bitcoin balance in the pod*


```solidity
function burn(address operator, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|Address of the operator performing the burning|
|`amount`|`uint256`|The amount of Bitcoin tokens to burn|


