"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const ethers_1 = require("ethers");
const dotenv = __importStar(require("dotenv"));
const fs = require('fs');
const path = require('path');
dotenv.config();
// Check if the process.env object is empty
if (!Object.keys(process.env).length) {
    throw new Error("process.env object is empty");
}
// Setup env variables
const provider = new ethers_1.ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers_1.ethers.Wallet(process.env.PRIVATE_KEY, provider);
/// TODO: Hack
let chainId = 31337;
const avsDeploymentData = JSON.parse(fs.readFileSync(path.resolve(__dirname, `../contracts/deployments/hello-world/${chainId}.json`), 'utf8'));
// Load core deployment data
const coreDeploymentData = JSON.parse(fs.readFileSync(path.resolve(__dirname, `../contracts/deployments/core/${chainId}.json`), 'utf8'));
const delegationManagerAddress = coreDeploymentData.addresses.delegation; // todo: reminder to fix the naming of this contract in the deployment file, change to delegationManager
const avsDirectoryAddress = coreDeploymentData.addresses.avsDirectory;
const helloWorldServiceManagerAddress = avsDeploymentData.addresses.helloWorldServiceManager;
const ecdsaStakeRegistryAddress = avsDeploymentData.addresses.stakeRegistry;
// Load ABIs
const delegationManagerABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/IDelegationManager.json'), 'utf8'));
const ecdsaRegistryABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/ECDSAStakeRegistry.json'), 'utf8'));
const helloWorldServiceManagerABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/HelloWorldServiceManager.json'), 'utf8'));
const avsDirectoryABI = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../abis/IAVSDirectory.json'), 'utf8'));
// Initialize contract objects from ABIs
const delegationManager = new ethers_1.ethers.Contract(delegationManagerAddress, delegationManagerABI, wallet);
const helloWorldServiceManager = new ethers_1.ethers.Contract(helloWorldServiceManagerAddress, helloWorldServiceManagerABI, wallet);
const ecdsaRegistryContract = new ethers_1.ethers.Contract(ecdsaStakeRegistryAddress, ecdsaRegistryABI, wallet);
const avsDirectory = new ethers_1.ethers.Contract(avsDirectoryAddress, avsDirectoryABI, wallet);
const signAndRespondToTask = (taskIndex, taskCreatedBlock, taskName) => __awaiter(void 0, void 0, void 0, function* () {
    const message = `Hello, ${taskName}`;
    const messageHash = ethers_1.ethers.solidityPackedKeccak256(["string"], [message]);
    const messageBytes = ethers_1.ethers.getBytes(messageHash);
    const signature = yield wallet.signMessage(messageBytes);
    console.log(`Signing and responding to task ${taskIndex}`);
    const tx = yield helloWorldServiceManager.respondToTask({ name: taskName, taskCreatedBlock: taskCreatedBlock }, taskIndex, signature);
    yield tx.wait();
    console.log(`Responded to task.`);
});
const registerOperator = () => __awaiter(void 0, void 0, void 0, function* () {
    // Registers as an Operator in EigenLayer.
    try {
        const tx1 = yield delegationManager.registerAsOperator({
            __deprecated_earningsReceiver: yield wallet.address,
            delegationApprover: "0x0000000000000000000000000000000000000000",
            stakerOptOutWindowBlocks: 0
        }, "");
        yield tx1.wait();
        console.log("Operator registered to Core EigenLayer contracts");
    }
    catch (error) {
        console.error("Error in registering as operator:", error);
    }
    const salt = ethers_1.ethers.hexlify(ethers_1.ethers.randomBytes(32));
    const expiry = Math.floor(Date.now() / 1000) + 3600; // Example expiry, 1 hour from now
    // Define the output structure
    let operatorSignatureWithSaltAndExpiry = {
        signature: "",
        salt: salt,
        expiry: expiry
    };
    // Calculate the digest hash, which is a unique value representing the operator, avs, unique value (salt) and expiration date.
    console.log(wallet.address);
    console.log(yield helloWorldServiceManager.getAddress());
    console.log(salt, "salt");
    console.log(expiry, "expiry");
    const operatorDigestHash = yield avsDirectory.calculateOperatorAVSRegistrationDigestHash(wallet.address, yield helloWorldServiceManager.getAddress(), salt, expiry);
    console.log(operatorDigestHash);
    // Sign the digest hash with the operator's private key
    console.log("Signing digest hash with operator's private key");
    const operatorSigningKey = new ethers_1.ethers.SigningKey(process.env.PRIVATE_KEY);
    const operatorSignedDigestHash = operatorSigningKey.sign(operatorDigestHash);
    // Encode the signature in the required format
    operatorSignatureWithSaltAndExpiry.signature = ethers_1.ethers.Signature.from(operatorSignedDigestHash).serialized;
    console.log("Registering Operator to AVS Registry contract");
    //Debugging
    console.log('operatorSignatureWithSaltAndExpiry before processing:', operatorSignatureWithSaltAndExpiry);
    console.log('wallet.address before processing:', wallet.address);
    // Register Operator to AVS
    // Per release here: https://github.com/Layr-Labs/eigenlayer-middleware/blob/v0.2.1-mainnet-rewards/src/unaudited/ECDSAStakeRegistry.sol#L49
    const tx2 = yield ecdsaRegistryContract.registerOperatorWithSignature(operatorSignatureWithSaltAndExpiry, wallet.address);
    yield tx2.wait();
    console.log("Operator registered on AVS successfully");
});
const monitorNewTasks = () => __awaiter(void 0, void 0, void 0, function* () {
    console.log(`Creating new task "EigenWorld"`);
    yield helloWorldServiceManager.createNewTask("EigenWorld");
    helloWorldServiceManager.on("NewTaskCreated", (taskIndex, task) => __awaiter(void 0, void 0, void 0, function* () {
        console.log(`New task detected: Hello, ${task.name}`);
        yield signAndRespondToTask(taskIndex, task.taskCreatedBlock, task.name);
    }));
    console.log("Monitoring for new tasks...");
});
const main = () => __awaiter(void 0, void 0, void 0, function* () {
    yield registerOperator();
    monitorNewTasks().catch((error) => {
        console.error("Error monitoring tasks:", error);
    });
});
main().catch((error) => {
    console.error("Error in main function:", error);
});
