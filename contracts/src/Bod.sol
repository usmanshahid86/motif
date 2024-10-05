pragma solidity ^0.8.9;

import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";

contract Bod is Initializable, ReentrancyGuardUpgradeable {
    address public bodOwner;
    address public bodManager;
    uint256 public lockedBitcoin;
    bool public isLocked;
    address public lockedBy;
    string public bitcoinAddress;

    event BitcoinLocked(bytes32 btcTxHash, uint256 amount);
    event BodLocked(address locker);
    event BodUnlocked(address unlocker);
    event DepositReceived(address indexed operator, uint256 amount);

    function setBodOwner(address _newOwner) external onlyBodOwner {
        require(_newOwner != address(0), "Bod: new owner is the zero address");
        bodOwner = _newOwner;
    }

    modifier onlyBodManager() {
        require(msg.sender == bodManager, "Bod: not bodManager");
        _;
    }

    modifier onlyBodOwner() {
        require(msg.sender == bodOwner, "Bod: not bodOwner");
        _;
    }

    modifier whenNotLocked() {
        require(!isLocked, "Bod: locked");
        _;
    }

    function initialize(address _bodOwner, address _bodManager, string memory _bitcoinAddress) external initializer {
        require(_bodOwner != address(0), "Bod: bodOwner cannot be zero address");
        require(_bodManager != address(0), "Bod: bodManager cannot be zero address");
        require(bytes(_bitcoinAddress).length > 0, "Bod: Bitcoin address cannot be empty");
        bodOwner = _bodOwner;
        bodManager = _bodManager;
        bitcoinAddress = _bitcoinAddress;
        lockedBitcoin = 2;
    }

    function lock(address locker) external onlyBodOwner whenNotLocked {
        isLocked = true;
        lockedBy = locker;
        emit BodLocked(locker);
    }

    function unlock() external {
        require(msg.sender == bodOwner || msg.sender == lockedBy, "Bod: not authorized to unlock");
        require(isLocked, "Bod: not locked");
        isLocked = false;
        lockedBy = address(0);
        emit BodUnlocked(msg.sender);
    }

    function getLockedBitcoin() external view returns (uint256) {
        return lockedBitcoin;
    }

    function depositBitcoin(uint256 amount, bytes32 btcTxHash) external onlyBodManager whenNotLocked {
        require(amount > 0, "Bod: Amount must be greater than 0");
        require(btcTxHash != bytes32(0), "Bod: Invalid Bitcoin transaction hash");
        
        lockedBitcoin += amount;
        emit BitcoinLocked(btcTxHash, amount);
        emit DepositReceived(msg.sender, amount);
    }

    uint256 public constant MIN_BITCOIN_REQUIRED = 1; // 0.001 BTC in satoshis

    function canLock() public view returns (bool) {
        return lockedBitcoin >= MIN_BITCOIN_REQUIRED;
    }
}
