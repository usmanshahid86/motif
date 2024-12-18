// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function emitNewTokens(address distributor) external returns (uint256, uint256);
    function getPendingEmissions() external view returns (
        uint256 pendingAmount,
        uint256 daysAccumulated,
        uint256 nextDailyEmission
    );
    function getNextEmissionAmount() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}