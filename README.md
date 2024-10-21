# BitDSM AVS

Welcome to the BitDSM AVS. 

This is an attempt to deploy the [BitDSM](https://github.com/hammadtq/BitDSM) project as an AVS service on Eigenlayer App. 
[Hello-world-avs](https://github.com/Layr-Labs/hello-world-avs) codebase is modified to create script for deploying BitDSM on Holeskey Testnet. 


## AVS User Flow

1) AVS consumer requests a task that creates a lock on the Bitcoin stored in the bod. 
2) BitDSM contract receives the request and emits a NewLockBitcoinTaskCreated event for the request.

That's it. 

### Disclaimers

- This repo is currently intended for _Holesky deployment testing_. 
- _Local anvil development_ support will be added later.

  
# Deploy AVS contracts to Holesky using Foundry

## build-contracts: builds all contracts
```
	cd contracts && forge build

```

## deploy-contracts: deploy all contracts

```
forge script script/BitDSMDeployer.s.sol:BitDSMDeployer \
    --rpc-url https://ethereum-holesky-rpc.publicnode.com --private-key $PRIVATE_KEY --broadcast 
```

# Existing Holesky Testnet Deployment

| Contract Name               | Holesky Address                                     | 
| -------------               | -------------                                       |
| BodManager                  | [0x0EAe257D92b0244F4239713c4980Fc15aC2052B8](https://holesky.etherscan.io/address/0x0EAe257D92b0244F4239713c4980Fc15aC2052B8)   |
| BodExample                  | [0x42c508D388e1f701e5C23a062D7073e5C642f24b](https://holesky.etherscan.io/address/0x42c508D388e1f701e5C23a062D7073e5C642f24b)   |
| CDPContract                 | [0xD77e13C8cA101da550D00A00Ca4FD6009398f8Ee](https://holesky.etherscan.io/address/0xD77e13C8cA101da550D00A00Ca4FD6009398f8Ee)   |
| BitDSMAVS (ServiceManager)  | [0xd52a4fa802368ec764083cc0fd2980762e735f73](https://holesky.etherscan.io/address/0xd52a4fa802368ec764083cc0fd2980762e735f73)   |
| BitDSMServiceManagerImpl    | [0xee50df1e39c37a6d39118116a1fd10fb43753b40](https://holesky.etherscan.io/address/0xee50df1e39c37a6d39118116a1fd10fb43753b40)   |   
| stakeRegistry               | [0x97985fb32db1e826c62c93e18e81fddec87b226a](https://holesky.etherscan.io/address/0x97985fb32db1e826c62c93e18e81fddec87b226a)   |
| stakeRegistryImpl           | [0x50916b90f84f7aebfeeb22d872bc78f87853eeb3](https://holesky.etherscan.io/address/0x50916b90f84f7aebfeeb22d872bc78f87853eeb3)   | 
| ankerEth Strategy           | [0x7673a47463f80c6a3553db9e54c8cdcd5313d0ac]        |
Please see [Current Testnet Deployment](https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment) for additional deployed addresses of core EigenLayer contracts.


## Access Deployment Files 
Contract deployment files including the abi's can be found at the following address. 

```
DEPLOYMENT_FILES_DIR=contracts/script/output/${CHAINID}
```



