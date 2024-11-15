import BodManagerABI from "@/lib/abis/BitcoinPodManager.json";
import BodABI from "@/lib/abis/BitcoinPod.json";
import { BitcoinPodManager } from "@/types/contracts/BitcoinPodManager";

import { Eip1193Provider, ethers, toBigInt } from "ethers";
import { BitcoinPod } from "@/types/contracts";
import { address } from "bitcoinjs-lib";
import { Operator } from "@/types";

const BITCOIN_POD_MANAGER_ADDRESS = process.env
  .NEXT_PUBLIC_BITCOIN_POD_MANAGER_ADDRESS as string;

function bech32ToHex(bech32Address: string) {
  const data = address.fromBech32(bech32Address).data;
  return Buffer.from(data).toString("hex");
}

export async function getOperators() {
  const response = await fetch("/api/operators");
  const result = await response.json();
  return result as Operator[];
}

export async function createBitcoinMultisigAddress(
  btcPublicKey: string,
  operatorId: string
) {
  const response = await fetch(`/api/operators/${operatorId}`, {
    method: "POST",
    body: JSON.stringify({
      method: "get_address",
      body: { pubKey: btcPublicKey },
    }),
  });

  const result = (await response.json()) as {
    newAddress: string;
    addressHex: string;
  };

  return result;
}

export async function createPOD(
  operatorAddress: string,
  btcAddressHex: string
) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);
  console.log("bitcoin pod manager", BITCOIN_POD_MANAGER_ADDRESS);

  const BodManager = new ethers.Contract(
    BITCOIN_POD_MANAGER_ADDRESS,
    BodManagerABI,
    signer
  ) as unknown as BitcoinPodManager;

  const btcAddress = btcAddressHex;

  const btcAddressAsBytes = ethers.getBytes("0x" + btcAddress);
  const tx = await BodManager.createPod(operatorAddress, btcAddressAsBytes);

  const receipt = await tx.wait();

  const foundLog = receipt?.logs.find((log) => {
    const eventLog = log as ethers.EventLog;

    if (!eventLog.fragment) return;

    if (eventLog.fragment.name !== "PodCreated") return;

    return true;
  }) as ethers.EventLog | undefined;

  if (!foundLog) return { podAddress: "", txHash: "" };

  const podAddress = foundLog.args[1];

  return { podAddress, txHash: foundLog?.transactionHash };
}

async function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function verifyBTCTransactionHash(txHash: string) {
  const maxAttempts = 10;
  const delayMs = 5000;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      const response = await fetch(
        `https://mempool.space/signet/api/tx/${txHash}`
      );

      if (response.status === 200) return true;

      if (attempt < maxAttempts - 1) {
        await delay(delayMs);
      }
    } catch (err) {
      console.error(`Attempt ${attempt + 1} failed:`, err);
      if (attempt < maxAttempts - 1) {
        await delay(delayMs);
      }
    }
  }

  return false;
}

/**
 *
 * @param txHash
 * @param amount sats
 */
export async function fundPod(
  bodAddress: string,
  txHash: string,
  amount: string
) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);

  const BodManager = new ethers.Contract(
    BITCOIN_POD_MANAGER_ADDRESS,
    BodManagerABI,
    signer
  ) as unknown as BitcoinPodManager;

  const txHashInBytes = ethers.getBytes("0x" + txHash);

  console.log(bodAddress);

  const tx = await BodManager.verifyBitcoinDepositRequest(
    bodAddress,
    txHashInBytes,
    toBigInt(amount)
  );

  const receipt = await tx.wait();

  const foundLog = receipt?.logs.find((log) => {
    const eventLog = log as ethers.EventLog;

    if (!eventLog.fragment) return;

    if (eventLog.fragment.name !== "VerifyBitcoinDepositRequest") return;

    return true;
  });

  console.log("fundPodResult", foundLog);
  return foundLog?.transactionHash;
}

export async function withdrawFromPod(
  podAddress: string,
  withdrawAddress: string
) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);

  const BodManager = new ethers.Contract(
    BITCOIN_POD_MANAGER_ADDRESS,
    BodManagerABI,
    signer
  ) as unknown as BitcoinPodManager;

  const btcAddressHex = await bech32ToHex(withdrawAddress);

  const btcAddressAsBytes = ethers.getBytes("0x" + btcAddressHex);

  const tx = await BodManager.withdrawBitcoinPSBTRequest(
    podAddress,
    btcAddressAsBytes
  );

  const receipt = await tx.wait();

  const foundLog = receipt?.logs.find((log) => {
    const eventLog = log as ethers.EventLog;

    if (!eventLog.fragment) return;

    if (eventLog.fragment.name !== "BitcoinWithdrawalPSBTRequest") return;

    return true;
  });

  return foundLog?.transactionHash;
}

export async function getAndSubmitBitcoinWithdrawPSBT(podAddress: string) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const signer = await provider.getSigner();
  await provider.send("eth_requestAccounts", []);

  console.log("podAddress", podAddress);
  const Bod = new ethers.Contract(
    podAddress,
    BodABI,
    signer
  ) as unknown as BitcoinPod;

  const psbt = await Bod.getSignedBitcoinWithdrawTransaction();

  return psbt;
}

export async function getPodBitcoinBalance(podAddress: string) {
  const provider = new ethers.BrowserProvider(
    window.okxwallet as Eip1193Provider
  );

  const Bod = new ethers.Contract(
    podAddress,
    BodABI,
    provider
  ) as unknown as BitcoinPod;

  const balance = await Bod.getBitcoinBalance();

  return Number(balance);
}
