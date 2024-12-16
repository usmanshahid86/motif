// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenInterface {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Token Operation Events
    event TokensEmitted(uint256 amount, uint256 newTotalSupply, uint256 timestamp);
    event EmissionsPaused(bool isPaused);
    event MaxSupplyCapUpdated(uint256 newCap);
    event EmissionRateAdjusted(uint256 oldRate, uint256 newRate);
    
    /// @notice Guardian System Events
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event GuardianOperationFailed(
        bytes32 indexed operationId,
        address indexed guardian,
        string operationType,
        string reason
    );
    
    /// @notice Emergency System Events
    event EmergencyActionProposed(bytes32 indexed actionId, string actionType);
    event EmergencyActionApproved(bytes32 indexed actionId, address indexed guardian);
    event EmergencyActionExecuted(bytes32 indexed actionId);
    event EmergencyActionFailed(
        bytes32 indexed actionId,
        string actionType,
        string reason
    );
    event EmergencyTokensBurned(address indexed from, uint256 amount);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);
    
    /// @notice Timelock Events
    event TimelockOperationCancelled(
        bytes32 indexed operationId,
        address indexed guardian,
        string operationType
    );
    event GuardianChangeScheduled(
        bytes32 indexed operationId,
        address indexed guardian,
        bool isAddition,
        uint256 scheduledTime
    );
    event ActionScheduled(bytes32 indexed actionId, uint256 executionTime);
    event EmissionHalved(uint256 indexed halvingPeriod, uint256 newEmissionRate);
    
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Operation Errors
    error EmissionsPausedError();
    error SupplyCapExceeded(uint256 attempted, uint256 cap);
    error InvalidRate(uint256 rate);
    error RateTooHigh(uint256 rate);
    error RateTooLow(uint256 rate);
    
    /// @notice Guardian System Errors
    error NotGuardian();
    error InvalidGuardianCount();
    error InsufficientGuardians();
    error GuardianAlreadyExists();
    error GuardianDoesNotExist();
    
    /// @notice Emergency Action Errors
    error NotEnoughApprovals();
    error AlreadyApproved();
    error ActionExpired();
    error EmergencyCooldownNotPassed();
    
    /// @notice Timelock Errors
    error TimelockNotReady();
    error OperationNotScheduled();
    error OperationAlreadyExecuted();
    error InvalidOperation();
    
    /// @notice Access Control Errors
    error Blacklisted(address account);
    error UnauthorizedCaller();
    error InvalidAddress();
    error EmissionPeriodExceeded();
    error InvalidEmissionAmount();
    error HalvingPeriodNotReached();
} 