# BitDSM Rewards Distribution Framework

The BitDSM Rewards Distribution Framework is designed to handle the emission, allocation, and distribution of rewards for operators and application-specific validators (AVSs). This framework includes two core smart contracts:

1. **RewardSubmitter.sol**: Handles the daily emissions, calculates splits, and distributes rewards.
2. **DAOContract.sol**: Manages governance-related configurations, such as reward splits and AVS weights.

## Overview

This implementation ensures efficient, fair, and scalable reward distribution while allowing dynamic configurations via DAO governance.

### Key Features

- **Dynamic Reward Splits**: The reward split between operators and AVSs can be adjusted via the DAO.
- **Proportional AVS Rewards**: Rewards are distributed among AVSs based on their weighted contributions.
- **Operator Incentives**: Incentivizes operators to maintain the integrity and security of the ecosystem.
- **Upgradeability**: Supports seamless upgrades to governance and reward logic.
- **DAO Integration**: Centralized governance for configurations with the potential to expand into a decentralized DAO.

---

## Contract Interactions

### **RewardSubmitter.sol**

This contract handles the emission and distribution of rewards. It integrates with `DAOContract` to dynamically fetch configurations like splits and AVS weights.

#### Workflow:
1. **Emit Tokens**: The `submitEmissionRewards` function triggers token emissions from the `BitDSMToken` contract.
2. **Fetch Configurations**: Reward splits (e.g., operator vs. AVS) and AVS weights are fetched from `DAOContract`.
3. **Operator Rewards**:
   - Allocates the operator's share of rewards.
   - Distributes the rewards using EigenLayer's `RewardsCoordinator`.
4. **AVS Rewards**:
   - Allocates the AVS share of rewards.
   - Distributes rewards to active AVSs proportionally based on their weights.

#### Key Functions:
- `submitEmissionRewards`: Handles daily emissions and distributes rewards.
- `setDAOContract`: Updates the DAO contract for governance configurations.

#### Events:
- `RewardsSubmitted`: Emitted when rewards are successfully distributed.
- `DAOContractUpdated`: Emitted when the DAO contract address is updated.

---

### **DAOContract.sol**

This contract acts as the governance layer for reward configurations, allowing adjustments to splits and AVS weights.

#### Workflow:
1. **Define Reward Splits**:
   - `operatorSplitBips`: Percentage of rewards allocated to operators (in basis points).
   - `avsSplitBips`: Percentage of rewards allocated to AVSs.
2. **Manage AVS Weights**:
   - Adds or removes AVSs.
   - Updates weights for active AVSs.
3. **Governance by Multisig**:
   - Configurations and updates are controlled by a multisig address.

#### Key Functions:
- `setRewardSplits`: Updates the reward split percentages.
- `addOrUpdateAVS`: Adds or updates an AVS with a specific weight.
- `removeAVS`: Removes an AVS from the active list.
- `getAVSWeight`: Retrieves the weight of a specific AVS.
- `getTotalWeight`: Calculates the total weight of all active AVSs.

#### Events:
- `RewardSplitsUpdated`: Emitted when the reward splits are updated.
- `AVSUpdated`: Emitted when an AVS is added or updated.
- `AVSRemoved`: Emitted when an AVS is removed.

---

## How `RewardSubmitter` and `DAOContract` Work Together

1. The `RewardSubmitter` contract retrieves the reward split configuration (`operatorSplitBips` and `avsSplitBips`) from the `DAOContract`.
2. The `RewardSubmitter` contract calculates the operator's share of rewards and distributes it using EigenLayer's `RewardsCoordinator`.
3. The remaining AVS rewards are distributed proportionally based on the weights managed by the `DAOContract`.
4. The `DAOContract` ensures flexibility by allowing updates to reward splits and AVS weights through multisig governance.

---

## Example Use Case

1. **Token Emission**:
   - `submitEmissionRewards` is called on `RewardSubmitter`.
   - Rewards are emitted from `BitDSMToken` to `RewardSubmitter`.

2. **Operator Rewards**:
   - 70% of rewards (as an example) are allocated to operators.
   - These rewards are submitted to EigenLayer's `RewardsCoordinator`.

3. **AVS Rewards**:
   - The remaining 30% is distributed among AVSs based on their weights.

4. **Governance**:
   - The multisig wallet updates the reward split to 60:40 (operator:AVS).
   - An AVS weight is adjusted to reflect its contribution to the ecosystem.

---

## Future Enhancements

- **Decentralized Governance**: Expand the DAO to allow community voting on reward splits and AVS weights.
- **Dynamic Emission Rates**: Introduce market-driven emission adjustments.
- **Support for New Applications**: Add modularity for additional reward distribution mechanisms.

---

## Deployment Instructions

1. Deploy `BitDSMToken` and initialize it with the initial owner and supply distributor.
2. Deploy `DAOContract` and configure the multisig wallet.
3. Deploy `RewardSubmitter` and initialize it with the token, rewards coordinator, and DAO contract addresses.
4. Set `RewardSubmitter` as the distributor in `BitDSMToken`.
5. Configure reward splits and AVS weights in `DAOContract`.

---

## Conclusion

The `RewardSubmitter` and `DAOContract` work in tandem to provide a flexible, scalable, and decentralized reward distribution framework for the BitDSM ecosystem. This architecture ensures fairness, incentivization, and adaptability for both operators and AVSs, laying the groundwork for a robust and sustainable ecosystem.
