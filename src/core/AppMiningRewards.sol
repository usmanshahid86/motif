// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IAppMetrics.sol";
import "../interfaces/IBitDSMRegistry.sol";
import "../interfaces/IBitcoinPodManager.sol";

contract AppMiningRewards is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IBitDSMRegistry public registry;
    IBitcoinPodManager public podManager;
    IERC20 public rewardsToken;
    
    // Weights for different metrics (total should be 10000)
    struct RewardWeights {
        uint16 tvlWeight;          // 4000 (40%)
        uint16 userWeight;         // 3000 (30%)
        uint16 transactionWeight;  // 2000 (20%)
        uint16 retentionWeight;    // 1000 (10%)
    }
    
    RewardWeights public weights;
    uint256 public epochDuration;  // Duration in blocks
    uint256 public currentEpoch;
    uint256 public rewardsPerEpoch;
    
    mapping(address => IAppMetrics.MetricsData) private appMetrics;
    mapping(address => uint256) public lastClaimedEpoch;
    
    event RewardsClaimed(address indexed app, uint256 amount, uint256 epoch);
    
    function initialize(
        address _registry,
        address _podManager,
        address _rewardsToken
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        registry = IBitDSMRegistry(_registry);
        podManager = IBitcoinPodManager(_podManager);
        rewardsToken = IERC20(_rewardsToken);
        
        weights = RewardWeights({
            tvlWeight: 4000,
            userWeight: 3000,
            transactionWeight: 2000,
            retentionWeight: 1000
        });
        
        epochDuration = 50400; // ~1 week in blocks
        rewardsPerEpoch = 1000000 * 1e18; // 1M tokens per epoch
    }
    
    function calculateRewards(address app) public view returns (uint256) {
        IAppMetrics.MetricsData memory metrics = appMetrics[app];
        require(metrics.isActive, "App not active");
        
        uint256 score;
        score += (metrics.tvl * weights.tvlWeight);
        score += (metrics.uniqueUsers * weights.userWeight);
        score += (metrics.transactionCount * weights.transactionWeight);
        score += (metrics.retentionScore * weights.retentionWeight);
        
        // Calculate share of rewards based on total ecosystem score
        return (score * rewardsPerEpoch) / getTotalEcosystemScore();
    }
    
    function claimRewards() external nonReentrant {
        require(registry.isAppRegistered(msg.sender), "App not registered");
        require(block.number >= lastClaimedEpoch[msg.sender] + epochDuration, "Too early");
        
        uint256 rewards = calculateRewards(msg.sender);
        lastClaimedEpoch[msg.sender] = block.number;
        
        require(rewardsToken.transfer(msg.sender, rewards), "Transfer failed");
        emit RewardsClaimed(msg.sender, rewards, currentEpoch);
    }
    
    function updateAppMetrics(address app, IAppMetrics.MetricsData memory newMetrics) 
        external 
        onlyOwner 
    {
        require(registry.isAppRegistered(app), "App not registered");
        appMetrics[app] = newMetrics;
        
        emit MetricsUpdated(
            app,
            newMetrics.tvl,
            newMetrics.uniqueUsers,
            newMetrics.transactionCount,
            newMetrics.retentionScore
        );
    }
}
