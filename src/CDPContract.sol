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

    constructor(address _bod) ERC20("CDP Stablecoin", "CDPS") {
        bod = Bod(_bod);
        require(bod.bodOwner() == msg.sender, "CDPContract: Caller is not the Bod owner");
        bod.lock(); // Lock the Bod
    }

    function mintStablecoin(uint256 amount) external onlyOwner {
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        uint256 maxStablecoin = (lockedBitcoin * 100) / COLLATERAL_RATIO;
        require(totalSupply() + amount <= maxStablecoin, "CDPContract: Exceeds maximum mintable amount");

        _mint(msg.sender, amount);
        emit StablecoinMinted(msg.sender, amount);
    }

    function burnStablecoin(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "CDPContract: Insufficient balance");
        _burn(msg.sender, amount);
        emit StablecoinBurned(msg.sender, amount);
    }

    function liquidate() external onlyOwner {
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
}
