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
    
    // Constants
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    uint256 public constant MAX_DAILY_MINT = 500000 * 10**18;
    uint256 public constant INITIAL_DAILY_EMISSION = 500000 * 10**18;
    uint256 public constant BASE_DECLINE_RATE = 50;
    uint256 public constant RATE_DENOMINATOR = 100;
    uint256 public constant EMISSION_PERIOD = 365 days;
    uint256 public constant TIMELOCK_MIN_DELAY = 2 days;
    uint256 public constant EMERGENCY_COOLDOWN = 1 days;
    uint256 public constant EMERGENCY_ACTION_TIMEOUT = 3 days;
    uint256 public constant MIN_GUARDIANS = 3;
    uint256 public constant GUARDIAN_TIMELOCK_DELAY = 3 days;
    uint256 public constant TARGET_TOTAL_SUPPLY = 140000000 * 10**18;
    
    // Version control
    uint256 public constant VERSION = 1;
    
    // Storage gap for future upgrades
    uint256[50] private __gap;
} 