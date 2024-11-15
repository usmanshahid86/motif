export type BitcoinPod = {
  btcAddress: string;
  btcAddressHex: string;
  ethPodAddress: string;
  sats: string;
  delegated: boolean;
  delegatedApp: string;
  txHash: string;
  operator?: string;
  depositTxHash?: string;
  withdrawTxHash?: string;
};

export type Operator = {
  id: string;
  name: string;
  address: string;
  tvl: string;
  link: string;
};

export interface OKXBitcoinSignet {
  bitcoinSignet?: {
    connect: () => Promise<{
      address: string;
      compressedPublicKey: string;
      publicKey: string;
    }>;
    sendBitcoin: (
      toAddress: string,
      satoshis: number,
      options?: {
        feeRate?: number;
      }
    ) => Promise<string>;
    signPsbt: (
      psbt: string,
      options?: {
        autoFinalized?: boolean;
        toSignInputs?: Array<{
          index: number;
          address?: string;
          publicKey?: string;
          sighashTypes?: number[];
          disableTweakSigner?: boolean;
        }>;
      }
    ) => Promise<string>;
    pushPsbt: (psbtHex: string) => Promise<string>;
  };
}
