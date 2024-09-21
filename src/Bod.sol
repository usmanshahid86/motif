pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract Bod is Initializable, ReentrancyGuardUpgradeable {
    address public bodOwner;
    address public bodManager;
    uint256 public lockedBitcoin;
    bool public isLocked;

    event BitcoinLocked(bytes32 btcTxHash, uint256 amount);
    event BodLocked(address locker);
    event BodUnlocked(address unlocker);
    event DepositReceived(address indexed operator, uint256 amount);

    function setBodOwner(address _newOwner) external onlyBodOwner {
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

    function initialize(address _bodOwner, address _bodManager) external initializer {
        require(_bodOwner != address(0), "Bod: bodOwner cannot be zero address");
        require(_bodManager != address(0), "Bod: bodManager cannot be zero address");
        bodOwner = _bodOwner;
        bodManager = _bodManager;
    }

    function lockBitcoin(bytes32 btcTxHash, uint256 amount) external onlyBodManager whenNotLocked {
        require(btcTxHash != bytes32(0), "Bod: Invalid Bitcoin transaction hash");
        require(amount > 0, "Bod: Amount must be greater than 0");
        
        lockedBitcoin += amount;
        emit BitcoinLocked(btcTxHash, amount);
    }

    function lock() external onlyBodOwner whenNotLocked {
        isLocked = true;
        emit BodLocked(msg.sender);
    }

    function unlock() external onlyBodOwner {
        require(isLocked, "Bod: not locked");
        isLocked = false;
        emit BodUnlocked(msg.sender);
    }

    function getLockedBitcoin() external view returns (uint256) {
        return lockedBitcoin;
    }

    function depositBitcoin(uint256 amount) external onlyBodManager {
        require(amount > 0, "Bod: Deposit amount must be greater than 0");
        lockedBitcoin += amount;
        emit DepositReceived(msg.sender, amount);
    }
}
