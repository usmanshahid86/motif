import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import BodManagerABI from './abis/BodManager.sol/BodManager.json';
import BodABI from './abis/Bod.sol/Bod.json';
import CDPContractABI from './abis/CDPContract.sol/CDPContract.json';

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [bodManagerAddress, setBodManagerAddress] = useState('');
  const [bodAddress, setBodAddress] = useState('');
  const [cdpAddress, setCdpAddress] = useState('');
  const [bitcoinAddress, setBitcoinAddress] = useState('bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
  const [lockedBitcoin, setLockedBitcoin] = useState('0');
  const [stablecoinBalance, setStablecoinBalance] = useState('0');

  useEffect(() => {
    const initializeEthers = async () => {
      if (window.ethereum) {
        const provider = new ethers.BrowserProvider(window.ethereum);
        setProvider(provider);
        try {
          const signer = await provider.getSigner();
          setSigner(signer);
        } catch (error) {
          console.error("Failed to get signer", error);
        }
      } else {
        console.log("Please install MetaMask!");
      }
    };

    initializeEthers();
  }, []);

  const deployBodManager = async () => {
    try {
      await provider.send("eth_requestAccounts", []);
      const BodManagerFactory = new ethers.ContractFactory(BodManagerABI.abi, BodManagerABI.bytecode, signer);
      const bodManager = await BodManagerFactory.deploy();
      await bodManager.waitForDeployment();
      const address = await bodManager.getAddress();
      setBodManagerAddress(address);
      console.log("BodManager deployed at:", address);
    } catch (error) {
      console.error("Error deploying BodManager:", error);
    }
  };

  const deployBod = async () => {
    try {
      const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
      const tx = await bodManager.createBod(bitcoinAddress);
      await tx.wait();
      const userAddress = await signer.getAddress();
      const newBodAddress = await bodManager.getBod(userAddress);
      setBodAddress(newBodAddress);
      console.log("Bod deployed at:", newBodAddress);
    } catch (error) {
      console.error("Error deploying Bod:", error);
    }
  };

  const deployCDP = async () => {
    try {
      if (!bodAddress) {
        console.error("Bod address not set. Please deploy a Bod first.");
        return;
      }
      
      // Check Bod ownership
      const bod = new ethers.Contract(bodAddress, BodABI.abi, provider);
      const bodOwner = await bod.bodOwner();
      const currentAccount = await signer.getAddress();
      console.log("Bod owner:", bodOwner);
      console.log("Current account:", currentAccount);
      if (bodOwner.toLowerCase() !== currentAccount.toLowerCase()) {
        console.error("Current account is not the Bod owner");
        return;
      }

      console.log("Deploying CDP...");
      const CDPFactory = new ethers.ContractFactory(CDPContractABI.abi, CDPContractABI.bytecode, signer);
      console.log("Bod address:", bodAddress);
      const cdp = await CDPFactory.deploy(bodAddress);
      console.log("CDP deployment transaction sent. Waiting for confirmation...");
      await cdp.waitForDeployment();
      const address = await cdp.getAddress();
      setCdpAddress(address);
      console.log("CDP deployed at:", address);

      // // Check new Bod owner
      // const newBodOwner = await bod.bodOwner();
      // console.log("New Bod owner:", newBodOwner);

      // // Lock Bod
      // console.log("Locking Bod...");
      const cdpContract = new ethers.Contract(address, CDPContractABI.abi, signer);
      // const isLocked = await bod.isLocked();
      // console.log("Is Bod locked?", isLocked);
      // if (!isLocked) {
      //   let tx = await cdpContract.lockBod();
      //   await tx.wait();
      //   console.log("Bod locked");
      // } else {
      //   console.log("Bod is already locked");
      // }

      // Mint stablecoin
      // console.log("Minting stablecoin...");
      // const lockedBitcoin = await bod.getLockedBitcoin();
      // console.log("Locked Bitcoin:", lockedBitcoin.toString());
      // const collateralRatio = await cdpContract.COLLATERAL_RATIO();
      // console.log("Collateral Ratio:", collateralRatio.toString());
      // const maxStablecoin = lockedBitcoin.mul(100).div(collateralRatio);
      // console.log("Max Stablecoin:", maxStablecoin.toString());
      let tx = await cdpContract.mintStablecoin(1000000000000000);
      await tx.wait();
      console.log("Stablecoin minted");
    } catch (error) {
      console.error("Error deploying CDP or minting stablecoin:", error);
      if (error.reason) {
        console.error("Error reason:", error.reason);
      }
      if (error.transaction) {
        console.error("Transaction that caused the error:", error.transaction);
      }
    }
  };

  const getBalances = async () => {
    try {
      if (!bodAddress || !cdpAddress) {
        console.error("Bod or CDP address not set. Please deploy both contracts first.");
        return;
      }
      console.log("Fetching balances...");
      const bod = new ethers.Contract(bodAddress, BodABI.abi, provider);
      const cdp = new ethers.Contract(cdpAddress, CDPContractABI.abi, provider);
      const userAddress = await signer.getAddress();

      console.log("Getting locked Bitcoin amount...");
      const lockedBitcoinAmount = await bod.getLockedBitcoin();
      const formattedBitcoin = ethers.formatUnits(lockedBitcoinAmount, "ether");
      setLockedBitcoin(formattedBitcoin);
      console.log("Locked Bitcoin:", formattedBitcoin, "BTC");

      console.log("Getting stablecoin balance...");
      const stablecoinAmount = await cdp.balanceOf(userAddress);
      const formattedStablecoin = ethers.formatUnits(stablecoinAmount, "ether");
      setStablecoinBalance(formattedStablecoin);
      console.log("Stablecoin Balance:", formattedStablecoin, "BITC");
    } catch (error) {
      console.error("Error getting balances:", error);
    }
  };

  const lockBitcoin = async () => {
    try {
      if (!bodManagerAddress) {
        console.error("BodManager address not set. Please deploy BodManager first.");
        return;
      }
      console.log("Locking 0.01 BTC...");
      const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
      const amount = ethers.parseEther("0.01"); // 0.01 BTC
      const btcTxHash = ethers.hexlify(ethers.randomBytes(32)); // Simulating a Bitcoin transaction hash
      const tx = await bodManager.lockBitcoin(btcTxHash, amount);
      console.log("Transaction sent. Waiting for confirmation...");
      await tx.wait();
      console.log("0.01 BTC locked successfully");
    } catch (error) {
      console.error("Error locking Bitcoin:", error);
    }
  };

  const checkBodOwner = async () => {
    if (!bodAddress) {
      console.error("Bod address not set. Please deploy a Bod first.");
      return;
    }
    const bod = new ethers.Contract(bodAddress, BodABI.abi, provider);
    const owner = await bod.bodOwner();
    console.log("Bod owner:", owner);
    const currentAccount = await signer.getAddress();
    console.log("Current account:", currentAccount);
    if (owner.toLowerCase() === currentAccount.toLowerCase()) {
      console.log("Current account is the Bod owner");
    } else {
      console.log("Current account is NOT the Bod owner");
    }
  };

  return (
    <div className="App">
      <h1>BitDSM Frontend</h1>
      <div>
        <button onClick={deployBodManager}>Deploy BodManager</button>
        <p>BodManager Address: {bodManagerAddress}</p>
      </div>
      <div>
        <input
          type="text"
          placeholder="bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
          value="bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
          onChange={(e) => setBitcoinAddress(e.target.value)}
        />
        <button onClick={deployBod}>Deploy Bod</button>
        <button onClick={lockBitcoin}>Lock 0.01 BTC</button>
        <p>Bod Address: {bodAddress}</p>
      </div>
      <div>
        <button onClick={deployCDP}>Deploy CDP</button>
        <p>CDP Address: {cdpAddress}</p>
      </div>
      <div>
        <button onClick={getBalances}>Get Balances</button>
        <p>Locked Bitcoin: {lockedBitcoin} BTC</p>
        <p>Stablecoin Balance: {stablecoinBalance} BITC</p>
      </div>
      <div>
        <button onClick={checkBodOwner}>Check Bod Owner</button>
      </div>
    </div>
  );
}

export default App;
