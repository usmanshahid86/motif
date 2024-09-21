pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./Bod.sol";

contract BodManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    mapping(address => Bod) public ownerToBod;
    uint256 public numBods;

    event BodCreated(address indexed owner, address bodAddress);

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        transferOwnership(initialOwner);
    }

    function createBod() external nonReentrant returns (address) {
        require(address(ownerToBod[msg.sender]) == address(0), "BodManager: Sender already has a bod");
        Bod bod = new Bod();
        bod.initialize(msg.sender, address(this));
        ownerToBod[msg.sender] = bod;
        numBods++;
        emit BodCreated(msg.sender, address(bod));
        return address(bod);
    }

    function lockBitcoin(bytes32 btcTxHash, uint256 amount) external nonReentrant {
        Bod bod = ownerToBod[msg.sender];
        require(address(bod) != address(0), "BodManager: Sender does not have a bod");
        bod.lockBitcoin(btcTxHash, amount);
    }

    function hasBod(address bodOwner) public view returns (bool) {
        return address(ownerToBod[bodOwner]) != address(0);
    }
}
