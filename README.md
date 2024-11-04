## BitDSM : Bitcoin Delegated Staking Mechanism
![Bitcoin Abstract Cover](./assets/cover.webp)

**BitDSM brings native Bitcoin delegation to ethereum applications.**

The BitcoinPod (BOD) is the core component of BitDSM, modeled after the EigenPod concept. A BOD is a non-custodial vault on the Bitcoin network, created using a P2WSH bitcoin address. The primary objective of the BitcoinPod is to ensure that a smart contract can slash the BOD for predetermined conditions for the value already held in the BitcoinPod or set to be processed through it. 

To accomplish this, BOD:
- function as the withdrawal address for one or more PoS validators managed by the BOD Owner
- verify pre-signed unbonding transactions from the source chain
- continuously monitor the Bitcoin blockchain to track the status of all BitcoinPods
- provide a delegation mechanism to other smart contracts via BOD manager. 

A BOD can be stateful or stateless, ie, either the bitcoins are held in it or the BOD is set as a withdrawal/unbonding address for a PoS validator on another chain. 

BOD is not a bridge nor does it mint any ERC-20. It is merely a way to delegate your spending authority to a smart contract. This enables other financial applications to be built on top of it like:
1. LSTs: PoS validators using Bitcoin to secure their chains can set withdrawal address as the BOD to mint an LST on ethereum. 
2. Lending/Borrowing: BOD can be locked as the collateral for borrowing a stable asset on Ethereum. 
3. Stable Coin: BOD can act as a CDP to mint a stable asset.
4. Insurance: BOD can act as an insurance for a BTC Bridge on Ethereum. 
5. BTC Bridge: BOD can act as a deposit address for minting a wrapped version of Bitcoin on Ethereum. 

BitcoinPods are bootstrapped using restaked security available to the AVS of Eigenlayer. BitcoinPods can be issued by operator sets with predetermined independent tasks, and can be secured either by an insurance built using BitDSM or with LRTs on Ethereum.

Front end link: https://bod-frontend.vercel.app/app

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/deploy.s.sol:DeployScript --fork-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
```

### To-Do
EigenLayer AVS deployment and operator registration.

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Deployment

```shell
$ forge script script/DeployBitDSM.s.sol:DeployBitDSM --fork-url http://localhost:8545 --broadcast --private-key $PRIVATE_KEY
```

## Existing Holesky Testnet Deployment 
 
| Contract Name                               | Holesky Address                                                                                                                 | 
| -------------                               | --------------------------------------------------------------------                                                            |
| ProxyAdmin                                  | [0x71e4efecf796bbbc562f639adde036784f67a563](https://holesky.etherscan.io/address/0x71e4efecf796bbbc562f639adde036784f67a563)   |
| BitDSMRegistry                              | [0x9619e0b51531ba2607d55422d66b14c570d5de7a](https://holesky.etherscan.io/address/0x9619e0b51531ba2607d55422d66b14c570d5de7a)   |
| BitDSMRegistryImplementation                | [0x641ff9a3d79f24fe45fb6b7351bcb43c2e7aed44](https://holesky.etherscan.io/address/0x641ff9a3d79f24fe45fb6b7351bcb43c2e7aed44)   |
| BitDSmServiceManager                        | [0x3e091b2318356b1aa1d5f0bd846e956b48beb238](https://holesky.etherscan.io/address/0x3e091b2318356b1aa1d5f0bd846e956b48beb238)   |
| BitDSMServiceManagerImplementation          | [0x95c13186d9d128e2b2a8e2762c39635bc49038c0](https://holesky.etherscan.io/address/0x95c13186d9d128e2b2a8e2762c39635bc49038c0)   |
| AppRegistry                                 | [0xd2a6d4e2f8faf4ee980be7ff43fb9e47b496b475](https://holesky.etherscan.io/address/0xd2a6d4e2f8faf4ee980be7ff43fb9e47b496b475)   |   
| AppRegistryImplementation                   | [0x8dad35e5f7f76b1dbf5874db00616e296a81123c](https://holesky.etherscan.io/address/0x8dad35e5f7f76b1dbf5874db00616e296a81123c)   |
| BitcoinPodManager                           | [0x3fab0a58446da7a0703c0856a7c05abfa5a0f964](https://holesky.etherscan.io/address/0x3fab0a58446da7a0703c0856a7c05abfa5a0f964)   |
| BitcoinPodManagerImplementation             | [0x8e152c04f082233de0435da6142cda04e0403dc2](https://holesky.etherscan.io/address/0x8e152c04f082233de0435da6142cda04e0403dc2)   |

Please see [Current Testnet Deployment](https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment) for additional deployed addresses of core EigenLayer contracts.


## Access Deployment Files 
Contract deployment files including the abi's can be found at the following address. 

```
DEPLOYMENT_FILES_DIR=contracts/script/output/${CHAINID}
```
