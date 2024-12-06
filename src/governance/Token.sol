// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./TokenStorage.sol";
import "../interfaces/ITokenEventsAndErrors.sol";
import "./TokenTimelock.sol";

contract BitDSMToken is 
    TokenStorage,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ITokenInterface
{
    // Add initializing flag
    bool private initializing;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner
    ) public initializer {
        initializing = true;  // Set flag before initialization
        __ERC20_init("BitDSM Token", "BDSM");
        __Ownable_init();
        _transferOwnership(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();

        startTime = block.timestamp;
        lastEmissionTime = startTime;
        _mint(initialOwner, INITIAL_SUPPLY);
        maxSupplyCap = TARGET_TOTAL_SUPPLY;
        initializing = false;  // Reset flag after initialization

        guardianList = new address[](0);
    }

    /**
     * @dev Modifier to check if emissions are allowed
     */
    modifier whenEmissionsNotPaused() {
        if (emissionsPaused) revert EmissionsPausedError();
        _;
    }
    // Add blacklist functionality 
    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Blacklisted");
        _;
    }

    /**
     * @dev Set the blacklist status of an account
     * @param user The address to update
     * @param status The blacklist status to set (true for blacklisted, false for not blacklisted)
     */
    function setBlacklisted(address user, bool status) external onlyOwner {
        blacklisted[user] = status;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        if (!initializing) {
            uint256 day = block.timestamp / 1 days;
            require(dailyMinted[day] + amount <= MAX_DAILY_MINT, "Daily mint limit");
            dailyMinted[day] += amount;
        }
        super._mint(account, amount);
    }

    /**
     * @dev Pause or unpause emissions
     * @param pause True to pause, false to unpause
     */
    function setEmissionsPaused(bool pause) external onlyOwner {
        emissionsPaused = pause;
        emit EmissionsPaused(pause);
    }

    /**
     * @dev Update the maximum supply cap
     * @param newCap New maximum supply cap
     */
    function setMaxSupplyCap(uint256 newCap) external onlyOwner {
        require(newCap >= totalSupply(), "Cap cannot be less than current supply");
        maxSupplyCap = newCap;
        emit MaxSupplyCapUpdated(newCap);
    }

    /**
     * @dev Calculates and mints new tokens based on declining emission curve
     * @param distributor Address to receive the new tokens
     */
    function emitNewTokens(address distributor) external nonReentrant whenEmissionsNotPaused {
        require(block.timestamp >= lastEmissionTime + 1 days, "Wait 24 hours between emissions");
        require(distributor != address(0), "Invalid distributor address");
        
        uint256 timePassed = block.timestamp - startTime;
        require(timePassed <= EMISSION_PERIOD, "Emission period ended");

        uint256 mintAmount = getNextEmissionAmount();
        require(mintAmount > 0, "No tokens to emit");
        
        uint256 currentSupply = totalSupply();
        
        // Check supply cap
        if (currentSupply + mintAmount > maxSupplyCap) {
            mintAmount = maxSupplyCap - currentSupply;
        }

        if (mintAmount > 0) {
            _mint(distributor, mintAmount);
            emit TokensEmitted(mintAmount, currentSupply + mintAmount, block.timestamp);
        }
        
        lastEmissionTime = block.timestamp;
    }

    /**
     * @dev Emergency function to burn tokens if supply gets too high
     * @param amount Amount of tokens to burn from caller's balance
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Calculate emission amount based on days passed
     * Uses a linear decline rate from INITIAL_DAILY_EMISSION to a minimum over 365 days
     */
    function getNextEmissionAmount() public view returns (uint256) {
        uint256 timePassed = block.timestamp - startTime;
        if (timePassed > EMISSION_PERIOD) {
            return 0;
        }

        uint256 daysPassed = timePassed / 1 days;
        
        // Calculate declining emission rate
        // At day 0: 100% of INITIAL_DAILY_EMISSION
        // At day 365: (100 - BASE_DECLINE_RATE)% of INITIAL_DAILY_EMISSION
        uint256 emissionAmount = INITIAL_DAILY_EMISSION * 
            (RATE_DENOMINATOR - ((daysPassed * BASE_DECLINE_RATE) / 365)) / 
            RATE_DENOMINATOR;

        // Cap at daily limit
        if (emissionAmount > MAX_DAILY_MINT) {
            return MAX_DAILY_MINT;
        }

        return emissionAmount;
    }

    /**
     * @dev Get current emission rate and progress
     */
    function getEmissionStats() external view returns (
        uint256 currentSupply,
        uint256 remainingTime,
        uint256 nextEmission,
        bool isPaused
    ) {
        currentSupply = totalSupply();
        uint256 timePassed = block.timestamp - startTime;
        remainingTime = timePassed >= EMISSION_PERIOD ? 0 : EMISSION_PERIOD - timePassed;
        nextEmission = getNextEmissionAmount();
        isPaused = emissionsPaused;
    }

    /**
     * @dev Calculate compound growth for a specific number of days
     * @param days_ Number of days to calculate growth for
     */
    function calculateGrowthForDays(uint256 days_) external view returns (uint256) {
        require(days_ <= 365, "Cannot calculate beyond emission period");
        
        uint256 totalSupply = INITIAL_SUPPLY;
        for (uint256 i = 0; i < days_; i++) {
            uint256 emission = INITIAL_DAILY_EMISSION * 
                (RATE_DENOMINATOR - ((i * BASE_DECLINE_RATE) / 365)) / 
                RATE_DENOMINATOR;
                
            if (emission > MAX_DAILY_MINT) {
                emission = MAX_DAILY_MINT;
            }
            
            totalSupply += emission;
        }
        return totalSupply;
    }

    /**
     * @dev Schedule a supply cap update through timelock
     * @param newCap New maximum supply cap
     */
    function scheduleSetMaxSupplyCap(uint256 newCap) external onlyOwner {
        require(newCap >= totalSupply(), "Cap cannot be less than current supply");
        
        bytes memory data = abi.encodeWithSelector(
            this.setMaxSupplyCap.selector,
            newCap
        );
        
        TokenTimelock timelock = TokenTimelock(payable(owner()));
        bytes32 actionId = timelock.hashOperation(
            address(this),
            0,
            data,
            bytes32(0),
            bytes32(0)
        );
        
        timelock.schedule(
            address(this),
            0,
            data,
            bytes32(0),
            bytes32(0),
            TIMELOCK_MIN_DELAY
        );
        
        emit ActionScheduled(actionId, block.timestamp + TIMELOCK_MIN_DELAY);
    }

    /**
     * @dev Schedule emissions pause state change through timelock
     * @param pause True to pause, false to unpause
     */
    function scheduleSetEmissionsPaused(bool pause) external onlyOwner {
        bytes memory data = abi.encodeWithSelector(
            this.setEmissionsPaused.selector,
            pause
        );
        
        TokenTimelock timelock = TokenTimelock(payable(owner()));
        bytes32 actionId = timelock.hashOperation(
            address(this),
            0,
            data,
            bytes32(0),
            bytes32(0)
        );
        
        timelock.schedule(
            address(this),
            0,
            data,
            bytes32(0),
            bytes32(0),
            TIMELOCK_MIN_DELAY
        );
        
        emit ActionScheduled(actionId, block.timestamp + TIMELOCK_MIN_DELAY);
    }

    /**
     * @dev Execute a scheduled timelock operation
     */
    function executeTimelockOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external {
        TokenTimelock timelock = TokenTimelock(payable(owner()));
        timelock.execute(target, value, data, predecessor, salt);
    }

    modifier onlyGuardian() {
        if (!guardians[msg.sender]) revert NotGuardian();
        _;
    }

    /**
     * @dev Schedule addition of a new guardian
     * @param guardian Address of the new guardian
     */
    function scheduleAddGuardian(address guardian) external onlyOwner {
        require(guardian != address(0), "Invalid guardian address");
        require(!guardians[guardian], "Already a guardian");
        
        bytes32 operationId = keccak256(
            abi.encodePacked("ADD_GUARDIAN", guardian, block.timestamp)
        );
        
        timelockOperations[operationId] = TimelockOperation({
            scheduledTime: block.timestamp + GUARDIAN_TIMELOCK_DELAY,
            executed: false
        });
        
        emit GuardianChangeScheduled(
            operationId,
            guardian,
            true,
            block.timestamp + GUARDIAN_TIMELOCK_DELAY
        );
    }

    /**
     * @dev Execute scheduled guardian addition with failure handling
     */
    function executeAddGuardian(bytes32 operationId, address guardian) external onlyOwner {
        TimelockOperation storage operation = timelockOperations[operationId];
        
        try this._validateTimelockOperation(operation, "ADD_GUARDIAN", guardian) {
            try this._addGuardian(guardian) {
                operation.executed = true;
                emit GuardianAdded(guardian);
            } catch Error(string memory reason) {
                emit GuardianOperationFailed(
                    operationId,
                    guardian,
                    "ADD_GUARDIAN",
                    reason
                );
            }
        } catch Error(string memory reason) {
            emit GuardianOperationFailed(
                operationId,
                guardian,
                "ADD_GUARDIAN",
                reason
            );
        }
    }

    /**
     * @dev Internal function for adding guardian
     */
    function _addGuardian(address guardian) external {
        require(msg.sender == address(this), "Only internal");
        require(guardian != address(0), "Invalid guardian address");
        require(!guardians[guardian], "Already a guardian");
        
        guardians[guardian] = true;
        guardianList.push(guardian);
    }

    /**
     * @dev Schedule removal of a guardian
     * @param guardian Address of the guardian to remove
     */
    function scheduleRemoveGuardian(address guardian) external onlyOwner {
        require(guardians[guardian], "Not a guardian");
        require(guardianList.length > MIN_GUARDIANS, "Cannot remove guardian below minimum");
        
        bytes32 operationId = keccak256(
            abi.encodePacked("REMOVE_GUARDIAN", guardian, block.timestamp)
        );
        
        timelockOperations[operationId] = TimelockOperation({
            scheduledTime: block.timestamp + GUARDIAN_TIMELOCK_DELAY,
            executed: false
        });
        
        emit GuardianChangeScheduled(
            operationId,
            guardian,
            false,
            block.timestamp + GUARDIAN_TIMELOCK_DELAY
        );
    }

    /**
     * @dev Execute scheduled guardian removal with failure handling
     */
    function executeRemoveGuardian(bytes32 operationId, address guardian) external onlyOwner {
        TimelockOperation storage operation = timelockOperations[operationId];
        
        try this._validateTimelockOperation(operation, "REMOVE_GUARDIAN", guardian) {
            try this._removeGuardian(guardian) {
                operation.executed = true;
                emit GuardianRemoved(guardian);
            } catch Error(string memory reason) {
                emit GuardianOperationFailed(
                    operationId,
                    guardian,
                    "REMOVE_GUARDIAN",
                    reason
                );
            }
        } catch Error(string memory reason) {
            emit GuardianOperationFailed(
                operationId,
                guardian,
                "REMOVE_GUARDIAN",
                reason
            );
        }
    }

    /**
     * @dev Internal function for removing guardian
     */
    function _removeGuardian(address guardian) external {
        require(msg.sender == address(this), "Only internal");
        require(guardians[guardian], "Not a guardian");
        require(guardianList.length > MIN_GUARDIANS, "Cannot remove guardian below minimum");
        
        guardians[guardian] = false;
        for (uint i = 0; i < guardianList.length; i++) {
            if (guardianList[i] == guardian) {
                guardianList[i] = guardianList[guardianList.length - 1];
                guardianList.pop();
                break;
            }
        }
    }

    /**
     * @dev Internal function to validate timelock operations
     * @param operation The timelock operation to validate
     * @param operationType The type of operation being validated
     * @param guardian The guardian address involved in the operation
     */
    function _validateTimelockOperation(
        TimelockOperation memory operation,
        string memory operationType,
        address guardian
    ) external view {
        bytes32 expectedOperationId = keccak256(
            abi.encodePacked(operationType, guardian, operation.scheduledTime - GUARDIAN_TIMELOCK_DELAY)
        );
        
        if (operation.scheduledTime == 0) revert OperationNotScheduled();
        if (operation.executed) revert OperationAlreadyExecuted();
        if (block.timestamp < operation.scheduledTime) revert TimelockNotReady();
        
        // Verify operation matches expected parameters
        require(
            keccak256(abi.encodePacked(operationType, guardian, operation.scheduledTime - GUARDIAN_TIMELOCK_DELAY)) == expectedOperationId,
            "Invalid operation parameters"
        );
    }

    /**
     * @dev Propose an emergency pause of all token operations
     */
    function proposeEmergencyPause() external onlyGuardian {
        require(!paused(), "Already paused");
        bytes32 actionId = keccak256(abi.encodePacked("PAUSE", block.timestamp));
        _initializeEmergencyAction(actionId);
        emit EmergencyActionProposed(actionId, "PAUSE");
    }

    /**
     * @dev Propose an emergency unpause of token operations
     */
    function proposeEmergencyUnpause() external onlyGuardian {
        require(paused(), "Not paused");
        bytes32 actionId = keccak256(abi.encodePacked("UNPAUSE", block.timestamp));
        _initializeEmergencyAction(actionId);
        emit EmergencyActionProposed(actionId, "UNPAUSE");
    }

    /**
     * @dev Propose an emergency burn of tokens from a specific address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function proposeEmergencyBurn(address from, uint256 amount) external onlyGuardian {
        bytes32 actionId = keccak256(abi.encodePacked("BURN", from, amount, block.timestamp));
        _initializeEmergencyAction(actionId);
        emit EmergencyActionProposed(actionId, "BURN");
    }

    /**
     * @dev Approve an emergency action
     * @param actionId ID of the action to approve
     */
    function approveEmergencyAction(bytes32 actionId) external onlyGuardian {
        EmergencyAction storage action = emergencyActions[actionId];
        require(action.proposedTime != 0, "Action does not exist");
        require(!action.executed, "Action already executed");
        require(block.timestamp <= action.proposedTime + EMERGENCY_ACTION_TIMEOUT, "Action expired");
        
        if (action.hasApproved[msg.sender]) revert AlreadyApproved();
        
        action.hasApproved[msg.sender] = true;
        action.approvals += 1;
        
        emit EmergencyActionApproved(actionId, msg.sender);
    }

    /**
     * @dev Execute an emergency pause action with failure handling
     */
    function executeEmergencyPause(bytes32 actionId) external onlyGuardian {
        // First validate the action - will revert if invalid
        (bool validationSuccess, string memory validationError) = _validateEmergencyActionWithError(actionId);
        if (!validationSuccess) {
            emit EmergencyActionFailed(actionId, "PAUSE", validationError);
            return;
        }
        
        // Attempt to pause
        bool success = _attemptPause();
        
        if (success) {
            _markActionExecuted(actionId);
        } else {
            emit EmergencyActionFailed(actionId, "PAUSE", "Pause operation failed. The token is already paused.");
        }
    }

    /**
     * @dev Internal function to attempt pause operation
     * @return success Whether the pause operation succeeded
     */
    function _attemptPause() private returns (bool) {
        if (paused()) {
            return false;
        }
        _pause();
        return true;
    }
    /**
     * @dev Internal function to attempt pause operation
     * @return success Whether the unpause operation succeeded
     */
    function _attemptUnpause() private returns (bool) {
        if (!paused()) {
            return false;
        }
        _unpause();
        return true;
    }

    /**
     * @dev Execute an emergency unpause action with failure handling
     */
    function executeEmergencyUnpause(bytes32 actionId) external onlyGuardian {
       // Validate the action and capture any error
        (bool validationSuccess, string memory validationError) = _validateEmergencyActionWithError(actionId);
        if (!validationSuccess) {
            emit EmergencyActionFailed(actionId, "UNPAUSE", validationError);
            return;
        }
            
        // Attempt to unpause
        bool success = _attemptUnpause();
        
        if (success) {
            _markActionExecuted(actionId);
        } else {
            emit EmergencyActionFailed(
                actionId,
                "UNPAUSE",
                "Unpause operation failed. The token is already unpaused."
            );
        }
    }

    /**
     * @dev Execute an emergency burn action with failure handling
     */
    // function executeEmergencyBurn(
    //     bytes32 actionId,
    //     address from,
    //     uint256 amount
    // ) external onlyGuardian {
    //     (bool validationSuccess, string memory validationError) = _validateEmergencyActionWithError(actionId);
    //     if (!validationSuccess) {
    //         emit EmergencyActionFailed(actionId, "BURN", validationError);
    //         return;
    //     }

    //     // Attempt to burn tokens
    //     bool success = _burn(from, amount);
        
    //     if (success) {
    //         emit EmergencyTokensBurned(from, amount);
    //         _markActionExecuted(actionId);
    //     } else {
    //         emit EmergencyActionFailed(
    //             actionId,
    //             "BURN",
    //             "Burn operation failed"
    //         );
    //     }
    // }

    /**
     * @dev Emergency withdrawal of stuck tokens
     * @param token Address of the token to withdraw (zero address for ETH)
     * @param to Address to send the tokens to
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyGuardian {
        bytes32 actionId = keccak256(abi.encodePacked("WITHDRAW", token, to, amount, block.timestamp));
        (bool validationSuccess, string memory validationError) = _validateEmergencyActionWithError(actionId);
        
        if (!validationSuccess) {
            emit EmergencyActionFailed(actionId, "WITHDRAW", validationError);
            return;
        }
        
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20Upgradeable(token).transfer(to, amount);
        }
        
        emit EmergencyWithdrawal(token, to, amount);
        _markActionExecuted(actionId);
    }

    // Internal helper functions
    function _initializeEmergencyAction(bytes32 actionId) internal {
        require(block.timestamp >= lastEmergencyAction + EMERGENCY_COOLDOWN, "Emergency cooldown not passed");
        EmergencyAction storage action = emergencyActions[actionId];
        action.proposedTime = block.timestamp;
        action.approvals = 1;
        action.hasApproved[msg.sender] = true;
    }

    /**
     * @dev Internal function to validate emergency action with error handling
     * @return success Whether the validation succeeded
     * @return errorMessage Error message if validation failed
     */
    function _validateEmergencyActionWithError(bytes32 actionId) internal view returns (bool, string memory) {
        EmergencyAction storage action = emergencyActions[actionId];
        
        if (action.proposedTime == 0) return (false, "Action does not exist");
        if (action.executed) return (false, "Action already executed");
        if (block.timestamp > action.proposedTime + EMERGENCY_ACTION_TIMEOUT) return (false, "Action expired");
        if (action.approvals < MIN_GUARDIANS) return (false, "Insufficient approvals");
        
        return (true, "");
    }

    function _markActionExecuted(bytes32 actionId) internal {
        EmergencyAction storage action = emergencyActions[actionId];
        action.executed = true;
        lastEmergencyAction = block.timestamp;
        emit EmergencyActionExecuted(actionId);
    }

    // Override transfer functions to check for pause status
    function transfer(address to, uint256 amount) public override whenNotPaused notBlacklisted(msg.sender) 
    notBlacklisted(to) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused notBlacklisted(msg.sender) 
    notBlacklisted(to) returns (bool) {
        return super.transferFrom(from, to, amount);
    }
    
    function approve(address spender, uint256 amount) public override whenNotPaused 
    notBlacklisted(msg.sender) 
    notBlacklisted(spender) 
    returns (bool) {
        return super.approve(spender, amount);
    }
    /**
     * @dev Cancel a scheduled timelock operation
     */
    function cancelTimelockOperation(
        bytes32 operationId,
        address guardian,
        string memory operationType
    ) external onlyOwner {
        TimelockOperation storage operation = timelockOperations[operationId];
        require(operation.scheduledTime != 0, "Operation does not exist");
        require(!operation.executed, "Operation already executed");
        
        delete timelockOperations[operationId];
        
        emit TimelockOperationCancelled(
            operationId,
            guardian,
            operationType
        );
    }
}
