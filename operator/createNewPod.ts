import { ethers } from "ethers";
import * as dotenv from "dotenv";
const fs = require('fs');
const path = require('path');
dotenv.config();

// Check if the process.env object is empty
if (!Object.keys(process.env).length) {
    throw new Error("process.env object is empty");
}
// display the process.env object
console.log(process.env);
// Setup env variables
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.CLIENT_PRIVATE_KEY!, provider);
/// TODO: Hack
let chainId = 17000;

const avsDeploymentData = JSON.parse(
  fs.readFileSync(path.resolve(__dirname, `../bitdsm_addresses.json`), "utf8")
);
const bitDSMPodMangerAddress = avsDeploymentData.BitcoinPodManagerProxy;
const bitDSMPodMangerABI = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, "../abis/BitDSMPodManager.json"),
    "utf8"
  )
);
// Initialize contract objects from ABIs
const BodManager = new ethers.Contract(
  bitDSMPodMangerAddress,
  bitDSMPodMangerABI,
  wallet
);


// Function to generate random names
function generateRandomName(): string {
    const adjectives = ['Quick', 'Lazy', 'Sleepy', 'Noisy', 'Hungry'];
    const nouns = ['Fox', 'Dog', 'Cat', 'Mouse', 'Bear'];
    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const noun = nouns[Math.floor(Math.random() * nouns.length)];
    const randomName = `${adjective}${noun}${Math.floor(Math.random() * 1000)}`;
    return randomName;
  }

  async function createNewPod(): Promise<string> {
    try {
      const tx = await BodManager.createPod(wallet.address, "0x965d5c75ae6c7a68761e6f9cf2657363bd97f11fc6727410adacd7f81368541b");
      const receipt = await tx.wait();
      return receipt.logs[0].args.pod;
    } catch (error) {
      console.error('Error sending transaction:', error);
      throw error; // Add this line to properly handle errors
    }
  }


  async function verifyBitcoinDeposit(
    podAddr: string,
    txHash: string,
    amount: number,
): Promise<void> {
  try {
    const tx = await BodManager.verifyBitcoinDepositRequest(
      podAddr,
      txHash,
      amount
    );
    const receipt = await tx.wait();
  } catch (error) {
    console.error('Error sending transaction:', error); // Add this line to properly handle errors
  }
}

// Example usage:
// await verifyBitcoinDeposit(
//     "0x3fab0a58446da7a0703c0856a7c05abfa5a0f964",
//     "0xcFd4E3033436f838d0e0f677DdB7ce3213db5d5A",
//     "0xf21abe91dc7751516e22059abe925df95fa19a63669ed8a5b31f53312c3b59af",
//     10000,
//     provider,
//     "cc0feedf5de50d545ee4428ab54300c715265470be4d9f338336a87c54d31a45"
// );

// Function to create a new task with a random name every 15 seconds
async function CreatePodandDeposit() {
   let podAddress = await createNewPod();
   await verifyBitcoinDeposit(podAddress, "0xf21abe91dc7751516e22059abe925df95fa19a63669ed8a5b31f53312c3b59af", 10000);
}

// Start the process
CreatePodandDeposit();