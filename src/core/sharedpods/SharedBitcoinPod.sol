// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title SharedBitcoinPod
 * @notice Example implementation of a Bitcoin pod that can be shared among multiple apps
 * @dev This is a demonstration contract showing how pod sharing could work
 */
contract SharedBitcoinPod {
    using SafeMathUpgradeable for uint256;

    // Constants
    uint256 public constant TOTAL_SHARES = 100;
    
    // Core pod data (similar to original BitcoinPod)
    address public operator;
    bytes public operatorBtcPubKey;
    bytes public bitcoinAddress;
    uint256 public bitcoinBalance;
    bool public locked;
    address public immutable manager;

    // Sharing mechanism
    struct AppShare {
        uint256 shares;      // Number of shares allocated
        uint256 lastRewardBlock; // Last block when rewards were claimed
    }
    
    mapping(address => AppShare) public appShares;
    address[] public registeredApps;
    uint256 public totalAllocatedShares;
    
    // Events
    event SharesAllocated(address app, uint256 shares);
    event SharesRemoved(address app, uint256 shares);
    event RewardsClaimed(address app, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner(), "Not owner");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor(address _manager) {
        manager = _manager;
    }

    /**
     * @notice Allocate shares to an app
     * @param app The app address
     * @param shares Number of shares to allocate
     */
    function allocateShares(address app, uint256 shares) external onlyOwner {
        require(shares > 0, "Shares must be > 0");
        require(totalAllocatedShares + shares <= TOTAL_SHARES, "Exceeds total shares");
        
        if (appShares[app].shares == 0) {
            registeredApps.push(app);
        }
        
        appShares[app].shares += shares;
        totalAllocatedShares += shares;
        
        emit SharesAllocated(app, shares);
    }

    /**
     * @notice Remove shares from an app
     * @param app The app address
     * @param shares Number of shares to remove
     */
    function removeShares(address app, uint256 shares) external onlyOwner {
        require(appShares[app].shares >= shares, "Insufficient shares");
        
        appShares[app].shares -= shares;
        totalAllocatedShares -= shares;
        
        if (appShares[app].shares == 0) {
            _removeApp(app);
        }
        
        emit SharesRemoved(app, shares);
    }

    /**
     * @notice Calculate rewards for an app based on their shares
     * @param app The app address
     * @return Reward amount for the period
     */
    function calculateRewards(address app) public view returns (uint256) {
        AppShare storage appShare = appShares[app];
        if (appShare.shares == 0) return 0;
        
        uint256 blocksSinceLastReward = block.number - appShare.lastRewardBlock;
        return bitcoinBalance
            .mul(blocksSinceLastReward)
            .mul(appShare.shares)
            .div(TOTAL_SHARES);
    }

    // Internal helper functions
    function _removeApp(address app) internal {
        for (uint i = 0; i < registeredApps.length; i++) {
            if (registeredApps[i] == app) {
                registeredApps[i] = registeredApps[registeredApps.length - 1];
                registeredApps.pop();
                break;
            }
        }
    }
}