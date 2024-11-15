
import { DialogViewKey } from '@/hooks/use-dialog-factory';
import { cn, truncateAddress } from '@/lib/utils';
import React, { useMemo, useState } from 'react'
import { useWeb3React } from '@web3-react/core';
import { useLocalStore } from '@/lib/providers/store-provider';
import BTC from '@/lib/denoms';
import Big from 'big.js';
import Button from '../ui/button';
import { Loader2 } from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import { BitcoinPod, OKXBitcoinSignet } from '@/types';
import { getAndSubmitBitcoinWithdrawPSBT, getPodBitcoinBalance, withdrawFromPod } from '@/lib/bod';
import { Table, TableHeader, TableBody, TableCell, TableHead, TableRow } from '../ui/table';
import { useQuery } from '@tanstack/react-query';
import { Checkbox } from '../ui/checkbox';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

async function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function WithdrawEntryDialog({
  setView,
  className,
}: Props) {
  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);

  const [selectedPod, setSelectedPod] = useState<BitcoinPod | null>(null)

  const {
    account,
    provider
  } = useWeb3React()

  const [loading, setLoading] = useState(false)

  const pods = useMemo(() => {
    return account ? bitcoinPods[account.toLowerCase()] : []
  }, [bitcoinPods, account])

  const query = useQuery({ queryKey: ['bods-balance', pods[0]], queryFn: () => getPodBitcoinBalance(pods[0].ethPodAddress), refetchInterval: 15000 })

  const updateBitcoinPod = useLocalStore((state) => state.global.updateBitcoinPod)

  return (
    <div className={cn('space-y-4', className)}>
      <div>
        Withdraw your BTC from your funded BODs. You are unable to withdraw from delegated BODs!
      </div>

      <div className='max-h-[200px] overflow-hidden px-0.5 py-2'>
        <Table>
          <TableHeader className="sticky top-0 bg-background z-10">
            <TableRow>
              <TableHead className="w-[120px]">Bod</TableHead>
              <TableHead>BTC Addr</TableHead>
              <TableHead>Balance</TableHead>
              <TableHead>Operator</TableHead>
              <TableHead>Delegated</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody className="overflow-y-auto">
            {(() => {
              return pods.map((pod) => (
                <TableRow onClick={() => {
                  if (pod.delegated) {
                    toast({
                      title: "BOD already delegated",
                      description: "You cannot withdraw from a BOD that has already been delegated.",
                    })
                    return;
                  }

                  if (!query.data) {
                    toast({
                      title: "BOD has no balance",
                      description: "You cannot withdraw from a BOD that has no balance.",
                    })
                    return;
                  }

                  if (selectedPod?.ethPodAddress === pod.ethPodAddress) {
                    setSelectedPod(null)
                    return;
                  }

                  setSelectedPod(pod)
                }} className={cn('hover:bg-white cursor-pointer', selectedPod?.ethPodAddress === pod.ethPodAddress && 'bg-white')} key={pod.ethPodAddress}>
                  <TableCell className="font-medium">{truncateAddress(pod.ethPodAddress)}</TableCell>
                  <TableCell>{truncateAddress(pod.btcAddress)}</TableCell>
                  <TableCell>{`${new BTC("sats", Big(query.data || "0")).convert("BTC").toString()} BTC`}</TableCell>
                  <TableCell>{pod.operator ? pod.operator : "Chorus"}</TableCell>
                  <TableCell>{pod.delegated ? "True" : "False"}</TableCell>
                  <TableCell><Checkbox checked={selectedPod?.ethPodAddress === pod.ethPodAddress} /></TableCell>
                </TableRow>
              ))
            })()}
          </TableBody>
        </Table>
      </div>


      <Button disabled={!selectedPod} onClick={async () => {
        setLoading(true)

        if (!selectedPod) {
          toast({
            title: "No BOD selected",
            description: "Please select a BOD to withdraw from.",
          })
          return;
        }

        if (selectedPod?.withdrawTxHash) {
          toast({
            title: "BOD already withdrawn",
            description: "You cannot withdraw from a BOD that is currently being withdrawn.",
          })
          return;
        }

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

        const {
          address,
          publicKey
        } = await okxSignet.bitcoinSignet.connect()

        try {
          console.log(address)
          console.log("pubkey:", publicKey)

          const result = await withdrawFromPod(selectedPod.ethPodAddress, address)

          if (
            !result
          ) {
            toast({
              title: "Error withdrawing from BOD",
              description: "An error occurred while withdrawing from the BOD.",
              variant: "destructive"
            })
            return
          }

          console.log(result)

          await delay(30000)

          const psbt = await getAndSubmitBitcoinWithdrawPSBT(selectedPod.ethPodAddress)

          console.log(psbt.slice(2))

          const psbtResult = await okxSignet.bitcoinSignet.signPsbt(psbt.slice(2), {
            autoFinalized: true,
            toSignInputs: [{
              index: 0,
              publicKey: publicKey,
            }]
          })

          console.log("psbtResult", psbtResult)

          const txHash = await okxSignet.bitcoinSignet.pushPsbt(psbtResult)
          console.log(txHash)

          updateBitcoinPod(account, {
            ...selectedPod,
            withdrawTxHash: txHash,
            sats: "0"
          })

          setView("withdrawCompleted")
        }
        catch (error) {
          console.error(error)
          toast({
            title: "Error withdrawing from BOD",
            description: "An error occurred while withdrawing from the BOD.",
            variant: "destructive"
          })
        }

        setLoading(false)


      }}>
        {loading ? <Loader2 className='animate-spin' /> : "Withdraw"}
      </Button>

    </div >
  )
}

export default WithdrawEntryDialog
