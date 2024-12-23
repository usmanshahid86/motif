# RewardsSubmitter Contract

## Overview

The `RewardsSubmitter` contract enables seamless integration with EigenLayer's Rewards V2 system for efficient token emissions and reward distribution. This contract:
- **Splits Emissions**: Automatically distributes token emissions between operators and the treasury.
- **Configurable Split Ratio**: Allows customization of reward percentages for operators and treasury allocations.
- **Daily Submission Interval**: Matches the token emission schedule to ensure regular updates.
- **EigenLayer Integration**: Utilizes EigenLayer's `RewardsCoordinator` for operator reward distributions.
- **Treasury Management**: Maintains treasury funds for team, investors, or exchange allocations.

---

## Features
1. Automatically splits emissions between operators and treasury.
2. Configurable split ratio (e.g., `70%` for operators, `30%` for treasury).
3. Supports a daily submission interval for token emissions.
4. Integrates with EigenLayer’s `RewardsCoordinator` for operator distributions.
5. Allows for secure treasury fund management via multi-signature wallets.

---

## How to Implement

### Steps to Deploy
1. Deploy the `RewardsSubmitter` contract.
2. Set it as the distributor in your `Token.sol` contract.
3. Configure the operator rewards percentage (e.g., `7000` for `70%`).
4. Set up a **treasury multisig** for non-operator funds.

## Benefits of This Implementation

- **Automated Operator Rewards**: Automatically calculates and distributes rewards to operators using EigenLayer.
- **Configurable Split Ratio**: Flexible reward allocation between operators and treasury.
- **Treasury Control**: Ensures non-operator funds are securely managed for broader ecosystem support.
- **Upgradeability**: Supports future enhancements with upgradable contract design.
- **Gas Efficiency**: Optimized for minimal overhead during daily emissions and reward submissions.

---

## Notes for Customization

- **Strategies and Multipliers**: Customize the `_getStrategiesAndMultipliers` function based on your specific staking strategies and weights.
- **Treasury Management**: Use a multisig wallet for secure and collaborative treasury operations.
- **Pause Functionality**: Leverage the pause mechanism to handle unexpected events without disruption.

---

## Future Enhancements

1. **Dynamic Emission Rates**: Introduce logic for emission adjustments based on market or protocol conditions.
2. **Epoch-Based Submissions**: Extend the interval system to epochs for greater flexibility.
3. **Multisig Integration**: Add multisig functionality for key operations like treasury updates and emission approvals.
