// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManager {
    function createStrategy(address app, bytes calldata data) external;
    function updateStrategy(address app, bytes calldata data) external;
    function deleteStrategy(address app) external;
}
