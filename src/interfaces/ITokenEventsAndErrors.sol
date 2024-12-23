// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenInterface {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Token Operation Events
   event AccumulatedEmission(
        uint256 daysAccumulated,
        uint256 amountMinted,
        uint256 newTotalSupply,
        uint256 timestamp,
        uint256 currentHalvingPeriod,    // Add this
        uint256 nextDailyEmission        // Add this
    );
    event EmissionsPaused(bool isPaused);

    /// @notice Guardian System Events
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    
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
    event TokenTimelockOperationScheduled(
        bytes32 indexed operationId,
        address target,
        uint256 value,
        bytes data,
        uint256 executeTime
    );

    event TokenTimelockOperationExecuted(
        bytes32 indexed operationId,
        address target,
        uint256 value,
        bytes data
    ); 
    event TokenTimelockOperationCancelled(bytes32 indexed operationId);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Operation Errors
    error EmissionsPausedError();
    error SupplyCapExceeded(uint256 attempted, uint256 cap);
    
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
    error UnauthorizedCaller();
    error InvalidAddress();
    error EmissionPeriodExceeded();
    error InvalidEmissionAmount();
    error HalvingPeriodNotReached();
} 