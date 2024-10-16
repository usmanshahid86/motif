// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBitcoinPodManager {
    function createPod(address operator, bytes memory btcAddress) external;
    function delegatePod(address pod, address appContract) external;
    function undelegatePod(address pod) external;
    function mintBitcoin(address pod, uint256 amount) external;
    function burnBitcoin(address pod, uint256 amount) external;
    function lockPod(address pod) external;
    function unlockPod(address pod) external;
}
