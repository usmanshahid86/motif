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

contract BitcoinPodManager is 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    IBitcoinPodManager 
{
    /// @notice Address of the BitDSMService manager contract, which manages operator registration/deregistration to AVS and operator tasks.
    address internal _bitDSMServiceManager;
    IAppRegistry public appRegistry;
    IBitDSMRegistry public bitDSMRegistry;
    mapping(address => address) public userToPod;
    mapping(address => address) public podToApp;
    mapping(address => BitcoinDepositRequest) public podToBitcoinDepositRequest;
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

    modifier onlyPodOwner(address pod) {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        _;
    }

    function initialize(address _appRegistry, address _bitDSMRegistry, address bitDSMServiceManager) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        appRegistry = IAppRegistry(_appRegistry);
        bitDSMRegistry = IBitDSMRegistry(_bitDSMRegistry);
        _bitDSMServiceManager = bitDSMServiceManager;
    }

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

    function delegatePod(address pod, address appContract) external whenNotPaused nonReentrant {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        require(appRegistry.isAppRegistered(appContract), "Invalid app contract");
        require(podToApp[pod] == address(0), "Pod already delegated");
        
        podToApp[pod] = appContract;
        emit PodDelegated(pod, appContract);
    }

    function undelegatePod(address pod) external whenNotPaused nonReentrant {
        require(userToPod[msg.sender] == pod, "Not the pod owner");
        require(podToApp[pod] != address(0), "Pod not delegated");
        
        delete podToApp[pod];
        emit PodUndelegated(pod);
    }
// removing the nonReentrant and whenNotPaused modifiers as the calling function already has them

    function _mintBitcoin(address pod, uint256 amount) internal {
        // check if the pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        //require(msg.sender == operator, "Only operator can mint");
        
        bitcoinPod.mint(operator, amount);
        emit BitcoinMinted(pod, amount);
    }
// removing the nonReentrant and whenNotPaused modifiers as the calling function already has them
    function _burnBitcoin(address pod, uint256 amount) internal {
        // check if the pod is undelegated
        require(podToApp[pod] == address(0), "Pod is delegated");
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        //require(msg.sender == operator, "Only operator can burn");
        
        bitcoinPod.burn(operator, amount);
        emit BitcoinBurned(pod, amount);
    }

    function lockPod(address pod) external whenNotPaused nonReentrant {
        address appContract = podToApp[pod];
        require(appContract != address(0), "Pod not delegated");
        require(msg.sender == appContract, "Only delegated app can lock");
        
        IBitcoinPod(pod).lock();
    }

    function unlockPod(address pod) external whenNotPaused nonReentrant {
        address appContract = podToApp[pod];
        require(appContract != address(0), "Pod not delegated");
        require(msg.sender == appContract, "Only delegated app can unlock");
        
        IBitcoinPod(pod).unlock();
    }

    
    function getBitcoinDepositRequest(address pod) external view returns (BitcoinDepositRequest memory) {
        return podToBitcoinDepositRequest[pod];
    }

    function getBitcoinWithdrawalAddress(address pod) external view returns (bytes memory) {
        return podToWithdrawalAddress[pod];
    }

    
    /**  @notice verify the deposit request from the pod owner
     * @param pod the pod address
     * @param transactionId the Bitcoin transaction id
     * @param amount the amount deposited
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
     * @notice confirm the deposit from the service manager
     * @param pod the pod address 
     * @param transactionId the Bitcoin transaction id
     * @param amount the amount deposited
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

    function setSignedBitcoinWithdrawTransactionPod(address pod, bytes memory signedBitcoinWithdrawTransaction) external whenNotPaused onlyBitDSMServiceManager{
        IBitcoinPod(pod).setSignedBitcoinWithdrawTransaction(signedBitcoinWithdrawTransaction);
    }
}
