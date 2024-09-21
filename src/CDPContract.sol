pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Bod.sol";

contract CDPContract is ERC20, Ownable {
    Bod public bod;
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization ratio
    uint256 public constant LIQUIDATION_THRESHOLD = 120; // 120% liquidation threshold

    event StablecoinMinted(address indexed user, uint256 amount);
    event StablecoinBurned(address indexed user, uint256 amount);
    event CollateralLiquidated(address indexed user, uint256 amount);

    constructor(address _bod) ERC20("BITC Stablecoin", "BITC") Ownable(msg.sender) {
        bod = Bod(_bod);
        require(bod.bodOwner() == msg.sender, "CDPContract: Caller is not the Bod owner");
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        require(bod.canLock(), "CDPContract: Insufficient Bitcoin in Bod");
        //bod.setBodOwner(address(this)); // Transfer ownership to the CDPContract
        //this.lockBod();
        //this.mintStablecoin(1);
    }

    bool private bodLocked;

    modifier onlyWhenBodLocked() {
        require(bodLocked, "CDPContract: Bod must be locked");
        _;
    }

    function mintStablecoin(uint256 amount) external {
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        uint256 maxStablecoin = (lockedBitcoin * 100) / COLLATERAL_RATIO;
        require(totalSupply() + amount <= maxStablecoin, "CDPContract: Exceeds maximum mintable amount");

        _mint(msg.sender, amount);
        emit StablecoinMinted(msg.sender, amount);
    }

    function burnStablecoin(uint256 amount) external onlyWhenBodLocked {
        require(balanceOf(msg.sender) >= amount, "CDPContract: Insufficient balance");
        _burn(msg.sender, amount);
        emit StablecoinBurned(msg.sender, amount);
    }

    function liquidate() external onlyOwner onlyWhenBodLocked {
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        uint256 currentCollateralRatio = (lockedBitcoin * 100) / totalSupply();
        
        require(currentCollateralRatio < LIQUIDATION_THRESHOLD, "CDPContract: Collateral ratio above liquidation threshold");

        uint256 amountToLiquidate = totalSupply() - (lockedBitcoin * 100) / COLLATERAL_RATIO;
        _burn(address(this), amountToLiquidate);
        emit CollateralLiquidated(address(this), amountToLiquidate);
    }

    function unlockBod() external onlyOwner {
        require(totalSupply() == 0, "CDPContract: Cannot unlock while stablecoins are in circulation");
        bod.unlock();
    }

    function lockBod() external onlyOwner {
        require(bod.bodOwner() == address(this), "CDPContract: CDPContract is not the Bod owner");
        require(bod.isLocked() == false, "CDPContract: Bod is already locked");
        bod.lock(address(this));
        bodLocked = true;
    }

    function getLockedBitcoin() external view returns (uint256) {
        return bod.getLockedBitcoin();
    }
}
