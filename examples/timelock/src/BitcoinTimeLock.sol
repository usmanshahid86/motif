    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.12;

    import "@openzeppelin/contracts/access/Ownable.sol";
    import "../../../src/interfaces/IBitcoinPod.sol";
    import "../../../src/interfaces/IBitcoinPodManager.sol";

    contract BitcoinTimelockApp is Ownable {
        IBitcoinPodManager public podManager;
        
        // Mapping of pod address to unlock timestamp
        mapping(address => uint256) public podUnlockTimes;
        
        event PodLocked(address indexed pod, uint256 unlockTime);
        event PodUnlocked(address indexed pod);

        constructor(address _podManager) {
            podManager = IBitcoinPodManager(_podManager);
        }

        function lockPodUntil(address pod, uint256 unlockTime) external {
            require(unlockTime > block.timestamp, "Unlock time must be in future");
            require(msg.sender == IBitcoinPod(pod).owner(), "Not pod owner");
            
            // Lock the pod through pod manager
            podManager.lockPod(pod);
            
            // Store unlock time
            podUnlockTimes[pod] = unlockTime;
            
            emit PodLocked(pod, unlockTime);
        }

        function unlockPod(address pod) external {
            require(block.timestamp >= podUnlockTimes[pod], "Time lock not expired");
            require(msg.sender == IBitcoinPod(pod).owner(), "Not pod owner");
            
            podManager.unlockPod(pod);
            delete podUnlockTimes[pod];
            
            emit PodUnlocked(pod);
        }
    }
