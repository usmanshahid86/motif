// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBitcoinPod {
    function createPod() external;
    function depositIntoStrategy(uint256 amount, address strategy) external;
    function withdrawFromStrategy(uint256 amount, address strategy) external;
    // Add other functions as per the spec
}
