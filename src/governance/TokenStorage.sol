// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenStorage is Initializable {
    // Token basic storage
    uint256 public startTime;
    uint256 public lastEmissionTime;
    uint256 public emissionRate;
    uint256 public maxSupplyCap;
    bool public emissionsPaused;
    
    // Guardian system storage
    mapping(address => bool) public guardians;
    address[] public guardianList;
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
    
    // Daily limits storage
    mapping(uint256 => uint256) public dailyMinted;
    
    // Blacklist storage
    mapping(address => bool) public blacklisted;
    
    // Base units (18 decimals)
    uint256 public constant DECIMALS = 18;
    uint256 public constant ONE_TOKEN = 10**DECIMALS;
    
    // Total supply: 21 million tokens
    uint256 public constant TOTAL_SUPPLY = 21_000_000 * ONE_TOKEN;
    uint256 public constant LOCKED_SUPPLY = TOTAL_SUPPLY / 2;  // 10.5M tokens
    
    // First period (0-4 years): 7,200 tokens per day
    uint256 public constant INITIAL_DAILY_EMISSION = 7_200 * ONE_TOKEN;
    
    uint256 public constant EMISSION_PERIOD = 20 * 365 days;   // 20 years
    uint256 public constant HALVING_PERIOD = 4 * 365 days;     // 4 years
    
    // Constants
    uint256 public constant MAX_DAILY_MINT = INITIAL_DAILY_EMISSION;
    uint256 public constant TIMELOCK_MIN_DELAY = 2 days;
    uint256 public constant EMERGENCY_COOLDOWN = 1 days;
    uint256 public constant EMERGENCY_ACTION_TIMEOUT = 3 days;
    uint256 public constant MIN_GUARDIANS = 3;
    uint256 public constant GUARDIAN_TIMELOCK_DELAY = 3 days;
    
    // Version control
    uint256 public constant VERSION = 1;
    
    // Storage gap for future upgrades
    uint256[50] private __gap;
} 