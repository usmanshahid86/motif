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
