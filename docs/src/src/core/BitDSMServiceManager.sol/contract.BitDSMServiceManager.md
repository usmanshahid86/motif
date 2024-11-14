# BitDSMServiceManager
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/core/BitDSMServiceManager.sol)

**Inherits:**
ECDSAServiceManagerBase, [IBitDSMServiceManager](/src/interfaces/IBitDSMServiceManager.sol/interface.IBitDSMServiceManager.md)

Extends ECDSAServiceManagerBase to handle Bitcoin pod operations and deposits
Key components:
- Manages Bitcoin pod operations through IBitcoinPodManager
- Handles deposit confirmations from operators
- Integrates with EigenLayer for staking and delegation
Dependencies:
- ECDSAServiceManagerBase: Base contract for ECDSA service management
- IBitcoinPodManager: Interface for Bitcoin pod management
- IBitDSMRegistry: Registry interface for BitDSM services and handling EigenLayer staking and delegation

*This contract manages Bitcoin DSM (Decentralized Service Manager) operations*


## State Variables
### _bitcoinPodManager

```solidity
IBitcoinPodManager _bitcoinPodManager;
```


## Functions
### onlyRegisteredOperator


```solidity
modifier onlyRegisteredOperator(address operator);
```

### constructor

Constructor for BitDSMServiceManager contract

*Initializes the contract with required dependencies from EigenLayer and BitDSM*


```solidity
constructor(address _avsDirectory, address _bitDSMRegistry, address _rewardsCoordinator, address _delegationManager)
    ECDSAServiceManagerBase(_avsDirectory, _bitDSMRegistry, _rewardsCoordinator, _delegationManager);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_avsDirectory`|`address`|Address of the EigenLayer AVS Directory contract|
|`_bitDSMRegistry`|`address`|Address of the BitDSM Registry contract for operator management|
|`_rewardsCoordinator`|`address`|Address of the rewards coordinator contract|
|`_delegationManager`|`address`|Address of EigenLayer's delegation manager contract|


### initialize

Initializes the BitDSMServiceManager contract


```solidity
function initialize(address _owner, address _rewardsInitiator, address bitcoinPodManager) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|Address of the owner of the contract|
|`_rewardsInitiator`|`address`|Address of the rewards initiator|
|`bitcoinPodManager`|`address`|Address of the BitcoinPodManager contract|


### setBitcoinPodManager


```solidity
function setBitcoinPodManager(address bitcoinPodManager) external;
```

### confirmDeposit

Confirms a Bitcoin chain deposit by verifying operator signature and updating pod state

*Only callable by the operator assigned to the pod*


```solidity
function confirmDeposit(address pod, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod receiving the deposit|
|`signature`|`bytes`|Operator's signature over the deposit confirmation message|


### withdrawBitcoinPSBT

Aids in processing a Bitcoin withdrawal by storing signed PSBT transaction created by the operator

*Only callable by the operator assigned to the pod*


```solidity
function withdrawBitcoinPSBT(address pod, uint256 amount, bytes calldata psbtTransaction, bytes calldata signature)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod processing the withdrawal|
|`amount`|`uint256`|Amount of Bitcoin being withdrawn|
|`psbtTransaction`|`bytes`|Partially Signed Bitcoin Transaction (PSBT) data created by the operator|
|`signature`|`bytes`|Operator's signature over the withdrawal data|


### withdrawBitcoinCompleteTx

Aids in completing a Bitcoin withdrawal by processing the final transaction signed by the operator

*Only callable by the operator assigned to the pod*


```solidity
function withdrawBitcoinCompleteTx(address pod, uint256 amount, bytes calldata completeTx, bytes calldata signature)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod processing the withdrawal|
|`amount`|`uint256`|Amount of Bitcoin being withdrawn|
|`completeTx`|`bytes`|Complete Bitcoin transaction data signed by the operator|
|`signature`|`bytes`|Operator's signature over the complete transaction|


### confirmWithdrawal

Confirms a Bitcoin chain withdrawal on by verifying operator signature and updating pod state

*Only callable by the operator assigned to the pod*


```solidity
function confirmWithdrawal(address pod, bytes calldata transaction, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod processing the withdrawal|
|`transaction`|`bytes`|Complete Bitcoin transaction data|
|`signature`|`bytes`|Operator's signature over the transaction data|


