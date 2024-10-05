# BitDSM AVS

Welcome to the BitDSM AVS. This is an attempt to deploy the [BitDSM](https://github.com/hammadtq/BitDSM) project as an AVS service on Eigenlayer App. [Hello-world-avs](https://github.com/Layr-Labs/hello-world-avs) codebase is modified to create script for deploying BitDSM on Holeskey Testnet. 


## AVS User Flow

1) AVS consumer requests a task that creates a lock on the Bitcoin stored in the bod. 
2) BitDSM contract receives the request and emits a NewLockBitcoinTaskCreated event for the request.

That's it. This simple flow highlights some of the core mechanics of how AVSs work.

### Disclaimers

- This repo is currently intended for Holesky deployment testing_. _Local anvil development support will be added shortly.
- Users who wish to build an AVS for Production purposes will want to migrate from the `ECDSAServiceManagerBase` implementation in `BitDSMAVS.sol` to a BLS style architecture using [RegistryCoordinator](https://github.com/Layr-Labs/eigenlayer-middleware/blob/dev/docs/RegistryCoordinator.md).

  
# Deploy AVS contracts to Holesky using Foundry
build-contracts: ## builds all contracts
	cd contracts && forge build

deploy-contracts:: ## deploy all contracts
forge script script/DeployerHolesky.s.sol:DeployerHolesky \
    --rpc-url $URL --private-key $PRIVATE_KEY --broadcast -vvv debug
```

# Existing Holesky Testnet Deployment

| Contract Name               | Holesky Address                                   | 
| -------------               | -------------                                     |
| BitDSMAVS Service Manager   | [0x923E6434FDD6c111df90F2f9D1A5b03E7A5e0EA3]        (https://holesky.etherscan.io/address/0xed0425f6ae26657c513c5d65dfb9596e16001f92)    |

Please see [Current Testnet Deployment](https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment) for additional deployed addresses.

# Make sure to update this if the strategy address changes
  DEPLOYMENT_FILES_DIR=contracts/script/output/${CHAINID}




