import * as bitcoin from "bitcoinjs-lib";
import { hexToBytes, utf8ToBytes } from "@stacks/common";
import { sha256 } from "@noble/hashes/sha256";
import ecc from "@bitcoinerlab/secp256k1";
import { BtcWallet } from "@okxweb3/coin-bitcoin";
import { UTXO } from "@/app/types";

bitcoin.initEccLib(ecc);

const bip322MessageTag = "BIP0322-signed-message";

const messageTagHash = Uint8Array.from([
  ...sha256(utf8ToBytes(bip322MessageTag)),
  ...sha256(utf8ToBytes(bip322MessageTag)),
]);

function isString(value: unknown) {
  return typeof value === "string";
}

function hashBip322Message(message: Uint8Array | string) {
  return sha256(
    Uint8Array.from([
      ...messageTagHash,
      ...(isString(message) ? utf8ToBytes(message) : message),
    ])
  );
}

const bip322TransactionToSignValues = {
  prevoutHash: hexToBytes(
    "0000000000000000000000000000000000000000000000000000000000000000"
  ),
  prevoutIndex: 0xffffffff,
  sequence: 0,
};

export function generatePSBT(address: string, message: string) {
  const { prevoutHash, prevoutIndex, sequence } = bip322TransactionToSignValues;

  // Generate the script for the given address
  const script = bitcoin.address.toOutputScript(
    address,
    bitcoin.networks.bitcoin
  );

  // Hash the message
  const hash = hashBip322Message(message);

  // Create the scriptSig with the hashed message
  const commands = [0, Buffer.from(hash)];
  const scriptSig = bitcoin.script.compile(commands);

  // Create a virtual transaction to spend
  const virtualToSpend = new bitcoin.Transaction();
  virtualToSpend.version = 0;
  virtualToSpend.addInput(
    Buffer.from(prevoutHash),
    prevoutIndex,
    sequence,
    scriptSig
  );
  virtualToSpend.addOutput(script, BigInt(0));

  // Create the PSBT
  const virtualToSign = new bitcoin.Psbt({ network: bitcoin.networks.bitcoin });
  virtualToSign.setVersion(0);
  const prevTxHash = virtualToSpend.getHash();
  const prevOutIndex = 0;
  const toSignScriptSig = bitcoin.script.compile([
    bitcoin.script.OPS.OP_RETURN,
  ]);

  try {
    virtualToSign.addInput({
      hash: prevTxHash,
      index: prevOutIndex,
      sequence: 0,
      witnessUtxo: { script, value: BigInt(0) },
    });
  } catch (e) {
    console.log(e);
    throw e;
  }

  virtualToSign.addOutput({ script: toSignScriptSig, value: BigInt(0) });
  return virtualToSign.toBase64();
}

export function generateDepositPSBT(
  sender: string,
  receiver: string,
  amount: number,
  utxos: UTXO[]
) {
  // get first utxo as a test
  const { txid, vout: prevoutIndex } = utxos[0];

  const prevoutHash = hexToBytes(txid);
  const sequence = 4294967293;

  // Generate the script for the given address
  const script = bitcoin.address.toOutputScript(
    sender,
    bitcoin.networks.bitcoin
  );

  // Hash the message
  const hash = hashBip322Message("deposit");

  // Create the scriptSig with the hashed message
  const commands = [1, Buffer.from(hash)];

  const scriptSig = bitcoin.script.compile(commands);

  // Create a virtual transaction to spend
  const virtualToSpend = new bitcoin.Transaction();

  virtualToSpend.version = 1;

  virtualToSpend.addInput(
    Buffer.from(prevoutHash),
    prevoutIndex,
    sequence,
    scriptSig
  );

  virtualToSpend.addOutput(script, BigInt(1));

  // Create the PSBT
  const virtualToSign = new bitcoin.Psbt({ network: bitcoin.networks.bitcoin });
  virtualToSign.setVersion(2);
  const prevTxHash = virtualToSpend.getHash();
  const prevOutIndex = prevoutIndex;
  console.log("script ops", bitcoin.script.OPS);
  const toSignScriptSig = bitcoin.script.compile([
    bitcoin.script.OPS.OP_DUP,
    bitcoin.script.OPS.OP_HASH160,
  ]);

  try {
    virtualToSign.addInput({
      hash: prevTxHash,
      index: prevOutIndex,
      sequence: 0,
      witnessUtxo: { script, value: BigInt(1) },
    });
  } catch (e) {
    console.log(e);
    throw e;
  }

  virtualToSign.addOutput({ script: toSignScriptSig, value: BigInt(1) });
  return virtualToSign.toBase64();
}

export async function getBODAddress(btcPubKey: string, ethAddress: string) {
  try {
    const payload = {
      jsonrpc: "2.0",
      method: "rpc.SubmitBtcPubkey",
      params: [
        {
          BTCPubKey: btcPubKey,
          EthAddr: ethAddress,
        },
      ],
      id: 1,
    };
    const response = await fetch("http://64.227.119.143:1234/rpc", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const result = (await response.json()) as {
      // this is the BOD address
      result: string;
      error?: string;
      id: number;
    };

    if (!result.result) return "";

    return result.result;
  } catch (err) {
    console.error(err);
    return "";
  }
}
