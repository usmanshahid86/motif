# BitcoinPodManagerStorage
[Git Source](https://github.com/hammadtq/BitDSM/blob/03e12ea1c014ff832e71dc625d1580cea6d3bafe/src/storage/BitcoinPodManagerStorage.sol)

Storage contract for BitcoinPodManager

*Contains all state variables used by BitcoinPodManager*


## State Variables
### _totalTVL
Total Value Locked in all pods (in satoshis)


```solidity
uint256 internal _totalTVL;
```


### _bitDSMServiceManager
Address of the BitDSMService manager contract


```solidity
address internal _bitDSMServiceManager;
```


### _appRegistry
Address of the App Registry contract


```solidity
address internal _appRegistry;
```


### _bitDSMRegistry
Address of the BitDSM Registry contract


```solidity
address internal _bitDSMRegistry;
```


### _userToPod
Mapping of user address to their pod address


```solidity
mapping(address => address) internal _userToPod;
```


### _podToApp
Mapping of pod address to the app address it is delegated to


```solidity
mapping(address => address) internal _podToApp;
```


### _podToBitcoinDepositRequest
Mapping of pod address to the Bitcoin deposit request


```solidity
mapping(address => IBitcoinPodManager.BitcoinDepositRequest) internal _podToBitcoinDepositRequest;
```


### _podToWithdrawalAddress
Mapping of pod address to the withdrawal address


```solidity
mapping(address => bytes) internal _podToWithdrawalAddress;
```


### __gap
Struct to store Bitcoin deposit request details

*Tracks the status and details of pending Bitcoin deposit requests*

*Gap for future storage variables*


```solidity
uint256[50] private __gap;
```


## Functions
### _setUserPod

*Internal setters*


```solidity
function _setUserPod(address user, address pod) internal;
```

### _setPodApp


```solidity
function _setPodApp(address pod, address app) internal;
```

