# BitcoinPod
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/core/BitcoinPod.sol)

**Inherits:**
[IBitcoinPod](/src/interfaces/IBitcoinPod.sol/interface.IBitcoinPod.md), OwnableUpgradeable

A contract that represents a Bitcoin custody pod managed by an Client and an Operator

*This contract handles Bitcoin deposits and withdrawals through a designated operator,
tracks balances, and manages pod locking/unlocking functionality
Key features:
- Links a Bitcoin address to an Ethereum address
- Tracks Bitcoin balances in the pod
- Allows only authorized operator actions
- Supports locking mechanism for security
- Manages withdrawal transaction storage
Security considerations:
- Only the designated operator can perform sensitive actions
- Pod can be locked to prevent unauthorized withdrawals
- Manager contract has privileged access for administrative functions*


## State Variables
### operator

```solidity
address public operator;
```


### operatorBtcPubKey

```solidity
bytes public operatorBtcPubKey;
```


### bitcoinAddress

```solidity
bytes public bitcoinAddress;
```


### bitcoinBalance

```solidity
uint256 public bitcoinBalance;
```


### locked

```solidity
bool public locked;
```


### manager

```solidity
address public immutable manager;
```


### signedBitcoinWithdrawTransaction

```solidity
bytes public signedBitcoinWithdrawTransaction;
```


## Functions
### onlyOperator

Modifier to ensure only the designated operator can perform an action


```solidity
modifier onlyOperator(address _operator);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_operator`|`address`|Address of the operator to check against|


### lockedPod

Modifier to ensure the pod is not locked before execution


```solidity
modifier lockedPod();
```

### onlyManager

Modifier to ensure only the manager contract can perform an action


```solidity
modifier onlyManager();
```

### constructor

Initializes the immutable manager address


```solidity
constructor(address _manager);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`address`|Address of the BitcoinPodManager contract that manages this pod|


### initialize

Initializes a new Bitcoin pod with the specified parameters

*Sets initial state:
- Transfers ownership to _owner
- Sets operator and their BTC public key
- Sets the pod's Bitcoin address
- Initializes pod as unlocked*


```solidity
function initialize(address _owner, address _operator, bytes memory _operatorBtcPubKey, bytes memory _btcAddress)
    external
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address that will own this pod contract|
|`_operator`|`address`|Address of the designated operator who can perform sensitive actions|
|`_operatorBtcPubKey`|`bytes`|Bitcoin public key of the operator for multisig address generation|
|`_btcAddress`|`bytes`|Multisig Bitcoin address associated with this pod|


### getBitcoinAddress


```solidity
function getBitcoinAddress() external view returns (bytes memory);
```

### getOperatorBtcPubKey


```solidity
function getOperatorBtcPubKey() external view returns (bytes memory);
```

### getOperator


```solidity
function getOperator() external view returns (address);
```

### getBitcoinBalance


```solidity
function getBitcoinBalance() external view returns (uint256);
```

### getSignedBitcoinWithdrawTransaction


```solidity
function getSignedBitcoinWithdrawTransaction() external view returns (bytes memory);
```

### setSignedBitcoinWithdrawTransaction


```solidity
function setSignedBitcoinWithdrawTransaction(bytes memory _signedBitcoinWithdrawTransaction) external onlyManager;
```

### lock


```solidity
function lock() external onlyManager lockedPod;
```

### unlock


```solidity
function unlock() external onlyManager;
```

### isLocked


```solidity
function isLocked() external view returns (bool);
```

### mint


```solidity
function mint(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) lockedPod;
```

### burn


```solidity
function burn(address _operator, uint256 amount) external onlyManager onlyOperator(_operator) lockedPod;
```

