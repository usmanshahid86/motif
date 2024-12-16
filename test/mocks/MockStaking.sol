// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MockStaking is ReentrancyGuard {
    IERC20 public immutable token;
    
    // Staking data structures
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTime;
    uint256 public totalStaked;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    // Errors
    error InsufficientBalance();
    error NoStakeFound();
    error StakingLocked();
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    // Stake tokens
    function stake(uint256 amount) external nonReentrant {
        if (amount == 0 || token.balanceOf(msg.sender) < amount) {
            revert InsufficientBalance();
        }
        
        // Transfer tokens to contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update staking data
        stakedBalance[msg.sender] += amount;
        stakingTime[msg.sender] = block.timestamp;
        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    // Withdraw staked tokens
    function withdraw(uint256 amount) external nonReentrant {
        if (stakedBalance[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        
        // Update staking data
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        
        // Transfer tokens back to user
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    // Mock reward calculation (for testing)
    function calculateRewards(address user) public view returns (uint256) {
        if (stakedBalance[user] == 0) {
            return 0;
        }
        
        // Simple reward calculation: 1% per day of staked amount
        uint256 stakingDuration = block.timestamp - stakingTime[user];
        uint256 daysStaked = stakingDuration / 1 days;
        return (stakedBalance[user] * daysStaked) / 100;
    }
    
    // Claim rewards
    function claimRewards() external nonReentrant {
        uint256 rewards = calculateRewards(msg.sender);
        if (rewards == 0) {
            revert NoStakeFound();
        }
        
        // Reset staking time for new reward period
        stakingTime[msg.sender] = block.timestamp;
        
        // Transfer rewards
        require(token.transfer(msg.sender, rewards), "Transfer failed");
        
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    // View functions
    function getStakeInfo(address user) external view returns (
        uint256 staked,
        uint256 stakingTimestamp,
        uint256 pendingRewards
    ) {
        return (
            stakedBalance[user],
            stakingTime[user],
            calculateRewards(user)
        );
    }
    
    // Emergency withdraw function (for testing)
    function emergencyWithdraw() external {
        uint256 amount = stakedBalance[msg.sender];
        if (amount == 0) {
            revert NoStakeFound();
        }
        
        // Reset user data
        stakedBalance[msg.sender] = 0;
        totalStaked -= amount;
        
        // Transfer tokens back to user
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
} 