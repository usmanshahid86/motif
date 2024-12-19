// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITokenEventsAndErrors.sol";

interface IToken is ITokenInterface {
    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    
    function initialize(address initialOwner, address initialSupplyDistributor) external;

    /*//////////////////////////////////////////////////////////////
                            TOKEN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                            EMISSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function emitNewTokens(address distributor) external returns (uint256, uint256);
    function getPendingEmissions() external view returns (
        uint256 pendingAmount,
        uint256 daysAccumulated,
        uint256 nextDailyEmission
    );
    function getNextEmissionAmount() external view returns (uint256);
    function getEmissionStats() external view returns (
        uint256 currentSupply,
        uint256 remainingTime,
        uint256 nextEmission,
        bool isPaused
    );
    function getDetailedEmissionStats() external view returns (
        uint256 currentSupply,
        uint256 pendingEmissions,
        uint256 daysAccumulated,
        uint256 nextEmission,
        uint256 remainingTime
    );

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function setEmissionsPaused(bool pause) external;

    /*//////////////////////////////////////////////////////////////
                            GUARDIAN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function scheduleAddGuardian(address guardian) external;
    function executeAddGuardian(bytes32 operationId, address guardian) external;
    function scheduleRemoveGuardian(address guardian) external;
    function executeRemoveGuardian(bytes32 operationId, address guardian) external;

    /*//////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function proposeEmergencyPause() external;
    function proposeEmergencyUnpause() external;
    function proposeEmergencyBurn(address from, uint256 amount) external;
    function approveEmergencyAction(bytes32 actionId) external;
    function executeEmergencyPause(bytes32 actionId) external;
    function executeEmergencyUnpause(bytes32 actionId) external;
    function emergencyWithdraw(address token, address to, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                            TIMELOCK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function scheduleSetEmissionsPaused(bool pause) external;
    function executeTimelockOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external;
    function cancelTimelockOperation(
        bytes32 operationId,
        address guardian,
        string memory operationType
    ) external;

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    
    function getStartTime() external view returns (uint256);
    function getLastEmissionTime() external view returns (uint256);
    function getTotalSupply() external pure returns (uint256);
    function getEmissionsPaused() external view returns (bool);
    function getGuardians(address) external view returns (bool);
    function getGuardianList() external view returns (address[] memory);
} 