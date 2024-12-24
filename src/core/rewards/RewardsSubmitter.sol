// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IRewardsCoordinator.sol";
import "./DAOContract.sol";

contract RewardSubmitter is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    IToken public token;                          // BitDSM token contract
    IRewardsCoordinator public rewardsCoordinator; // EigenLayer's RewardsCoordinator contract
    DAOContract public daoContract;               // DAO contract for split and AVS weights

    uint256 public constant MIN_SUBMISSION_INTERVAL = 1 days; // Minimum time between submissions
    uint256 public lastSubmissionTime;                       // Timestamp of last submission

    event RewardsSubmitted(uint256 operatorAmount, uint256 totalAVSAmount);
    event DAOContractUpdated(address oldDAOContract, address newDAOContract);

    error TooEarlyToSubmit();
    error InvalidAddress();
    error ZeroWeight();

    function initialize(
        address _token,
        address _rewardsCoordinator,
        address _daoContract
    ) external initializer {
        require(_token != address(0), "Invalid token address");
        require(_rewardsCoordinator != address(0), "Invalid rewards coordinator address");
        require(_daoContract != address(0), "Invalid DAO contract address");

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        token = IToken(_token);
        rewardsCoordinator = IRewardsCoordinator(_rewardsCoordinator);
        daoContract = DAOContract(_daoContract);
    }

    /**
     * @notice Submits token emissions and distributes rewards to operators and AVSs
     */
    function submitEmissionRewards() external nonReentrant whenNotPaused {
        if (block.timestamp < lastSubmissionTime + MIN_SUBMISSION_INTERVAL) {
            revert TooEarlyToSubmit();
        }

        // Emit new tokens to this contract
        (uint256 emittedAmount,) = token.emitNewTokens(address(this));

        if (emittedAmount > 0) {
            // Fetch splits from DAO contract
            uint16 operatorSplitBips = daoContract.operatorSplitBips();
            uint16 avsSplitBips = daoContract.avsSplitBips();

            // Calculate amounts
            uint256 operatorAmount = (emittedAmount * operatorSplitBips) / 10000;
            uint256 totalAVSAmount = emittedAmount - operatorAmount;

            // Distribute operator rewards
            token.approve(address(rewardsCoordinator), operatorAmount);
            IRewardsCoordinator.RewardsSubmission;
            operatorRewards[0] = IRewardsCoordinator.RewardsSubmission({
                token: IERC20(address(token)),
                amount: operatorAmount,
                startTimestamp: uint32(block.timestamp),
                duration: uint32(MIN_SUBMISSION_INTERVAL),
                strategiesAndMultipliers: _getOperatorStrategiesAndMultipliers()
            });
            rewardsCoordinator.createAVSRewardsSubmission(operatorRewards);

            // Distribute AVS rewards
            address[] memory activeAVSs = daoContract.getActiveAVSs();
            uint256 totalWeight = daoContract.getTotalWeight();

            require(totalWeight > 0, "Zero total AVS weight");
            for (uint256 i = 0; i < activeAVSs.length; i++) {
                address avs = activeAVSs[i];
                uint256 avsWeight = daoContract.getAVSWeight(avs);
                uint256 avsReward = (totalAVSAmount * avsWeight) / totalWeight;

                if (avsReward > 0) {
                    token.transfer(avs, avsReward);
                }
            }

            emit RewardsSubmitted(operatorAmount, totalAVSAmount);
        }

        lastSubmissionTime = block.timestamp;
    }

    /**
     * @notice Updates the DAO contract address
     * @param _daoContract New DAO contract address
     */
    function setDAOContract(address _daoContract) external onlyOwner {
        require(_daoContract != address(0), "Invalid DAO contract address");
        address oldDAOContract = address(daoContract);
        daoContract = DAOContract(_daoContract);
        emit DAOContractUpdated(oldDAOContract, _daoContract);
    }

    /**
     * @dev Returns the strategies and their multipliers for operator rewards
     * Override this function to implement custom strategy weights
     */
    function _getOperatorStrategiesAndMultipliers() internal view virtual returns (
        IRewardsCoordinator.StrategyAndMultiplier[] memory
    ) {
        IRewardsCoordinator.StrategyAndMultiplier[] memory strategies = 
            new IRewardsCoordinator.StrategyAndMultiplier       // Example: single strategy with 1x multiplier
        strategies[0] = IRewardsCoordinator.StrategyAndMultiplier({
            strategy: IStrategy(address(token)),
            multiplier: 1
        });

        return strategies;
    }
}
