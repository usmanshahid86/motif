"use client";

import { Button } from "@/components/ui/button";
import { Carousel, CarouselApi, CarouselContent, CarouselItem } from "@/components/ui/carousel";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { getBODAddress } from "@/lib/core";
import { isBitcoinWallet } from "@dynamic-labs/bitcoin";
import { DynamicWidget, useDynamicContext, useEmbeddedReveal, useEmbeddedWallet } from "@dynamic-labs/sdk-react-core";
import { Bitcoin, Loader2 } from 'lucide-react';
import React, { useCallback, useEffect, useRef, useState } from "react";
import { isEthereumWallet } from '@dynamic-labs/ethereum';
import { ethers } from 'ethers';
import { Eip1193Provider } from 'ethers';
import BodManagerABI from "@/lib/abis/BodManager.sol/BodManager.json"
import BodABI from '@/lib/abis/Bod.sol/Bod.json';
import CDPContractABI from '@/lib/abis/CDPContract.sol/CDPContract.json';
import { useToast } from '@/hooks/use-toast';

const OPERATORS = [
  {
    name: "Brave",
    address: "0xf...c1b",
  },
  {
    name: "Charlie",
    address: "0xb...3fa",
  },
  {
    name: "Delta",
    address: "0xc...bb4",
  },
];

function AppWrapper() {
  const { primaryWallet } = useDynamicContext();
  const { toast } = useToast()

  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [signer, setSigner] = useState<ethers.JsonRpcSigner | null>(null);

  const [message, setMessage] = useState("Hello World");
  const [publicKey, setPublicKey] = useState("");

  const [loader1, setLoader1] = useState(false)
  const [loader2, setLoader2] = useState(false)
  const [loader3, setLoader3] = useState(false)
  const [loader4, setLoader4] = useState(false)
  const [loader5, setLoader5] = useState(false)

  const [bodAddress, setBodAddress] = useState("");
  const [isLoading, setIsLoading] = useState(false)

  const [ethAddress, setEthAddress] = useState("")
  const [bitcoinAddress, setBitcoinAddress] = useState("")

  const [openDialog, setOpenDialog] = useState(false)

  const [pages, setPages] = useState(0)
  const [api, setApi] = useState<CarouselApi>()

  const btcStakeRef = useRef<HTMLInputElement>(null)

  const [bodManagerAddress, setBodManagerAddress] = useState('');
  const [cdpAddress, setCdpAddress] = useState('');

  const [lockedBitcoin, setLockedBitcoin] = useState('0');
  const [stablecoinBalance, setStablecoinBalance] = useState('0');

  const scrollPrev = useCallback(() => {
    if (api) api.scrollPrev()
  }, [api])

  const scrollNext = useCallback(() => {
    if (api) api.scrollNext()
  }, [api])

  const storeEthAddress = useCallback(async () => {
    if (!primaryWallet) {
      console.log("wallet not connected");
      return;
    }

    await primaryWallet.connector.switchNetwork({
      networkName: "Holesky Testnet",
      networkChainId: 17000
    })

    setEthAddress(primaryWallet.address)
  }, [primaryWallet])

  // const sendPublicKey = useCallback(async () => {
  //   if (!primaryWallet || !isBitcoinWallet(primaryWallet)) {
  //     console.log("wallet not connected");
  //     return;
  //   }

  //   const addresses = await primaryWallet.additionalAddresses

  //   const firstAddress = addresses[0]
  //   const publicKey = firstAddress.publicKey

  //   setPublicKey(publicKey as string);

  //   const utxos = await getFundingUTXOs(firstAddress.address)

  //   console.log("utxos", utxos)
  //   const psbtraw = await generateDepositPSBT(firstAddress.address, "bc1qxshp5nyc6wnc9g3qx9ue3y98lafn4n6yan53aq", 0, utxos)
  //   console.log("psbt hex", psbtraw)

  //   // Define the parameters for signing the PSBT
  //   const params = {
  //     allowedSighash: [1], // Only allow SIGHASH_ALL
  //     unsignedPsbtBase64: psbtraw, // The unsigned PSBT in Base64 format
  //     signature: [
  //       {
  //         address: firstAddress.address, // The address that is signing
  //         signingIndexes: [0], // The index of the input being signed
  //       },
  //     ],
  //   };

  //   try {
  //     // Request the wallet to sign the PSBT
  //     const signedPsbt = await primaryWallet.signPsbt(params);
  //     console.log(signedPsbt); // Log the signed PSBT
  //   } catch (e) {
  //     console.error(e); // Handle any errors that occur during signing
  //   }



  // }, [primaryWallet])

  // const signDeposit = useCallback(async () => {
  //   if (!primaryWallet || !isBitcoinWallet(primaryWallet)) {
  //     console.log("wallet not connected");
  //     return;
  //   }

  //   const address = primaryWallet.address;

  // }, [primaryWallet])

  // const presignTransaction = useCallback(async () => {
  //   if (!primaryWallet || !isBitcoinWallet(primaryWallet)) {
  //     console.log("wallet not connected");
  //     return;
  //   }

  //   console.log(primaryWallet.additionalAddresses);

  //   const address = await primaryWallet.address;

  //   const psbt = generatePSBT(address, message);

  //   // Define the parameters for signing the PSBT
  //   const params = {
  //     allowedSighash: [1], // Only allow SIGHASH_ALL
  //     unsignedPsbtBase64: psbt, // The unsigned PSBT in Base64 format
  //     signature: [
  //       {
  //         address, // The address that is signing
  //         signingIndexes: [0], // The index of the input being signed
  //       },
  //     ],
  //   };

  //   try {
  //     // Request the wallet to sign the PSBT
  //     const signedPsbt = await primaryWallet.signPsbt(params);
  //     console.log(signedPsbt); // Log the signed PSBT
  //   } catch (e) {
  //     console.error(e); // Handle any errors that occur during signing
  //   }
  // }, [primaryWallet, message]);

  const deployBodManager = useCallback(async () => {
    if (!primaryWallet || !isEthereumWallet(primaryWallet)) return;

    setLoader1(true)
    const provider = new ethers.BrowserProvider(window.ethereum as Eip1193Provider);

    const signer = await provider.getSigner();

    setSigner(signer)
    setProvider(provider)
    await provider.send("eth_requestAccounts", []);
    const BodManagerFactory = new ethers.ContractFactory(BodManagerABI.abi, BodManagerABI.bytecode, signer);
    const bodManager = await BodManagerFactory.deploy();
    await bodManager.waitForDeployment();
    const address = await bodManager.getAddress();
    console.log("BodManager deployed at:", address);

    toast({
      title: "BodManager Deployed",
      description: `Deployed at ${address}`
    })
    setBodManagerAddress(address)

    setLoader1(false)

  }, [primaryWallet])

  const deployBod = useCallback((async () => {
    setLoader2(true)
    try {
      if (!signer) return;
      const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
      const tx = await bodManager.createBod(bitcoinAddress);
      await tx.wait();
      const userAddress = await signer.getAddress();
      const newBodAddress = await bodManager.getBod(userAddress);
      setBodAddress(newBodAddress);
      console.log("Bod deployed at:", newBodAddress);

      toast({
        title: "Bod Deployed",
        description: `Deployed at ${newBodAddress}`
      })
    } catch (error) {
      console.error("Error deploying Bod:", error);
    }

    setLoader2(false)
  }), [signer, provider, bodManagerAddress])

  const deployCDP = useCallback((async () => {
    setLoader4(true)
    try {
      if (!bodAddress) {
        console.error("Bod address not set. Please deploy a Bod first.");
        return;
      }

      if (!signer) return;

      // Check Bod kwnership
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


      toast({
        title: "CDP Deployed",
        description: `Deployed at ${address}`
      })

      const cdpContract = new ethers.Contract(address, CDPContractABI.abi, signer);

      let tx = await cdpContract.mintStablecoin(1000000000000000);
      await tx.wait();
      console.log("Stablecoin minted");
      toast({
        title: "BitC Minted",
        description: `Mint has succeeded`
      })
    } catch (error) {
      console.error("Error deploying CDP or minting stablecoin:", error);
    }

    setLoader4(false)
  }), [signer, provider, bodAddress])

  const getBalances = useCallback((async () => {

    setLoader5(true)
    try {
      if (!bodAddress || !cdpAddress) {
        console.error("Bod or CDP address not set. Please deploy both contracts first.");
        return;
      }

      if (!signer) return;
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

      toast({
        title: "Balanced Updated",
        description: `BitC balance and locked BTC balance has been updated`
      })
    } catch (error) {
      console.error("Error getting balances:", error);
    }

    setLoader5(false)
  }), [signer, provider, bodAddress, cdpAddress])

  const lockBitcoin = useCallback((async () => {
    try {
      if (!bodManagerAddress) {
        console.error("BodManager address not set. Please deploy BodManager first.");
        return;
      }

      setLoader3(true)
      console.log("Locking 0.01 BTC...");
      const bodManager = new ethers.Contract(bodManagerAddress, BodManagerABI.abi, signer);
      const amount = ethers.parseEther("0.01"); // 0.01 BTC
      const btcTxHash = ethers.hexlify(ethers.randomBytes(32)); // Simulating a Bitcoin transaction hash
      const tx = await bodManager.lockBitcoin(btcTxHash, amount);
      console.log("Transaction sent. Waiting for confirmation...");
      await tx.wait();
      console.log("0.01 BTC locked successfully");

      toast({
        title: "BTC Locked",
        description: "0.01 BTC Staked successfully"
      })
    } catch (error) {
      console.error("Error locking Bitcoin:", error);
    }

    setLoader3(false)
  }), [signer, provider, bodManagerAddress])

  function DialogPages() {
    switch (pages) {
      case 0: {
        return <div>
          <span className='text-lg font-semibold'>Choose an Operator</span>
          <Carousel
            opts={{
              loop: true,
              align: "start"
            }}
            setApi={setApi}
            className='w-[90%] p-1'
          >
            <CarouselContent>
              <CarouselItem
                onClick={() => {
                  setPages(1)
                }}
                className="basis-1/2 cursor-pointer"
              >
                <div className={'flex h-32 flex-col rounded-lg border bg-zinc-100 hover:bg-zinc-100/90 px-4 text-zinc-900'}>
                  <span className="text-lg font-semibold">
                    Operator Alpha
                  </span>
                  <span>Address: 0xb...b44</span>
                </div>
              </CarouselItem>
              {OPERATORS.map((operator) => (
                <CarouselItem
                  key={operator.name}
                  className="basis-1/2 cursor-not-allowed"
                >
                  <div className='flex h-32 flex-col rounded-lg border px-4 bg-zinc-100 opacity-80 text-zinc-900'>
                    <span className="text-lg font-semibold">
                      Operator {operator.name}
                    </span>
                    <span>Address: {operator.address}</span>
                  </div>
                </CarouselItem>
              ))}
            </CarouselContent>
          </Carousel>
          <div className='flex space-x-4'>
            <span
              onClick={() => scrollPrev()}
              className='cursor-pointer select-none hover:text-zinc-200'
            >Previous</span>
            <span
              className='cursor-pointer select-none hover:text-zinc-200'
              onClick={() => scrollNext()}
            >Next</span>
          </div>

        </div>
      }
      case 1: {
        return <div className='space-y-4'>
          <span className='text-lg font-semibold'>Verify Details</span>
          <div>
            <div>Selected: Operator Alpha</div>
            <div>Total Staked: {(1.69).toFixed(9)} BTC</div>
          </div>
          <Button
            className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 font-semibold'
            disabled={isLoading}
            onClick={async () => {
              try {

                setIsLoading(true)

                if (!primaryWallet || !isBitcoinWallet(primaryWallet)) {
                  console.log("wallet not connected");
                  throw "not btc network or connected"
                }

                const addresses = await primaryWallet.additionalAddresses

                const firstAddress = addresses[0]
                const publicKey = firstAddress.publicKey
                const btcAdd = firstAddress.address;

                setBitcoinAddress(btcAdd)
                setOpenDialog(false)

                // const address = await getBODAddress(publicKey as string, ethAddress)

                // if (!address) throw "error getting bod address"

                // saveBodAddress(address)
                // console.log("bodAddress", bodAddress)
              }
              catch (err) {

              }
              setIsLoading(false)
            }}>
            {
              isLoading ?
                <Loader2 className='animate-spin' />
                :
                <span>
                  Get Your BOD
                </span>
            }
          </Button>
        </div>
      }
      default: {
        return <></>
      }
    }
  }

  return (
    <div className="flex flex-col space-y-4 text-zinc-900">
      <DynamicWidget />
      <div className='h-[1px] w-full border-b' />
      <div className='space-y-1'>
        <h3 className='text-xl font-semibold'>Staking</h3>
        <div className='flex rounded-lg w-full bg-zinc-900 p-4 text-zinc-100 justify-between items-center'>
          <div className='space-y-2 flex flex-col'>
            <div className='flex flex-col'>
              <div className='flex space-x-2 items-center'>
                <Bitcoin className='w-4 h-4' />
                <span className='font-semibold'>Bitcoin</span>
              </div>
              <span className='text-sm'>Bitcoin Address:{bitcoinAddress}</span>
              <span className='text-sm'>BOD Address:{bodAddress}</span>
              <span className='text-sm'>BOD Manager Address:{bodManagerAddress}</span>
            </div>
            <div className='flex'>
              <Button
                disabled={
                  !primaryWallet
                }
                className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                onClick={() => {
                  setOpenDialog(true)
                }}
              >
                Create BOD
              </Button>

            </div>

          </div>
          <div className='flex space-x-4'>
            <div className='space-y-1 max-w-[200px] w-full'>
              <div>
                {lockedBitcoin}
              </div>
              <div className='font-semibold'>
                Staked
              </div>
            </div>

            <div className='space-y-1 max-w-[200px] w-full'>
              <div>
                {parseFloat(lockedBitcoin) > 0 ? "1000" : "0"}
              </div>
              <div className='font-semibold'>
                Points
              </div>
            </div>
          </div>
        </div>

      </div>
      <div className='flex rounded-lg w-full bg-zinc-100 p-4 text-zinc-900 border justify-between items-center'>
        <div className='space-y-2 flex flex-col'>
          <div className='flex flex-col'>
            <span className='font-semibold'>Ethereum</span>
            <div className='text-sm'>Ethereum Address: {ethAddress}</div>

            <span className='text-sm'>CDP Address:{cdpAddress}</span>
          </div>
          <div>
            <Button
              className='p-2 font-semibold'
              onClick={async () => {
                await storeEthAddress()
              }}

              disabled={
                !primaryWallet || !isEthereumWallet(primaryWallet)
              }
            >
              Submit Ethereum Address
            </Button>
          </div>

        </div>
        <div className='flex space-x-4'>
          <div className='space-y-1 max-w-[200px] w-full'>
            <div>
              {stablecoinBalance || "0"}
            </div>
            <div className='font-semibold'>
              BitC
            </div>
          </div>

        </div>
      </div>
      <div className='h-[1px] w-full border-b' />
      <div className='space-y-1'>
        <h3 className='text-xl font-semibold'>Your Stake</h3>

        <div className='grid grid-cols-2 w-full gap-x-4'>
          <div className='h-[400px] bg-zinc-900 rounded-lg flex flex-col text-zinc-100 p-4 '>
            {primaryWallet ? (
              <div className='flex flex-col gap-4'>
                <div className='space-y-1'>
                  <label className='font-semibold'>BTC To Stake: 0.1</label>
                </div>
                <Button
                  className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                  onClick={async () => {
                    await deployBodManager()
                  }}
                >
                  {

                    loader1 ?
                      <Loader2 className='animate-spin' />
                      :
                      <span>

                        Deploy BodManager
                      </span>
                  }
                </Button>
                <Button
                  className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                  onClick={async () => {
                    await deployBod()
                  }}
                >
                  {
                    loader2 ?
                      <Loader2 className='animate-spin' />
                      :
                      <span>

                        Deploy Bod
                      </span>
                  }
                </Button>
                <Button
                  className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                  onClick={async () => {
                    await lockBitcoin()
                  }}
                >
                  {
                    loader3 ?
                      <Loader2 className='animate-spin' />
                      :
                      <span>

                        Lock Bitcoin
                      </span>
                  }
                </Button>
                <Button
                  className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                  onClick={async () => {
                    await deployCDP()
                  }}
                >
                  {
                    loader4 ?
                      <Loader2 className='animate-spin' />
                      :
                      <span>
                        Deploy CDP
                      </span>
                  }
                </Button>
                <Button
                  className='bg-zinc-100 text-zinc-900 hover:bg-zinc-100/80 p-2 font-semibold'
                  onClick={async () => {
                    await getBalances()
                  }}
                >
                  {
                    loader5 ?
                      <Loader2 className='animate-spin' />
                      :
                      <span>
                        Refresh Balances
                      </span>
                  }
                </Button>
              </div>
            ) : <div className='text-center text-2xl'>
              <span>Connect your wallet</span>
            </div>
            }

          </div>
          <div className='h-[400px] rounded-lg border'>

          </div>
        </div>



      </div>
      {primaryWallet && (
        <>
          {/* <Button onClick={() => presignTransaction()}>Sign PSBT</Button> */}
          <Dialog open={openDialog} onOpenChange={setOpenDialog}>
            <DialogContent className="rounded-lg border-zinc-600 bg-zinc-950 overflow-hidden">
              <DialogHeader>
                <DialogTitle>BitDSM</DialogTitle>
              </DialogHeader>
              {DialogPages()}
            </DialogContent>
          </Dialog>
        </>
      )}

    </div>
  );
}

export default AppWrapper;
