// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBitcoinPodManager {
    function createPod(address strategy) external;
    function depositIntoPod(address pod, uint256 amount) external;
    function withdrawFromPod(address pod, uint256 amount) external;
    function liquidatePod(address pod) external;
}
