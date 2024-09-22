import { UTXO } from "@/app/types";
import {
  buildPsbt,
  networks,
  utxoInput,
  utxoOutput,
  utxoTx,
} from "@okxweb3/coin-bitcoin";

import * as bitcoin from "bitcoinjs-lib";

export async function getFundingUTXOs(
  address: string,
  amount?: number
): Promise<UTXO[]> {
  // Get all UTXOs for the given address

  let utxos = null;
  try {
    const response = await fetch(
      new URL(`https://mempool.space/api/address/${address}/utxo`)
    );
    utxos = await response.json();
  } catch (error: Error | any) {
    throw new Error(error?.message || error);
  }

  const confirmedUTXOs = utxos
    .filter((utxo: any) => utxo.status.confirmed)
    .sort((a: any, b: any) => b.value - a.value);

  let sliced = confirmedUTXOs;
  if (amount) {
    var sum = 0;
    for (var i = 0; i < confirmedUTXOs.length; ++i) {
      sum += confirmedUTXOs[i].value;
      if (sum > amount) {
        break;
      }
    }
    if (sum < amount) {
      return [];
    }
    sliced = confirmedUTXOs.slice(0, i + 1);
  }

  const response = await fetch(
    `https://mempool.space/api/v1/validate-address/${address}`
  );
  const addressInfo = await response.json();
  const { isvalid, scriptPubKey } = addressInfo;
  if (!isvalid) {
    throw new Error("Invalid address");
  }

  // Iterate through the final list of UTXOs to construct the result list.
  // The result contains some extra information,
  return sliced.map((s: any) => {
    return {
      txid: s.txid,
      vout: s.vout,
      value: s.value,
      scriptPubKey: scriptPubKey,
    };
  });
}
