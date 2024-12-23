// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IRewardsCoordinator.sol";

contract RewardsSubmitter is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice BitDSM token contract
    IToken public token;
    
    /// @notice EigenLayer's RewardsCoordinator contract
    IRewardsCoordinator public rewardsCoordinator;
    
    /// @notice Address where non-operator rewards are sent
    address public treasury;
    
    /// @notice Percentage of emissions that go to operators (in basis points, e.g. 7000 = 70%)
    uint16 public operatorRewardsBips;
    
    /// @notice Minimum time between reward submissions
    uint256 public constant MIN_SUBMISSION_INTERVAL = 1 days;
    
    /// @notice Last time rewards were submitted
    uint256 public lastSubmissionTime;

    event RewardsSubmitted(uint256 operatorAmount, uint256 treasuryAmount);
    event TreasuryUpdated(address oldTreasury, address newTreasury);
    event OperatorRewardsBipsUpdated(uint16 oldBips, uint16 newBips);

    error InvalidAddress();
    error InvalidBips();
    error TooEarlyToSubmit();

    function initialize(
        address _token,
        address _rewardsCoordinator,
        address _treasury,
        uint16 _operatorRewardsBips
    ) external initializer {
        if (_token == address(0) || _rewardsCoordinator == address(0) || _treasury == address(0)) 
            revert InvalidAddress();
        if (_operatorRewardsBips > 10000) revert InvalidBips();

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IToken(_token);
        rewardsCoordinator = IRewardsCoordinator(_rewardsCoordinator);
        treasury = _treasury;
        operatorRewardsBips = _operatorRewardsBips;
    }

    /**
     * @notice Triggers token emission and submits rewards
     * @dev Can only be called once per MIN_SUBMISSION_INTERVAL
     */
    function submitEmissionRewards() external nonReentrant whenNotPaused {
        if (block.timestamp < lastSubmissionTime + MIN_SUBMISSION_INTERVAL) 
            revert TooEarlyToSubmit();

        // Emit new tokens to this contract
        (uint256 emittedAmount,) = token.emitNewTokens(address(this));
        
        if (emittedAmount > 0) {
            // Calculate split
            uint256 operatorAmount = (emittedAmount * operatorRewardsBips) / 10000;
            uint256 treasuryAmount = emittedAmount - operatorAmount;
            
            // Transfer treasury portion
            token.transfer(treasury, treasuryAmount);
            
            // Approve rewards coordinator to spend operator portion
            token.approve(address(rewardsCoordinator), operatorAmount);
            
            // Create rewards submission
            IRewardsCoordinator.RewardsSubmission[] memory submissions = new IRewardsCoordinator.RewardsSubmission[](1);
            submissions[0] = IRewardsCoordinator.RewardsSubmission({
                token: IERC20(address(token)),
                amount: operatorAmount,
                startTimestamp: uint32(lastSubmissionTime),
                duration: uint32(MIN_SUBMISSION_INTERVAL),
                strategiesAndMultipliers: _getStrategiesAndMultipliers()
            });
            
            // Submit to RewardsCoordinator
            rewardsCoordinator.createAVSRewardsSubmission(submissions);
            
            emit RewardsSubmitted(operatorAmount, treasuryAmount);
        }
        
        lastSubmissionTime = block.timestamp;
    }

    /**
     * @notice Updates the treasury address
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert InvalidAddress();
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @notice Updates operator rewards percentage
     * @param _operatorRewardsBips New percentage in basis points
     */
    function setOperatorRewardsBips(uint16 _operatorRewardsBips) external onlyOwner {
        if (_operatorRewardsBips > 10000) revert InvalidBips();
        uint16 oldBips = operatorRewardsBips;
        operatorRewardsBips = _operatorRewardsBips;
        emit OperatorRewardsBipsUpdated(oldBips, _operatorRewardsBips);
    }

    /**
     * @dev Returns the strategies and their multipliers for rewards
     * Override this function to implement custom strategy weights
     */
    function _getStrategiesAndMultipliers() internal view virtual returns (
        IRewardsCoordinator.StrategyAndMultiplier[] memory
    ) {
        IRewardsCoordinator.StrategyAndMultiplier[] memory strategies = 
            new IRewardsCoordinator.StrategyAndMultiplier[](1);
        
        // Example: single strategy with 1x multiplier
        strategies[0] = IRewardsCoordinator.StrategyAndMultiplier({
            strategy: IStrategy(address(token)),
            multiplier: 1
        });
        
        return strategies;
    }
}