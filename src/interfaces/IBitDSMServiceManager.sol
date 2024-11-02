// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@eigenlayer-middleware/src/interfaces/IServiceManager.sol";

interface IBitDSMServiceManager is IServiceManager {
    struct Task {
        string name;
        uint32 taskCreatedBlock;
    }

    function confirmDeposit(address pod, bytes calldata signature) external;
}
