// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAppMetrics {
    struct MetricsData {
        uint256 tvl;                  // Total value locked
        uint256 uniqueUsers;          // Number of unique users
        uint256 transactionCount;     // Total transactions
        uint256 retentionScore;       // User retention score (0-10000)
        uint256 lastUpdateBlock;      // Last block metrics were updated
        bool isActive;                // If app is currently active
    }

    event MetricsUpdated(
        address indexed app,
        uint256 tvl,
        uint256 uniqueUsers,
        uint256 transactionCount,
        uint256 retentionScore
    );

    function getAppMetrics(address app) external view returns (MetricsData memory);
    function updateMetrics(
        uint256 newTvl,
        uint256 newUniqueUsers,
        uint256 newTransactionCount,
        uint256 newRetentionScore
    ) external;
}
