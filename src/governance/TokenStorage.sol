// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenStorage is Initializable {
    // Emission Constants
    uint256 public constant TOTAL_SUPPLY = 21_000_000 * 10 ** 18; // Total supply: 21 million tokens
    uint256 public constant INITIAL_SUPPLY = TOTAL_SUPPLY / 2;  // 10.5M tokens
    uint256 public constant INITIAL_DAILY_EMISSION = 7_200 * 10 ** 18; // First period (0-4 years): 7,200 tokens per day
    uint256 public constant EMISSION_PERIOD = 20 * 365 days;   // 20 years
    uint256 public constant HALVING_PERIOD = 4 * 365 days;     // 4 years
    uint256 public constant MAX_ACCUMULATION_DAYS = 30; // Maximum accumulation period for emissions (e.g., 30 days)
    uint256 public constant MAX_DAILY_MINT = INITIAL_DAILY_EMISSION * MAX_ACCUMULATION_DAYS;
    
    // Governance Constants
    uint256 public constant TIMELOCK_MIN_DELAY = 2 days;
    uint256 public constant EMERGENCY_COOLDOWN = 1 days;
    uint256 public constant EMERGENCY_ACTION_TIMEOUT = 3 days;
    uint256 public constant MIN_GUARDIANS = 3;
    uint256 public constant MAX_GUARDIANS = 7;
    uint256 public constant GUARDIAN_TIMELOCK_DELAY = 3 days;
    

    // Token basic storage
    uint256 public startTime;
    uint256 public lastEmissionTime;
    bool public emissionsPaused;
    uint256 public lastHalvingPeriod;
    
    // Guardian system storage
    mapping(address => bool) public guardians;
    address[MAX_GUARDIANS] public guardianList;
    uint256 public guardianCount;
    uint256 public lastEmergencyAction;
    
    // Emergency actions storage
    struct EmergencyAction {
        uint256 proposedTime;
        uint256 approvals;
        bool executed;
        mapping(address => bool) hasApproved;
    }
    mapping(bytes32 => EmergencyAction) public emergencyActions;
    
    // Timelock storage
    struct TimelockOperation {
        uint256 scheduledTime;
        bool executed;
    }
    mapping(bytes32 => TimelockOperation) public timelockOperations;
    
    
    // Version control
    uint256 public constant VERSION = 1;
    
    // Storage gap for future upgrades
    uint256[50] private __gap;

    bytes4 public constant SET_EMISSIONS_PAUSED_SELECTOR = bytes4(keccak256("_setEmissionsPaused(bool)"));
    mapping(bytes32 => bool) public scheduledTokenTimelockOperations; // TokenTimeLock scheduled operations
    mapping(bytes32 => bool) public executedTokenTimelockOperations; // TokenTimeLock executed operations
} 
