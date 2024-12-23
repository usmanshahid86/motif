// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./SharedBitcoinPod.sol";

/**
 * @title SharedBitcoinPodManager
 * @notice Example implementation of a manager for shared Bitcoin pods
 * @dev This demonstrates how pods could be shared among multiple apps
 */
contract SharedBitcoinPodManager is Initializable, OwnableUpgradeable {
    
    // Registry references
    address public appRegistry;
    
    // Pod tracking
    mapping(address => address) public userToPod;
    mapping(address => mapping(address => uint256)) public podToAppShares;
    
    // Events
    event SharedPodCreated(address owner, address pod, address operator);
    event SharesAllocated(address pod, address app, uint256 shares);
    event SharesRemoved(address pod, address app, uint256 shares);

    function initialize(address _appRegistry) external initializer {
        __Ownable_init();
        appRegistry = _appRegistry;
    }

    /**
     * @notice Create a new shared pod
     * @param operator The pod operator
     * @param btcAddress The Bitcoin address
     * @param initialApps Initial app allocations
     * @param initialShares Shares for each initial app
     */
    function createSharedPod(
        address operator,
        bytes memory btcAddress,
        address[] memory initialApps,
        uint256[] memory initialShares
    ) external returns (address) {
        require(initialApps.length == initialShares.length, "Arrays length mismatch");
        require(userToPod[msg.sender] == address(0), "User already has a pod");

        // Create new shared pod
        SharedBitcoinPod newPod = new SharedBitcoinPod(address(this));
        userToPod[msg.sender] = address(newPod);

        // Allocate initial shares
        uint256 totalShares = 0;
        for (uint i = 0; i < initialApps.length; i++) {
            require(_isAppRegistered(initialApps[i]), "App not registered");
            newPod.allocateShares(initialApps[i], initialShares[i]);
            totalShares += initialShares[i];
        }
        require(totalShares <= 100, "Total shares exceeds 100");

        emit SharedPodCreated(msg.sender, address(newPod), operator);
        return address(newPod);
    }

    /**
     * @notice Modify app shares in a pod
     * @param pod The pod address
     * @param app The app address
     * @param newShares New share amount
     */
    function modifyShares(address pod, address app, uint256 newShares) external {
        require(msg.sender == SharedBitcoinPod(pod).owner(), "Not pod owner");
        require(_isAppRegistered(app), "App not registered");
        
        uint256 currentShares = SharedBitcoinPod(pod).appShares(app).shares;
        
        if (newShares > currentShares) {
            SharedBitcoinPod(pod).allocateShares(app, newShares - currentShares);
            emit SharesAllocated(pod, app, newShares - currentShares);
        } else if (newShares < currentShares) {
            SharedBitcoinPod(pod).removeShares(app, currentShares - newShares);
            emit SharesRemoved(pod, app, currentShares - newShares);
        }
    }

    // Internal helper functions
    function _isAppRegistered(address app) internal view returns (bool) {
        return IAppRegistry(appRegistry).isAppRegistered(app);
    }
}