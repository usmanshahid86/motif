// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract SecurityRegistry is Initializable, OwnableUpgradeable {
    // Operator Set structure
    struct OperatorSet {
        address[] operators;         // List of operators in the set
        uint256 collateral;          // Total collateral staked
        uint256 bitcoinPool;         // Total Bitcoin pooled (tracked externally)
        uint256 lastSlashed;         // Last block when a slashing occurred
        uint256 slashingPenaltyRate; // Penalty rate (e.g., 10% for misbehavior)
    }

    mapping(bytes32 => OperatorSet) public operatorSets; // Map to store operator sets by unique ID
    mapping(address => uint256) public operatorCollateral; // Track individual collateral

    event OperatorSetRegistered(bytes32 indexed setId, address[] operators, uint256 initialCollateral);
    event CollateralStaked(address indexed operator, uint256 amount);
    event SlashingEvent(bytes32 indexed setId, uint256 slashedAmount);
    event RewardsDistributed(bytes32 indexed setId, uint256 totalRewards);

    /**
     * @notice Initialize the contract
     */
    function initialize(address initialOwner) external initializer {
        __Ownable_init();
        transferOwnership(initialOwner);
    }

    /**
     * @notice Register a new operator set
     * @param setId Unique identifier for the operator set
     * @param operators List of operator addresses in the set
     * @param initialCollateral Initial collateral contributed by the set
     */
    function registerOperatorSet(
        bytes32 setId,
        address[] memory operators,
        uint256 initialCollateral,
        uint256 slashingPenaltyRate
    ) external onlyOwner {
        require(operatorSets[setId].collateral == 0, "Operator set already exists");
        operatorSets[setId] = OperatorSet({
            operators: operators,
            collateral: initialCollateral,
            bitcoinPool: 0, // Assume external tracking
            lastSlashed: 0,
            slashingPenaltyRate: slashingPenaltyRate
        });

        emit OperatorSetRegistered(setId, operators, initialCollateral);
    }

    /**
     * @notice Stake collateral for an operator
     * @param operator Address of the operator
     * @param amount Amount of collateral to stake
     */
    function stakeCollateral(address operator, uint256 amount) external payable {
        require(msg.value == amount, "Collateral amount mismatch");
        operatorCollateral[operator] += amount;
        emit CollateralStaked(operator, amount);
    }

    /**
     * @notice Trigger slashing for an operator set
     * @param setId ID of the operator set to be slashed
     * @param reason Reason for the slashing (for logging)
     */
    function slashOperatorSet(bytes32 setId, string memory reason) external onlyOwner {
        OperatorSet storage set = operatorSets[setId];
        require(set.collateral > 0, "Operator set not found");

        uint256 penalty = (set.collateral * set.slashingPenaltyRate) / 100;
        set.collateral -= penalty;
        set.lastSlashed = block.number;

        emit SlashingEvent(setId, penalty);
    }

    /**
     * @notice Distribute rewards to an operator set
     * @param setId ID of the operator set
     * @param totalRewards Total reward amount to distribute
     */
    function distributeRewards(bytes32 setId, uint256 totalRewards) external onlyOwner {
        OperatorSet storage set = operatorSets[setId];
        require(set.operators.length > 0, "Operator set not found");

        uint256 perOperatorReward = totalRewards / set.operators.length;
        for (uint256 i = 0; i < set.operators.length; i++) {
            payable(set.operators[i]).transfer(perOperatorReward); // Distribute rewards
        }

        emit RewardsDistributed(setId, totalRewards);
    }
}
