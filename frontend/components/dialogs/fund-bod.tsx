
import { DialogViewKey } from '@/hooks/use-dialog-factory';
import { cn } from '@/lib/utils';
import React, { useMemo, useRef, useState } from 'react'
import Button from '../ui/button';
import { useWeb3React } from '@web3-react/core';
import { toast } from '@/hooks/use-toast';
import { OKXBitcoinSignet } from '@/types';
import { Input } from '../ui/input';
import { useLocalStore } from '@/lib/providers/store-provider';
import { fundPod, verifyBTCTransactionHash } from '@/lib/bod';
import Link from 'next/link';
import BTC from '@/lib/denoms';
import Big from 'big.js';
import { Loader2 } from 'lucide-react';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

function FundBODDialog({
  setView,
  className,
}: Props) {

  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);
  const updateBitcoinPod = useLocalStore((state) => state.global.updateBitcoinPod);

  const {
    provider,
    account,
  } = useWeb3React()

  const [loading, setLoading] = useState(false)

  const amountRef = useRef<HTMLInputElement>(null)

  const [amount, setAmount] = useState("0.0001")

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [bitcoinPods, account])

  return (
    <div className={cn('space-y-4', className)}>
      <div className='space-y-1'>
        <label htmlFor='amount' className='text-sm'>Deposit Amount (BTC)</label>
        <Input
          id='amount'
          type="text"
          onChange={(e) => {
            const value = e.target.value.replace(/[^0123456789.]/g, "");
            const dotCount =
              e.target.value.length - value.replaceAll(".", "").length;

            if (dotCount > 1) {
              return;
            }

            setAmount(value)
          }}
          ref={amountRef}
          placeholder="0.00001"
          value={amount}
        />
      </div>


      <Button onClick={async () => {
        if (!provider || !provider.provider || !account) {
          toast({
            title: "Please make sure you have OKX wallet installed.",
            description: "OKX Wallet is required to stake your BTC to BitDSM.",
          });
          return;
        }

        const okxSignet = provider.provider as OKXBitcoinSignet

        if (!okxSignet.bitcoinSignet) {
          toast({
            title: "Bitcoin network not supported",
            description: "Please make sure your OKX wallet has Bitcoin network enabled.",
          });
          return;
        }

        setLoading(true)

        const pod = pods[0]

        try {
          await okxSignet.bitcoinSignet.connect();

          const sats = new BTC("BTC", Big(amountRef.current?.value || "0")).convert("sats").toNumber()

          const txHash = await okxSignet.bitcoinSignet.sendBitcoin(pod.btcAddress, sats, {
            feeRate: 6,
          })

          console.log("sendBitcoinResult", txHash);

          const verified = await verifyBTCTransactionHash(txHash)
          console.log("verified", verified)

          if (!verified) {
            toast({
              title: "Deposit failed",
              description: "Sorry the deposit was not detected on the Bitcoin network. Please try again.",
              variant: "destructive",
            })
            setLoading(false)
            return
          }

          const fundPodResult = await fundPod(pod.ethPodAddress, txHash, sats.toString())
          console.log("fundPodResult", fundPodResult)

          toast({
            title: "Deposit successful",
            description: <>Your BTC has been deposited to your BOD.<Link href={`https://holesky.etherscan.io/tx/${txHash}`} target='_blank'>View on Explorer</Link></>,
          });

          updateBitcoinPod(account, {
            ...pod,
            sats: sats.toString(),
            depositTxHash: txHash,
          })

          setView('fundedBod')

        }
        catch (error) {
          console.error(error)
          toast({
            title: "Deposit failed",
            description: "Sorry the deposit failed to complete due to an unexpected error.",
            variant: "destructive",
          })
        }

        setLoading(false)

      }}>
        {loading ? <Loader2 className='w-4 h-4 animate-spin' /> : <>Deposit BTC</>}
      </Button>

    </div>
  )
}

export default FundBODDialog
