pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IBitcoinPodManager.sol";
import "../interfaces/IAppRegistry.sol";
import "../interfaces/IBitDSMRegistry.sol";
import "../interfaces/IBitcoinPod.sol";
import "./BitcoinPod.sol";
import "../interfaces/IBitDSMServiceManager.sol";

/**
 * @title BitcoinPodManager
 * @notice Manages Bitcoin custody pods for Clients in the BitDSM protocol
 * @dev Handles pod creation, deposits, withdrawals and pod state management
 *
 * The BitcoinPodManager contract provides the following key functionality:
 * - Pod creation and management
 * - Bitcoin deposit and withdrawal request handling for each pod 
 * - Integration with BitDSM Service Manager for operator actions
 * - Pod delegation to apps
 
 *
 * Key components:
 * - BitcoinPod: Individual custody pods that hold Bitcoin
 * - BitDSMServiceManager: Manages operator tasks and verification
 * - AppRegistry: Verifies and delegates to/from registered applications
 *
 * Security features:
 * - Reentrancy protection on state-modifying functions
 * - Access control via modifiers
 * - Circuit breaker (pause) functionality
 * - Pod ownership verification
 * - App verification through App Registry
 *
 * State Management:
 * - Tracks user to pod mappings
 * - Tracks pod to app mappings  
 * - Tracks deposit requests per pod
 * - Tracks withdrawal addresses per pod
 *
 * Key flows:
 * 1. Pod Creation
 *    - User requests for pod creation with a selected operator
 *    - User and operator needs to create a Bitcoin Multisig address beforehand
 *    - Manager verifies operator and creates new BitcoinPod contract
 *    - Transfers ownership of Pod to the user
 *
 * 2. Deposits
 *    - User initiates deposit verification request
 *    - Operator verifies the bitcoin deposit on Bitcoin Network
 *    - Manager updates pod balance
 *
 * 3. Withdrawals  
 *    - User initiates withdrawal request
 *    - Operator signs withdrawal transaction
 *    - Manager facilitates withdrawal completion
 */

contract BitcoinPodManager is 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    IBitcoinPodManager 
{
    /// @notice Address of the BitDSMService manager contract, which manages operator registration/deregistration to AVS and operator tasks.
    address internal _bitDSMServiceManager;
    /// @notice Address of the App Registry contract, which verifies and delegates to/from registered applications
    IAppRegistry public appRegistry;
    /// @notice Address of the BitDSM Registry contract, which verifies and registers operators
    IBitDSMRegistry public bitDSMRegistry;
    /// @notice Mapping of user address to their pod address
    mapping(address => address) public userToPod;
    /// @notice Mapping of pod address to the app address it is delegated to
    mapping(address => address) public podToApp;
    /// @notice Mapping of pod address to the Bitcoin deposit request
    mapping(address => BitcoinDepositRequest) public podToBitcoinDepositRequest;
    /// @notice Mapping of pod address to the withdrawal address
    mapping (address => bytes) public podToWithdrawalAddress;

    /* @dev Ensures that the function is only callable by the `BitDSMServiceManager` contract.
     * This is used to restrict deposit and withdrawal verification to the `BitDSMServiceManager` contract
     */
    modifier onlyBitDSMServiceManager() {
        require(
            msg.sender == _bitDSMServiceManager,
            "BitcoinPodManager.onlyBitDSMServiceManager: caller is not the BitDSMServiceManager"
        );
        _;
    }
    /* @dev Ensures that the function is only callable by the owner of the pod
     * This is used to restrict actions to the pod owner
     */
    modifier onlyPodOwner(address pod) {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        _;
    }
    /**
     * @notice Initialization function to set the app registry, bitDSM registry, and bitDSMServiceManager
     * @param _appRegistry Address of the App Registry contract
     * @param _bitDSMRegistry Address of the BitDSM Registry contract
     * @param bitDSMServiceManager Address of the BitDSMServiceManager contract
     */
    function initialize(address _appRegistry, address _bitDSMRegistry, address bitDSMServiceManager) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        appRegistry = IAppRegistry(_appRegistry);
        bitDSMRegistry = IBitDSMRegistry(_bitDSMRegistry);
        _bitDSMServiceManager = bitDSMServiceManager;
    }

    /**
     * @inheritdoc IBitcoinPodManager
     * @dev Creates a new Bitcoin pod with the specified operator and Bitcoin address
     * @dev Owner can only creata a single pod against its Ethereum address
     * @dev Retrieves operator's Bitcoin public key from registry
     * @dev Creates new BitcoinPod contract and stores mapping
     * @dev Emits PodCreated event
     */
    function createPod(address operator, bytes memory btcAddress)                   
        external 
        whenNotPaused 
        nonReentrant
        returns (address)
    {
        require(userToPod[msg.sender] == address(0), "User already has a pod");
        require(bitDSMRegistry.isOperatorBtcKeyRegistered(operator), "Invalid operator");
        
        bytes memory operatorBtcPubKey = bitDSMRegistry.getOperatorBtcPublicKey(operator);
        address newPod = address(new BitcoinPod(msg.sender, operator, operatorBtcPubKey, btcAddress, address(this)));
        userToPod[msg.sender] = newPod;
        
        emit PodCreated(msg.sender, newPod, operator);
        // return the pod address
        return newPod;
    }

    /**
     * @inheritdoc IBitcoinPodManager
    * @dev Checks:
    * - Caller must be the pod owner
    * - App contract must be registered in AppRegistry
    * - Pod must not already be delegated
    * @dev Updates pod-to-app mapping and emits PodDelegated event
     */
    function delegatePod(address pod, address appContract) external whenNotPaused nonReentrant {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        require(appRegistry.isAppRegistered(appContract), "Invalid app contract");
        require(podToApp[pod] == address(0), "Pod already delegated");
        
        podToApp[pod] = appContract;
        emit PodDelegated(pod, appContract);
    }

    /**
     * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Caller must be the pod owner
     * - Pod must be delegated to an app
     * @dev Updates pod-to-app mapping and emits PodUndelegated event
     */
    function undelegatePod(address pod) external whenNotPaused nonReentrant {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        require(podToApp[pod] != address(0), "Pod not delegated");
        
        delete podToApp[pod];
        emit PodUndelegated(pod);
    }
    /**
     * @notice Internal function to set Bitcoin tokens to a pod
     * @param pod The address of the pod to add tokens to
     * @param amount The amount of tokens to set
     * @dev This function performs the following:
     * - Validates that the pod is not delegated to any app
     * - Emits a BitcoinMinted event
     * @dev Security considerations:
     * - Only callable internally by other functions
     * - Pod must not be delegated to prevent unauthorized minting
     * - Tokens are minted to the pod owner
     */
    function _mintBitcoin(address pod, uint256 amount) internal {
        // check if the pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        //require(msg.sender == operator, "Only operator can mint");
        
        bitcoinPod.mint(operator, amount);
        emit BitcoinMinted(pod, amount);
    }

    /**
     * @notice Internal function to clear Bitcoin tokens from a pod
     * @param pod The address of the pod to remove tokens from
     * @param amount The amount of tokens to remove
     * @dev This function performs the following:
     * - Validates that the pod is not delegated to any app
     * - Emits a BitcoinBurned event
     */
    function _burnBitcoin(address pod, uint256 amount) internal {
        // check if the pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        //require(msg.sender == operator, "Only operator can burn");
        
        bitcoinPod.burn(operator, amount);
        emit BitcoinBurned(pod, amount);
    }
    /**
     * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Pod must be delegated to an app
     * - Caller must be the delegated app
     * @dev Locks the pod
     */
    function lockPod(address pod) external whenNotPaused nonReentrant {
        address appContract = podToApp[pod];
        require(appContract != address(0), "Pod not delegated");
        require(msg.sender == appContract, "Only delegated app can lock");
        
        IBitcoinPod(pod).lock();
    }
    /**
    * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Pod must be delegated to an app
     * - Caller must be the delegated app
     * @dev Unlocks the pod
     */
    function unlockPod(address pod) external whenNotPaused nonReentrant {
        address appContract = podToApp[pod];
        require(appContract != address(0), "Pod not delegated");
        require(msg.sender == appContract, "Only delegated app can unlock");
        
        IBitcoinPod(pod).unlock();
    }

    // @inheritdoc IBitcoinPodManager
    function getBitcoinDepositRequest(address pod) external view returns (BitcoinDepositRequest memory) {
        return podToBitcoinDepositRequest[pod];
    }

    // @inheritdoc IBitcoinPodManager
    function getBitcoinWithdrawalAddress(address pod) external view returns (bytes memory) {
        return podToWithdrawalAddress[pod];
    }

    /** 
     * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Caller must be the pod owner
     * - No pending deposit request
     * @dev Updates pod-to-bitcoin deposit request mapping and emits VerifyBitcoinDepositRequest event
     */
    function verifyBitcoinDepositRequest(address pod, bytes32 transactionId, uint256 amount) external whenNotPaused nonReentrant onlyPodOwner(pod) {
        // check if any request is pending
        require(podToBitcoinDepositRequest[pod].isPending == false, "Request already pending");
        podToBitcoinDepositRequest[pod] = BitcoinDepositRequest(transactionId, amount, true);
        // get operator for the pod
        address operator = IBitcoinPod(pod).getOperator();
        emit VerifyBitcoinDepositRequest(pod, operator, BitcoinDepositRequest(transactionId, amount, true));
    }
    /**
     * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Caller must be BitDSM Service Manager
     * - Transaction ID must match pending deposit request
     * @dev Updates pod state:
     * - Adds Bitcoin token value to pod
     * - Clears pending deposit request
     * @dev Emits BitcoinDepositConfirmed event
     */
    function confirmBitcoinDeposit(address pod, bytes32 transactionId, uint256 amount) external whenNotPaused nonReentrant onlyBitDSMServiceManager{
        // get the deposit index
        BitcoinDepositRequest memory depositRequest = podToBitcoinDepositRequest[pod];
        require(depositRequest.transactionId == transactionId, "Invalid transaction id");
        depositRequest.isPending = false;

        // update the amount for the pod
        _mintBitcoin(pod, amount);
        // emit verification event
        emit BitcoinDepositConfirmed(pod, amount);
        // delete the deposit request
        delete podToBitcoinDepositRequest[pod];
    }

    // submit Withdrawal request from the pod Owner
    // PSBT is the partial Bitcoin transaction created and presigned by the Operator to be completed by the Service Manager
    // in response to the withdrawal request
    /**
     * @inheritdoc IBitcoinPodManager
     * @dev This function starts the PSBT withdrawal flow where:
     * 1. Pod owner initiates a withdrawal request
     * 2. Operator creates and signs PSBT in response to the request
     * 3. Operator sends the PSBT to the Service Manager
     * 4. Service manager verifies and stores PSBT in pod
     * 5. Pod owner can retrieve and complete PSBT
     * @dev Checks:
     * - Caller must be the pod owner
     * - No pending withdrawal request exists
     * - Pod must be unlocked
     * - Pod must not be delegated to any app
     * - Withdrawal address must be valid
     * @dev Updates pod-to-withdrawal address mapping and emits BitcoinWithdrawalPSBTRequest event
     * @dev The operator will create and sign PSBT in response to this request
     */
    function withdrawBitcoinPSBTRequest(address pod, bytes memory withdrawAddress) external whenNotPaused nonReentrant onlyPodOwner(pod){
        require(podToWithdrawalAddress[pod].length == 0, "Withdrawal already requested");
        require(withdrawAddress.length > 0, "Invalid withdraw address");
        // check if the pod is locked
        require(IBitcoinPod(pod).isLocked() == false, "Pod is locked");

        // check if pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        // get the operator for the pod
        address operator = IBitcoinPod(pod).getOperator();
        podToWithdrawalAddress[pod] = withdrawAddress;
        // emit the event
        emit BitcoinWithdrawalPSBTRequest(pod, operator, withdrawAddress);
    }
    // request for complete withdrawal transaction
    // preSignedWithdrawTransaction is the Bitcoin transaction signed by the Client
    // OPerator is required to complete the transaction and send it back to the pod owner
    /**
     * @inheritdoc IBitcoinPodManager
     * @dev This function starts the complete transaction withdrawal flow where:
     * 1. Pod owner creates and signs a Bitcoin transaction
     * 2. Pod owner initiates withdrawal with the pre-signed transaction
     * 3. Operator completes signing the transaction
     * 4. Service manager verifies and stores completed transaction in pod
     * 5. Pod owner can retrieve and broadcast transaction
     * @dev Checks:
     * - Caller must be the pod owner
     * - No pending withdrawal request exists
     * - Pod must be unlocked
     * - Pod must not be delegated to any app
     * - Withdrawal address must be valid
     * - Pre-signed transaction must be provided
     * @dev Updates pod-to-withdrawal address mapping and emits BitcoinWithdrawalCompleteTxRequest event
     * @dev The operator will complete signing the transaction in response to this request
     */
    function withdrawBitcoinCompleteTxRequest(address pod, bytes memory preSignedWithdrawTransaction, bytes memory withdrawAddress) external whenNotPaused nonReentrant onlyPodOwner(pod){
        require(podToWithdrawalAddress[pod].length == 0, "Withdrawal already requested");
        require(withdrawAddress.length > 0, "Invalid withdraw address");
        // check if the pod is locked
        require(IBitcoinPod(pod).isLocked() == false, "Pod is locked");

        // check if pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        // get the operator for the pod
        address operator = IBitcoinPod(pod).getOperator();
        podToWithdrawalAddress[pod] = withdrawAddress;
        // emit the event
        emit BitcoinWithdrawalCompleteTxRequest(pod, operator, preSignedWithdrawTransaction);
    }
    /**
     * @notice Withdraws Bitcoin as tokens from a pod
     * @dev This function handles the clearing of Bitcoin token value from a pod by:
     * 1. Verifying there is an active withdrawal request
     * 3. Unsetting the pod's entire Bitcoin balance
     * 4. Emitting withdrawal event
     * 5. Cleaning up withdrawal request state
     * @dev Can only be called by the BitDSM Service Manager
     * @dev Checks:
     * - Pod must have an active withdrawal request
     */
    function withdrawBitcoinAsTokens(address pod) external whenNotPaused nonReentrant onlyBitDSMServiceManager{
        // check if the pod has a withdrawal request
        require(podToWithdrawalAddress[pod].length != 0, "No withdrawal request");
        // check if 
        // get the withdrawal address
        bytes memory withdrawAddress = podToWithdrawalAddress[pod];
        // burn the amount
        _burnBitcoin(pod, IBitcoinPod(pod).getBitcoinBalance());
        // emit the event
        emit BitcoinWithdrawnFromPod(pod, withdrawAddress);
        // delete the withdrawal address
        delete podToWithdrawalAddress[pod];
    }
    /**
     * @inheritdoc IBitcoinPodManager
     * @dev Checks:
     * - Caller must be BitDSM Service Manager
     * @dev Updates pod state:
     * - Stores the signed Bitcoin withdrawal transaction
     * @param pod The address of the pod
     * @param signedBitcoinWithdrawTransaction The signed Bitcoin PSBT or raw transaction
     */
    function setSignedBitcoinWithdrawTransactionPod(address pod, bytes memory signedBitcoinWithdrawTransaction) external whenNotPaused onlyBitDSMServiceManager{
        IBitcoinPod(pod).setSignedBitcoinWithdrawTransaction(signedBitcoinWithdrawTransaction);
    }
}
