# Shared Pod Delegation Example

This directory contains example implementations demonstrating how Bitcoin pods could be shared among multiple applications in BitDSM.

## Key Concepts

### Share-Based Delegation
Instead of delegating a pod to a single app, pod owners can:
- Divide their pod into 100 shares
- Allocate shares to multiple apps
- Modify share allocations dynamically
- Track rewards per share

### Benefits
1. More efficient pod utilization
2. Flexible reward distribution
3. Risk diversification across apps
4. Lower barrier to entry for apps

## Implementation Details

### SharedBitcoinPod
- Extends current BitcoinPod functionality
- Adds share tracking per app
- Implements reward calculation based on shares
- Maintains list of registered apps

### SharedBitcoinPodManager
- Manages creation of shared pods
- Handles share allocation/removal
- Integrates with AppRegistry
- Tracks pod ownership

## Example Usage

```solidity
// Create a shared pod with initial allocations
address[] memory apps = new address[](2);
apps[0] = app1;
apps[1] = app2;

uint256[] memory shares = new uint256[](2);
shares[0] = 60; // 60% to app1
shares[1] = 40; // 40% to app2

address pod = podManager.createSharedPod(operator, btcAddress, apps, shares);

// Later, modify shares
podManager.modifyShares(pod, app1, 50); // Change app1 to 50%
podManager.modifyShares(pod, app3, 10); // Add app3 with 10%
```

## Migration Path

To implement this feature:
1. Create new contracts alongside existing ones
2. Add migration functions to allow converting single-app pods to shared pods
3. Update frontend to support both delegation types
4. Add share management UI for pod owners

## Security Considerations

1. Share total must never exceed 100
2. Only pod owner can modify shares
3. Apps must be registered in AppRegistry
4. Reward calculations must be accurate and fair