// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IAppRegistry.sol";
import "@eigenlayer/src/contracts/interfaces/IRewardsCoordinator.sol";
import "../interfaces/IBitcoinPodManager.sol";
import "@eigenlayer/src/contracts/interfaces/IStrategyManager.sol";
import "../interfaces/IBitcoinPod.sol";

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
    mapping(address => uint256) public lastStakeAmount;
    
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
    
    event AppRewardDistributed(address indexed app, uint256 amount);
    event TVLRewardDistributed(address indexed pod, address indexed owner, uint256 amount);
    
    function initialize(
        address _token,
        address _appRegistry,
        address _eigenLayerRewards,
        address _podManager
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        token = IToken(_token);
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
            if (appRegistry.isAppRegistered(apps[i])) {
                token.transfer(apps[i], perAppAmount);
                emit AppRewardDistributed(apps[i], perAppAmount);
            }
        }
    }
    
    function _distributeOperatorRewards(uint256 amount) internal {
        // Create EigenLayer rewards submission
        IRewardsCoordinator.RewardsSubmission[] memory submissions = new IRewardsCoordinator.RewardsSubmission[](1);
        
        // Convert your StrategyAndMultiplier to IRewardsCoordinator.StrategyAndMultiplier
        IRewardsCoordinator.StrategyAndMultiplier[] memory strategyAndMultipliers = _getEligibleStrategies();
        
        submissions[0] = IRewardsCoordinator.RewardsSubmission({
            strategiesAndMultipliers: strategyAndMultipliers,
            token: IERC20(address(token)),  // Cast your token to IERC20
            amount: amount,
            startTimestamp: uint32(block.timestamp - 1 days),
            duration: uint32(1 days)
        });
        
        token.approve(address(eigenLayerRewards), amount);
        eigenLayerRewards.createAVSRewardsSubmission(submissions);
    }
    
    function _distributeTVLRewards(uint256 amount) internal {
        address[] memory pods = podManager.getActivePods();
        uint256 totalViableBtc = _getViableTotalBTC();
        
        if (totalViableBtc == 0) return;

        for(uint i = 0; i < pods.length; i++) {
            address pod = pods[i];
            uint256 viablePodBtc = _getViablePodBTC(pod);
            
            if (viablePodBtc > 0) {
                uint256 podShare = (amount * viablePodBtc) / totalViableBtc;
                if (podShare > 0) {
                    // Transfer rewards to the pod owner
                    address podOwner = IBitcoinPod(pod).getOwner();
                    token.transfer(podOwner, podShare);
                    emit TVLRewardDistributed(pod, podOwner, podShare);
                }
            }
        }
    }
    
    function _getViableTotalBTC() internal view returns (uint256) {
        uint256 total = podManager.getTotalTVL();
        // For TVL rewards, we'll count all BTC since it's already tracked in the pod manager
        return total;
    }
    
    function _getViablePodBTC(address pod) internal view returns (uint256) {
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        uint256 podBtc = bitcoinPod.getBitcoinBalance();
        return podBtc;
    }
    
    function _getEligibleStrategies() internal view returns (IRewardsCoordinator.StrategyAndMultiplier[] memory) {
        // Implementation for getting EigenLayer strategies
        // This would return the list of strategies eligible for rewards
    }
    
    function updateStake(address staker, uint256 newAmount) external {
        // Track when stake changes
        stakeDeltaSinceLastEmission[staker][address(this)] = 
            int256(newAmount) - int256(lastStakeAmount[staker]);
        lastStakeAmount[staker] = newAmount;
        lastStakeUpdate[staker] = block.number;
    }
    
    function _getViableStake(address staker) internal view returns (uint256) {
        uint256 currentStake = lastStakeAmount[staker];
        // Only count stake that's been there since last distribution
        if (lastStakeUpdate[staker] > lastEmissionBlock[address(this)]) {
            return currentStake - uint256(stakeDeltaSinceLastEmission[staker][address(this)]);
        }
        return currentStake;
    }
}