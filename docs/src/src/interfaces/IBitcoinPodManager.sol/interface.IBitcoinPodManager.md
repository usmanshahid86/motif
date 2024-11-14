# IBitcoinPodManager
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/interfaces/IBitcoinPodManager.sol)

Interface for managing Bitcoin pods, which handle Bitcoin deposits and withdrawals

*This interface defines the core functionality for Bitcoin pod management including:
- Pod creation and delegation
- Bitcoin deposit verification and confirmation
- Bitcoin withdrawal requests and processing
- Pod locking/unlocking mechanisms*


## Functions
### getUserPod

Gets the pod address associated with a user


```solidity
function getUserPod(address user) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to lookup|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The address of the user's pod, or zero address if none exists|


### getPodApp

Gets the app contract address that a pod is delegated to


```solidity
function getPodApp(address pod) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to lookup|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The address of the app contract the pod is delegated to, or zero address if not delegated|


### getBitcoinDepositRequest

Gets the deposit request details for a pod (alias of getPodDepositRequest)


```solidity
function getBitcoinDepositRequest(address pod) external view returns (BitcoinDepositRequest memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to lookup|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`BitcoinDepositRequest`|BitcoinDepositRequest struct containing the deposit transaction ID, amount and pending status|


### getBitcoinWithdrawalAddress

Gets the withdrawal address set for a pod (alias of getPodWithdrawalAddress)


```solidity
function getBitcoinWithdrawalAddress(address pod) external view returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to lookup|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|The Bitcoin withdrawal address as bytes|


### getTotalTVL

Gets the total value locked across all pods


```solidity
function getTotalTVL() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 The total value locked in satoshis|


### getBitDSMServiceManager

Gets the address of the BitDSM Service Manager contract


```solidity
function getBitDSMServiceManager() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The address of the BitDSM Service Manager contract|


### getAppRegistry

Gets the address of the App Registry contract


```solidity
function getAppRegistry() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the App Registry|


### getBitDSMRegistry

Gets the address of the BitDSM Registry contract


```solidity
function getBitDSMRegistry() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the BitDSM Registry|


### createPod

Creates a new pod

*Checks that:
- User doesn't already have a pod
- Operator is registered in BitDSM Registry*


```solidity
function createPod(address operator, bytes memory btcAddress) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator creating the pod|
|`btcAddress`|`bytes`|The Bitcoin address for the pod|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address The address of the created pod|


### delegatePod

Delegates a pod to an app

*Only the pod owner can delegate the pod*

*The app must be registered in the App Registry*


```solidity
function delegatePod(address pod, address appContract) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to be delegated|
|`appContract`|`address`|The address of the app to delegate the pod to|


### undelegatePod

Undelegates a pod

*Only the pod owner can undelegate the pod*


```solidity
function undelegatePod(address pod) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to be undelegated|


### lockPod

Locks a pod

*Only the delegated app can lock the pod*


```solidity
function lockPod(address pod) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to be locked|


### unlockPod

Unlocks a pod

*Only the delegated app can unlock the pod*


```solidity
function unlockPod(address pod) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod to be unlocked|


### verifyBitcoinDepositRequest

Client request to verify the deposit

*can only be requested by pod owner*


```solidity
function verifyBitcoinDepositRequest(address pod, bytes32 transactionId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod|
|`transactionId`|`bytes32`|The Bitcoin transaction ID|
|`amount`|`uint256`|The amount deposited|


### confirmBitcoinDeposit

Confirms the deposit on Bitcoin Network

*can only be requested by the BitDSM Service Manager*

*Updates the pod balance*


```solidity
function confirmBitcoinDeposit(address pod, bytes32 transactionId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod|
|`transactionId`|`bytes32`|The Bitcoin transaction ID|
|`amount`|`uint256`|The amount deposited|


### withdrawBitcoinPSBTRequest

Initiates a Bitcoin withdrawal request using PSBT (Partially Signed Bitcoin Transaction) from pod owner


```solidity
function withdrawBitcoinPSBTRequest(address pod, bytes memory withdrawAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod where the withdrawal is requested|
|`withdrawAddress`|`bytes`|The Bitcoin address where funds should be withdrawn to|


### withdrawBitcoinCompleteTxRequest

Initiates a Bitcoin withdrawal request from the pod owner


```solidity
function withdrawBitcoinCompleteTxRequest(
    address pod,
    bytes memory preSignedWithdrawTransaction,
    bytes memory withdrawAddress
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod where the withdrawal is requested|
|`preSignedWithdrawTransaction`|`bytes`|The pre-signed Bitcoin transaction sent from the pod owner|
|`withdrawAddress`|`bytes`|The Bitcoin address where funds should be withdrawn to|


### withdrawBitcoinAsTokens

Withdraws Bitcoin as tokens from the pod


```solidity
function withdrawBitcoinAsTokens(address pod) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod where the withdrawal is requested|


### setSignedBitcoinWithdrawTransactionPod

Sets the signed Bitcoin withdrawal transaction in the pod


```solidity
function setSignedBitcoinWithdrawTransactionPod(address pod, bytes memory signedBitcoinWithdrawTransaction) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod|
|`signedBitcoinWithdrawTransaction`|`bytes`|The signed Bitcoin PSBT or raw transaction|


## Events
### PodCreated
Event emitted when a new pod is created


```solidity
event PodCreated(address indexed user, address indexed pod, address indexed operator);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user creating the pod|
|`pod`|`address`|The address of the created pod|
|`operator`|`address`|The address of the operator for the pod|

### PodDelegated
Event emitted when a pod is delegated to an app


```solidity
event PodDelegated(address indexed pod, address indexed appContract);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod being delegated|
|`appContract`|`address`|The address of the app being delegated to|

### PodUndelegated
Event emitted when a pod is undelegated


```solidity
event PodUndelegated(address indexed pod);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod being undelegated|

### BitcoinMinted
Event emitted when Bitcoin token value is set to a pod


```solidity
event BitcoinMinted(address indexed pod, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod receiving the token value|
|`amount`|`uint256`|The amount of Bitcoin tokens set|

### BitcoinBurned
Event emitted when Bitcoin tokens are cleared from a pod


```solidity
event BitcoinBurned(address indexed pod, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod burning the tokens|
|`amount`|`uint256`|The amount of Bitcoin tokens burned|

### TotalTVLUpdated
Event emitted when the total TVL is updated


```solidity
event TotalTVLUpdated(uint256 newTVL);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newTVL`|`uint256`|The new total TVL|

### VerifyBitcoinDepositRequest
Event emitted when a Bitcoin deposit request is initiated


```solidity
event VerifyBitcoinDepositRequest(
    address indexed pod, address indexed operator, BitcoinDepositRequest bitcoinDepositRequest
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod where the deposit is requested|
|`operator`|`address`|The address of the operator verifying the deposit request|
|`bitcoinDepositRequest`|`BitcoinDepositRequest`|The details of the deposit request|

### BitcoinDepositConfirmed
Event emitted when a deposit is confirmed on Bitcoin Network


```solidity
event BitcoinDepositConfirmed(address indexed pod, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod receiving the deposit|
|`amount`|`uint256`|The amount of Bitcoin deposited|

### BitcoinWithdrawnFromPod
Event emitted when Bitcoin is withdrawn from a pod


```solidity
event BitcoinWithdrawnFromPod(address indexed pod, bytes withdrawAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod|
|`withdrawAddress`|`bytes`|The address to which the Bitcoin is withdrawn|

### BitcoinWithdrawalPSBTRequest
Event emitted when a Bitcoin withdrawal PSBT request is initiated


```solidity
event BitcoinWithdrawalPSBTRequest(address indexed pod, address indexed operator, bytes withdrawAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod from where the Bitcoin is requested to be withdrawn|
|`operator`|`address`|The address of the operator that will create and sign the PSBT|
|`withdrawAddress`|`bytes`|The address to which the Bitcoin is withdrawn|

### BitcoinWithdrawalCompleteTxRequest
Event emitted when a Bitcoin withdrawal complete transaction request is initiated


```solidity
event BitcoinWithdrawalCompleteTxRequest(address indexed pod, address indexed operator, bytes preSignedBitcoinTx);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|The address of the pod from where the Bitcoin is requested to be withdrawn|
|`operator`|`address`|The address of the operator whose sign is required|
|`preSignedBitcoinTx`|`bytes`|The pre-signed Bitcoin transaction sent from the client|

## Structs
### BitcoinDepositRequest
Struct to store Bitcoin deposit request details


```solidity
struct BitcoinDepositRequest {
    bytes32 transactionId;
    uint256 amount;
    bool isPending;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`transactionId`|`bytes32`|The Bitcoin transaction ID of the deposit|
|`amount`|`uint256`|The amount of Bitcoin being deposited in satoshis|
|`isPending`|`bool`|deposit request status|

