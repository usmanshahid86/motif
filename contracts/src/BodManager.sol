pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import "./Bod.sol";

contract BodManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    mapping(address => Bod) public ownerToBod;
    uint256 public numBods;

    event BodCreated(address indexed owner, address bodAddress, string bitcoinAddress);

    function initialize(address initialOwner) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        transferOwnership(initialOwner);
    }

    function createBod(string memory bitcoinAddress) external nonReentrant returns (address) {
        require(address(ownerToBod[msg.sender]) == address(0), "BodManager: Sender already has a bod");
        require(bytes(bitcoinAddress).length > 0, "BodManager: Bitcoin address cannot be empty");
        Bod bod = new Bod();
        bod.initialize(msg.sender, address(this), bitcoinAddress);
        ownerToBod[msg.sender] = bod;
        numBods++;
        emit BodCreated(msg.sender, address(bod), bitcoinAddress);
        return address(bod);
    }

    function lockBitcoin(bytes32 btcTxHash, uint256 amount) external nonReentrant {
        Bod bod = ownerToBod[msg.sender];
        require(address(bod) != address(0), "BodManager: Sender does not have a bod");
        bod.depositBitcoin(amount, btcTxHash);
    }

    function hasBod(address bodOwner) public view returns (bool) {
        return address(ownerToBod[bodOwner]) != address(0);
    }

    function getBod(address bodOwner) public view returns (address) {
        return address(ownerToBod[bodOwner]);
    }
}
