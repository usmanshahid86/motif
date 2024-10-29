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

contract BitcoinPodManager is 
    Initializable, 
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    IBitcoinPodManager 
{
    IAppRegistry public appRegistry;
    IBitDSMRegistry public bitDSMRegistry;
    mapping(address => address) public userToPod;
    mapping(address => address) public podToApp;

    event PodCreated(address indexed user, address indexed pod, address indexed operator);
    event PodDelegated(address indexed pod, address indexed appContract);
    event PodUndelegated(address indexed pod);
    event BitcoinMinted(address indexed pod, uint256 amount);
    event BitcoinBurned(address indexed pod, uint256 amount);

    function initialize(address _appRegistry, address _bitDSMRegistry) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        appRegistry = IAppRegistry(_appRegistry);
        bitDSMRegistry = IBitDSMRegistry(_bitDSMRegistry);
    }

    function createPod(address operator, bytes memory btcAddress) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(userToPod[msg.sender] == address(0), "User already has a pod");
        require(bitDSMRegistry.isOperatorBtcKeyRegistered(operator), "Invalid operator");
        
        bytes memory operatorBtcPubKey = bitDSMRegistry.getOperatorBtcPublicKey(operator);
        address newPod = address(new BitcoinPod(msg.sender, operator, operatorBtcPubKey, btcAddress, address(this)));
        userToPod[msg.sender] = newPod;
        
        emit PodCreated(msg.sender, newPod, operator);
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

    function mintBitcoin(address pod, uint256 amount) external whenNotPaused nonReentrant {
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        require(msg.sender == operator, "Only operator can mint");
        
        bitcoinPod.mint(operator, amount);
        emit BitcoinMinted(pod, amount);
    }

    function burnBitcoin(address pod, uint256 amount) external whenNotPaused nonReentrant {
        IBitcoinPod bitcoinPod = IBitcoinPod(pod);
        address operator = bitcoinPod.getOperator();
        require(msg.sender == operator, "Only operator can burn");
        
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
}
