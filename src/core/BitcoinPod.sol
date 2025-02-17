// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IBitcoinPod.sol";

/**
 * @title BitcoinPod
 * @notice A contract that represents a Bitcoin custody pod managed by an Client and an Operator
 * @dev This contract handles Bitcoin deposits and withdrawals through a designated operator,
 * tracks balances, and manages pod locking/unlocking functionality
 *
 * Key features:
 * - Links a Bitcoin address to an Ethereum address
 * - Tracks Bitcoin balances in the pod
 * - Allows only authorized operator actions
 * - Supports locking mechanism for security
 * - Manages withdrawal transaction storage
 *
 * Security considerations:
 * - Pod can be locked to prevent unauthorized withdrawals
 * - Manager contract has privileged access for administrative functions
 *
 * @dev Security assumptions:
 * - All state-modifying functions are only callable by the PodManager contract
 * - The PodManager is trusted and implements necessary security measures
 * - No direct external calls are made from these functions
 *
 */
contract BitcoinPod is IBitcoinPod, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public operator;
    bytes public operatorBtcPubKey;
    string public bitcoinAddress;
    uint256 public bitcoinBalance;
    bool public locked;
    address public immutable manager;
    bytes public signedBitcoinWithdrawTransaction;
    PodState public podState;
    uint256 private constant MAX_TX_SIZE = 1024 * 100; // 100KB max transaction size

    /**
     * @notice Modifier to ensure the pod is active before execution
     */
    modifier onlyActive() {
        require(podState == PodState.Active, "Pod is not active");
        _;
    }

    /**
     * @notice Modifier to ensure the pod is not locked before execution
     */
    modifier lockedPod() {
        require(!locked, "Pod is locked");
        _;
    }

    /**
     * @notice Modifier to ensure only the manager contract can perform an action
     */
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can perform this action");
        _;
    }

    /**
     * @notice Initializes the immutable manager address
     * @param _manager Address of the BitcoinPodManager contract that manages this pod
     */
    constructor(address _manager) {
        manager = _manager;
        //_disableInitializers();
    }

    /**
     * @notice Initializes a new Bitcoin pod with the specified parameters
     * @param _owner Address that will own this pod contract
     * @param _operator Address of the designated operator who can perform sensitive actions
     * @param _operatorBtcPubKey Bitcoin public key of the operator for multisig address generation
     * @param _btcAddress Multisig Bitcoin address associated with this pod
     * @dev Sets initial state:
     * - Transfers ownership to _owner
     * - Sets operator and their BTC public key
     * - Sets the pod's Bitcoin address
     * - Initializes pod as unlocked and active
     */
    function initialize(address _owner, address _operator, bytes memory _operatorBtcPubKey, string memory _btcAddress)
        external
        initializer
    {
        require(_operatorBtcPubKey.length > 0, "Operator BTC public key cannot be empty");
        require(bytes(_btcAddress).length > 0, "Bitcoin address cannot be empty");
        require(_operator != address(0), "Operator cannot be the zero address");
        require(_owner != address(0), "Owner cannot be the zero address");

        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_owner);
        operator = _operator;
        operatorBtcPubKey = _operatorBtcPubKey;
        bitcoinAddress = _btcAddress;
        locked = false;
        podState = PodState.Active;
        emit PodInitialized(address(this), _owner, _operator);
    }

    // @inheritdoc IBitcoinPod
    function getBitcoinAddress() external view returns (string memory) {
        return bitcoinAddress;
    }

    // @inheritdoc IBitcoinPod
    function getOperatorBtcPubKey() external view returns (bytes memory) {
        return operatorBtcPubKey;
    }

    // @inheritdoc IBitcoinPod
    function getOperator() external view returns (address) {
        return operator;
    }

    // @inheritdoc IBitcoinPod
    function getBitcoinBalance() external view returns (uint256) {
        return bitcoinBalance;
    }

    // @inheritdoc IBitcoinPod
    function getSignedBitcoinWithdrawTransaction() external view returns (bytes memory) {
        return signedBitcoinWithdrawTransaction;
    }

    // @inheritdoc IBitcoinPod
    function setSignedBitcoinWithdrawTransaction(bytes memory _signedBitcoinWithdrawTransaction)
        external
        onlyManager
        nonReentrant
    {
        require(_signedBitcoinWithdrawTransaction.length > 0, "Signed transaction cannot be empty");
        require(podState == PodState.Inactive, "Pod is not inactive");
        require(_signedBitcoinWithdrawTransaction.length <= MAX_TX_SIZE, "Signed transaction exceeds max size");
        signedBitcoinWithdrawTransaction = _signedBitcoinWithdrawTransaction;
        emit WithdrawTransactionSet(_signedBitcoinWithdrawTransaction);
    }

    // @inheritdoc IBitcoinPod
    function setPodState(PodState _newState) external onlyManager nonReentrant {
        require(_isValidStateTransition(podState, _newState), "Invalid state transition");
        PodState previousState = podState;
        podState = _newState;
        emit PodStateChanged(previousState, _newState);
    }

    // @inheritdoc IBitcoinPod
    function lock() external onlyManager onlyActive lockedPod {
        locked = true;
        emit PodLocked(address(this));
    }

    // @inheritdoc IBitcoinPod
    function unlock() external onlyManager {
        locked = false;
        emit PodUnlocked(address(this));
    }

    // @inheritdoc IBitcoinPod
    function isLocked() external view returns (bool) {
        return locked;
    }

    // @inheritdoc IBitcoinPod
    function mint(uint256 amount) external onlyManager onlyActive lockedPod nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        bitcoinBalance += amount;
        emit MintPodValue(address(this), amount);
    }

    // @inheritdoc IBitcoinPod
    function burn(uint256 amount) external onlyManager lockedPod nonReentrant {
        require(podState == PodState.Inactive, "Pod is active");
        require(bitcoinBalance >= amount, "Insufficient balance");
        bitcoinBalance -= amount;
        emit BurnPodValue(address(this), amount);
    }

    // Add getter function for pod state
    function getPodState() external view returns (PodState) {
        return podState;
    }

    function _isValidStateTransition(PodState _from, PodState _to) internal pure returns (bool) {
        return (_from == PodState.Active && _to == PodState.Inactive)
            || (_from == PodState.Inactive && _to == PodState.Active);
    }
}
