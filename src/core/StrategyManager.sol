// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IStrategyManager.sol";

contract StrategyManager is IStrategyManager {
    function createStrategy(address app, bytes calldata data) external {
        // Implementation of creating a strategy
    }

    function updateStrategy(address app, bytes calldata data) external {
        // Implementation of updating a strategy
    }

    function deleteStrategy(address app) external {
        // Implementation of deleting a strategy
    }
}