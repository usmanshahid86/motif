import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import BodManagerABI from './abis/BodManager.sol/BodManager.json';
import BodABI from './abis/Bod.sol/Bod.json';
import CDPContractABI from './abis/CDPContract.sol/CDPContract.json';

function App() {
  const [bodManagerAddress, setBodManagerAddress] = useState('');
  const [bodAddress, setBodAddress] = useState('');
  const [cdpAddress, setCdpAddress] = useState('');
  const [bitcoinAddress, setBitcoinAddress] = useState('');
  const [lockedBitcoin, setLockedBitcoin] = useState('0');
  const [isLocked, setIsLocked] = useState(false);
  const [stablecoinBalance, setStablecoinBalance] = useState('0');
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);

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
      await provider.send("eth_requestAccounts", []); // Request user accounts
      const signer = await provider.getSigner();
      const BodManagerFactory = new ethers.ContractFactory(BodManagerABI.abi, BodManagerABI.bytecode, signer);
      const bodManager = await BodManagerFactory.deploy();
      await bodManager.waitForDeployment();
      setBodManagerAddress(await bodManager.getAddress());
    } catch (error) {
      console.error("Error deploying BodManager:", error);
    }
  };

  const createBod = async () => {
    const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
    const tx = await bodManager.createBod(bitcoinAddress);
    await tx.wait();
    const userAddress = await signer.getAddress();
    const bodAddress = await bodManager.getBod(userAddress);
    setBodAddress(bodAddress);
  };

  const getBodAddress = async () => {
    const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
    const userAddress = await signer.getAddress();
    const bodAddress = await bodManager.getBod(userAddress);
    setBodAddress(bodAddress);
  };

  const lockBitcoin = async () => {
    const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
    const tx = await bodManager.lockBitcoin(ethers.hexlify(ethers.randomBytes(32)), ethers.parseUnits("0.001", "ether"));
    await tx.wait();
  };

  const deployCDP = async () => {
    const CDPFactory = new ethers.ContractFactory(CDPContractABI.abi, CDPContractABI.bytecode, signer);
    const cdp = await CDPFactory.deploy(bodAddress);
    await cdp.deployed();
    setCdpAddress(cdp.address);
  };

  const lockBod = async () => {
    const cdp = new ethers.Contract(cdpAddress, CDPContractABI.abi, signer);
    const tx = await cdp.lockBod();
    await tx.wait();
  };

  const checkLockStatus = async () => {
    const bod = new ethers.Contract(bodAddress, BodABI.abi, provider);
    const locked = await bod.isLocked();
    setIsLocked(locked);
  };

  const getLockedBitcoin = async () => {
    const bod = new ethers.Contract(bodAddress, BodABI.abi, provider);
    const amount = await bod.getLockedBitcoin();
    setLockedBitcoin(ethers.formatUnits(amount, "ether"));
  };

  const mintStablecoin = async () => {
    const cdp = new ethers.Contract(cdpAddress, CDPContractABI.abi, signer);
    const tx = await cdp.mintStablecoin(ethers.parseUnits("50", "ether"));
    await tx.wait();
  };

  const getStablecoinBalance = async () => {
    const cdp = new ethers.Contract(cdpAddress, CDPContractABI.abi, provider);
    const userAddress = await signer.getAddress();
    const balance = await cdp.balanceOf(userAddress);
    setStablecoinBalance(ethers.formatUnits(balance, "ether"));
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
          placeholder="Enter Bitcoin Address"
          value={bitcoinAddress}
          onChange={(e) => setBitcoinAddress(e.target.value)}
        />
        <button onClick={createBod}>Create Bod</button>
        <button onClick={getBodAddress}>Get Bod Address</button>
        <p>Bod Address: {bodAddress}</p>
      </div>
      <div>
        <button onClick={lockBitcoin}>Lock Bitcoin (0.001 BTC)</button>
      </div>
      <div>
        <button onClick={deployCDP}>Deploy CDP</button>
        <p>CDP Address: {cdpAddress}</p>
      </div>
      <div>
        <button onClick={lockBod}>Lock Bod</button>
        <button onClick={checkLockStatus}>Check Lock Status</button>
        <p>Is Locked: {isLocked ? "Yes" : "No"}</p>
      </div>
      <div>
        <button onClick={getLockedBitcoin}>Get Locked Bitcoin</button>
        <p>Locked Bitcoin: {lockedBitcoin} BTC</p>
      </div>
      <div>
        <button onClick={mintStablecoin}>Mint Stablecoin (50 BITC)</button>
        <button onClick={getStablecoinBalance}>Get Stablecoin Balance</button>
        <p>Stablecoin Balance: {stablecoinBalance} BITC</p>
      </div>
    </div>
  );
}

export default App;
