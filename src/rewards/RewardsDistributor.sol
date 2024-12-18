// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IToken.sol";

contract RewardsDistributor is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IToken public token;
    IAppRegistry public appRegistry;
    IRewardsCoordinator public eigenLayerRewards;
    IBitcoinPodManager public podManager;
    
    // Distribution percentages
    uint256 public constant APP_SHARE = 30;
    uint256 public constant OPERATOR_SHARE = 40;
    uint256 public constant TVL_SHARE = 30;
    
    // Add tempo and epoch tracking
    uint256 public emissionTempo;
    mapping(address => uint256) public lastEmissionBlock;
    mapping(address => uint256) public accumulatedEmissions;
    
    // Track stake changes
    mapping(address => mapping(address => int256)) public stakeDeltaSinceLastEmission;
    
    // Configuration
    uint256 public minimumDistributionAmount = 100e18; // Minimum amount to trigger distribution
    
    // Tracking
    mapping(address => uint256) public lastStakeUpdate;
    
    event EmissionsDistributed(
        uint256 totalAmount,
        uint256 appAmount,
        uint256 operatorAmount,
        uint256 tvlAmount
    );
    
    event TVLRewardDistributed(
        address pod,
        uint256 amount
    );
    
    function initialize(
        address _token,
        address _appRegistry,
        address _eigenLayerRewards,
        address _podManager
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        token = IBitDSMToken(_token);
        appRegistry = IAppRegistry(_appRegistry);
        eigenLayerRewards = IRewardsCoordinator(_eigenLayerRewards);
        podManager = IBitcoinPodManager(_podManager);
    }
    
    function distributeEmissions(uint256 amount) external nonReentrant {
        require(msg.sender == address(token), "Only token");
        
        // 1. Accumulate first
        accumulatedEmissions[address(this)] += amount;
        
        // 2. Only distribute if tempo met AND minimum amount reached
        if (_shouldDistribute() && 
            accumulatedEmissions[address(this)] >= minimumDistributionAmount) {
            _performDistribution();
        }
    }
    
    function _shouldDistribute() internal view returns (bool) {
        return block.number >= lastEmissionBlock[address(this)] + emissionTempo;
    }
    
    function _performDistribution() internal {
        uint256 totalAccumulated = _drainAccumulatedEmissions();
        
        // Calculate shares of accumulated amount
        uint256 appAmount = (totalAccumulated * APP_SHARE) / 100;
        uint256 operatorAmount = (totalAccumulated * OPERATOR_SHARE) / 100;
        uint256 tvlAmount = (totalAccumulated * TVL_SHARE) / 100;
        
        // Distribute accumulated amounts
        _distributeAppRewards(appAmount);
        _distributeOperatorRewards(operatorAmount);
        _distributeTVLRewards(tvlAmount);
    }
    
    function _drainAccumulatedEmissions() internal returns (uint256) {
        uint256 amount = accumulatedEmissions[address(this)];
        accumulatedEmissions[address(this)] = 0;
        lastEmissionBlock[address(this)] = block.number;
        return amount;
    }
    
    function _distributeAppRewards(uint256 amount) internal {
        address[] memory apps = appRegistry.getRegisteredApps();
        if (apps.length == 0) return;
        
        uint256 perAppAmount = amount / apps.length;
        for(uint i = 0; i < apps.length; i++) {
            token.transfer(apps[i], perAppAmount);
        }
    }
    
    function _distributeOperatorRewards(uint256 amount) internal {
        // Create EigenLayer rewards submission
        RewardsSubmission[] memory submissions = new RewardsSubmission[](1);
        submissions[0] = RewardsSubmission({
            token: token,
            amount: amount,
            startTimestamp: uint32(block.timestamp - 1 days),
            duration: 1 days,
            strategiesAndMultipliers: _getEligibleStrategies()
        });
        
        token.approve(address(eigenLayerRewards), amount);
        eigenLayerRewards.createAVSRewardsSubmission(submissions);
    }
    
    function _distributeTVLRewards(uint256 amount) internal {
        address[] memory pods = podManager.getActivePods();
        uint256 totalViableBtc = _getViableTotalBTC();
        
        for(uint i = 0; i < pods.length; i++) {
            address pod = pods[i];
            uint256 viablePodBtc = _getViablePodBTC(pod);
            uint256 podShare = (amount * viablePodBtc) / totalViableBtc;
            
            if (podShare > 0) {
                token.transfer(pod, podShare);
                emit TVLRewardDistributed(pod, podShare);
            }
        }
    }
    
    function _getViableTotalBTC() internal view returns (uint256) {
        uint256 total = podManager.getTotalLockedBTC();
        // Subtract any BTC added since last emission
        return total - _getNonViableBTC();
    }
    
    function _getViablePodBTC(address pod) internal view returns (uint256) {
        uint256 podBtc = IBitcoinPod(pod).bitcoinBalance();
        int256 stakeDelta = stakeDeltaSinceLastEmission[pod][address(this)];
        // Only subtract positive stake changes
        if (stakeDelta > 0) {
            podBtc -= uint256(stakeDelta);
        }
        return podBtc;
    }
    
    function _getEligibleStrategies() internal view returns (StrategyAndMultiplier[] memory) {
        // Implementation for getting EigenLayer strategies
        // This would return the list of strategies eligible for rewards
    }
    
    function updateStake(address staker, uint256 newAmount) external {
        // Track when stake changes
        stakeDeltaSinceLastEmission[staker][address(this)] = 
            int256(newAmount) - int256(previousAmount);
        lastStakeUpdate[staker] = block.number;
    }
    
    function _getViableStake(address staker) internal view returns (uint256) {
        uint256 currentStake = getStake(staker);
        // Only count stake that's been there since last distribution
        if (lastStakeUpdate[staker] > lastEmissionBlock[address(this)]) {
            return currentStake - uint256(stakeDeltaSinceLastEmission[staker][address(this)]);
        }
        return currentStake;
    }
} 
} 