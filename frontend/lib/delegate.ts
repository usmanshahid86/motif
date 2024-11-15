import { ethers } from "ethers";
import { Eip1193Provider } from "ethers";
import { BitcoinPodManager } from "@/types/contracts";
import BitcoinPodManagerABI from "@/lib/abis/BitcoinPodManager.json";

const BITCOIN_POD_MANAGER_ADDRESS = process.env
  .NEXT_PUBLIC_BITCOIN_POD_MANAGER_ADDRESS as string;

export async function delegateBod(podAddress: string, appAddress: string) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);

  const BitcoinPodManager = new ethers.Contract(
    BITCOIN_POD_MANAGER_ADDRESS,
    BitcoinPodManagerABI,
    signer
  ) as unknown as BitcoinPodManager;

  const tx = await BitcoinPodManager.delegatePod(podAddress, appAddress);

  const receipt = await tx.wait();

  console.log(receipt);
  return receipt?.hash;
}

export async function undelegateBod(podAddress: string) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);

  const BitcoinPodManager = new ethers.Contract(
    BITCOIN_POD_MANAGER_ADDRESS,
    BitcoinPodManagerABI,
    signer
  ) as unknown as BitcoinPodManager;

  const tx = await BitcoinPodManager.undelegatePod(podAddress);

  const receipt = await tx.wait();
  console.log(receipt);
  return receipt?.hash;
}
