## BitDSM

**BitDSM brings native Bitcoin staking to the ethereum.**

Users can build:

-   **Stable Coins**: CDP based stable coins backed by native Bitcoin locked via PSBT.
-   **Lend and Borrowing**: Collateral-lock based financial products such as lending/borrowing.
-   **Bridge**: Can you locked Bitcoin to act as a Bridge.


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
