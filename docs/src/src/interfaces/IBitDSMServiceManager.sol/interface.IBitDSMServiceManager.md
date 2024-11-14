# IBitDSMServiceManager
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/interfaces/IBitDSMServiceManager.sol)

**Inherits:**
IServiceManager

Interface for managing Bitcoin DSM (Decentralized Service Manager) operations

*THIS CONTRACT IS NOT AUDITED.*

*Extends IServiceManager from EigenLayer middleware
This interface defines the core functionality for:
- Managing Bitcoin deposits and withdrawals through pods
- Handling operator signatures and transaction verification
- Integrating with EigenLayer's staking and delegation system
Key operations:
- Deposit confirmation by operators
- Two-phase Bitcoin withdrawals (PSBT + complete transaction)
- Signature verification for security
The contract works in conjunction with:
- BitcoinPodManager: For pod state management
- BitcoinPod: Individual Bitcoin custody pods
- EigenLayer: For staking and operator management*


## Functions
### confirmDeposit

Confirms a Bitcoin chain deposit by verifying operator signature and updating pod state

*Only callable by the operator assigned to the pod*

*Verifies operator signature over deposit details*

*Updates pod state via BitcoinPodManager when deposit is confirmed*

*Emits BitcoinDepositConfirmed event via BitcoinPodManager*


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

*Verifies pod has pending withdrawal request*

*Validates operator signature over withdrawal details*

*Stores PSBT in pod state and emits BitcoinWithdrawalTransactionSigned event*


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

*Verifies operator controls pod before processing*

*Retrieves withdrawal address from pod state for verification*


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

*Verifies operator signature matches transaction details*

*Updates pod state via BitcoinPodManager when withdrawal is confirmed*

*Emits BitcoinWithdrawalConfirmed event via BitcoinPodManager*


```solidity
function confirmWithdrawal(address pod, bytes calldata transaction, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod processing the withdrawal|
|`transaction`|`bytes`|Complete Bitcoin transaction data|
|`signature`|`bytes`|Operator's signature over the transaction data|


## Events
### BitcoinWithdrawalTransactionSigned
Emitted when a Bitcoin withdrawal transaction is signed by an operator


```solidity
event BitcoinWithdrawalTransactionSigned(address indexed pod, address indexed operator, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pod`|`address`|Address of the Bitcoin pod processing the withdrawal|
|`operator`|`address`|Address of the operator signing the transaction|
|`amount`|`uint256`|Amount of Bitcoin being withdrawn|

