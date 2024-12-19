# Reward Distribution Mechanism (Version 1)

## Overview
This reward distribution mechanism is designed to incentivize applications (apps) directly within the BitDSM ecosystem based on predefined weights. The system uses a token emission process that sends rewards to registered apps, which can either receive tokens directly or claim them on-demand. Apps are expected to implement their own mechanisms for further redistribution to their contributors (e.g., TVL providers) but are provided with optional interface templates to facilitate this.

---

## Objectives
- Incentivize apps fairly based on dynamically adjustable weights.
- Provide flexibility for apps to decide how to reward their TVL providers or users.
- Ensure a transparent, decentralized, and efficient token distribution mechanism.

---

## Components
1. **Token.sol**:
   - Handles periodic token emissions.
   - Sends emitted tokens to the `AppRegistry.sol` contract.

2. **AppRegistry.sol**:
   - Manages the list of whitelisted apps eligible to receive rewards.
   - Reads weights assigned to each app from the `Multisig.sol` contract.
   - Supports two options for apps to access their rewards:
     1. **Direct Transfer**: Automatically sends rewards to the app's EOA address.
     2. **Self-Claiming**: Apps can claim rewards on-demand by calling a function and paying gas fees.

3. **Multisig.sol**:
   - Defines the reward weights for each whitelisted app.
   - Maintains decentralized control, allowing stakeholders to adjust weights as needed.
   - Serves as the source of truth for `AppRegistry.sol` during reward allocation.

---

## Mechanism Flow

1. **Token Emission**:
   - `Token.sol` emits tokens periodically (e.g., per block or epoch).
   - Tokens are transferred to `AppRegistry.sol` for further distribution.

2. **Weight-Based Distribution**:
   - `AppRegistry.sol` queries the `Multisig.sol` contract to determine the reward weights for each app.
   - The weights define the proportion of the emitted tokens allocated to each app.

3. **Reward Distribution**:
   - Apps can access their allocated tokens in one of two ways:
     1. **Direct Transfer**:
        - Tokens are automatically sent to the app's EOA address after each emission cycle.
     2. **Self-Claiming**:
        - Apps call a function in `AppRegistry.sol` to withdraw their rewards, paying gas fees for the transaction.

4. **Optional Redistribution by Apps**:
   - Apps are encouraged to redistribute tokens to their TVL providers or users as needed.
   - A reference interface will be provided to simplify the implementation of redistribution mechanisms.
   - Redistribution rules (e.g., TVL providers receiving 80% of app rewards) are optional and must be enforced by the app itself.

5. **Dynamic Weight Adjustments**:
   - `Multisig.sol` allows weights to be updated via decentralized governance or stakeholder agreement.
   - This ensures flexibility and adaptability as the ecosystem evolves.

---

## Open Questions
- Should the protocol enforce redistribution rules (e.g., requiring apps to allocate 80% of tokens to TVL providers), or should it remain entirely optional?
- Is there a need for a Merkle tree or similar structure to optimize claimable rewards, particularly for scalability?
- Is there any other leg of the product here? Like native bitcoin staking AVS operators that are encouraged to use bitcoin pods as shared security among themselves? Are they an app that go through the app registry? Or do they integrate natively through another mechanism?