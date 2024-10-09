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

| Contract Name               | Holesky Address                                                                                                                 | 
| -------------               | --------------------------------------------------------------------                                                            |
| BodManager                  | [0x0f8f80B3c08672Aafc42484fca9ddbBF13cB73df](https://holesky.etherscan.io/address/0x0f8f80B3c08672Aafc42484fca9ddbBF13cB73df)   |
| BodExample                  | [0x42c508D388e1f701e5C23a062D7073e5C642f24b](https://holesky.etherscan.io/address/0x42c508D388e1f701e5C23a062D7073e5C642f24b)   |
| CDPContract                 | [0x1b44f151D36a6439fB2Cf3639242307c21238A29](https://holesky.etherscan.io/address/0x1b44f151D36a6439fB2Cf3639242307c21238A29)   |
| BitDSMAVS (ServiceManager)  | [0x9e09c22b6ffdbb35083966af90020214f52be16e](https://holesky.etherscan.io/address/0x9e09c22b6ffdbb35083966af90020214f52be16e)   |
| BitDSMServiceManagerImpl    | [0xB301332d451918bd91D4b0FBAeff2d45d2ec5912](https://holesky.etherscan.io/address/0xb301332d451918bd91d4b0fbaeff2d45d2ec5912)   |   
| stakeRegistry               | [0x75e9e52cbd55586aca2fe0c0de7f471b78b09fe9](https://holesky.etherscan.io/address/0x75e9e52cbd55586aca2fe0c0de7f471b78b09fe9)   |
| stakeRegistryImpl           | [0xf0de4f21eed29829b665a9ef7a91fcae9b39db25](https://holesky.etherscan.io/address/0xf0de4f21eed29829b665a9ef7a91fcae9b39db25)   |

Please see [Current Testnet Deployment](https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment) for additional deployed addresses of core EigenLayer contracts.


## Access Deployment Files 
Contract deployment files including the abi's can be found at the following address. 

```
DEPLOYMENT_FILES_DIR=contracts/script/output/${CHAINID}
```



