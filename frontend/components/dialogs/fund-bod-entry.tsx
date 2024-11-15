import { DialogViewKey } from '@/hooks/use-dialog-factory';
import { cn, truncateAddress } from '@/lib/utils';
import React, { useMemo } from 'react'
import { useWeb3React } from '@web3-react/core';
import { useLocalStore } from '@/lib/providers/store-provider';
import BTC from '@/lib/denoms';
import Big from 'big.js';
import { Table, TableHeader, TableHead, TableRow, TableBody, TableCell } from '../ui/table';
import { toast } from '@/hooks/use-toast';
import { getPodBitcoinBalance } from '@/lib/bod';
import { useQuery } from '@tanstack/react-query';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

function FundBODEntryDialog({
  setView,
  className,
}: Props) {

  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);

  const {
    account,
  } = useWeb3React()

  const pods = useMemo(() => {
    return account ? bitcoinPods[account.toLowerCase()] : []
  }, [bitcoinPods, account])

  const query = useQuery({ queryKey: ['bods-balance', pods[0]], queryFn: () => getPodBitcoinBalance(pods[0].ethPodAddress), refetchInterval: 15000 })

  return (
    <div className={cn('space-y-4', className)}>
      <div>
        By funding a BOD, you are able to delegate your BTC in your BOD to an App and earn rewards.
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
                      description: "You cannot fund a BOD that has already been delegated.",
                    })
                    return;
                  }

                  if (query.data || pod.depositTxHash) {
                    toast({
                      title: "BOD already funded",
                      description: "You cannot fund a BOD that has already been funded.",
                    })
                    return;
                  }
                  setView("fundBod")
                }} className={'hover:bg-white cursor-pointer'} key={pod.ethPodAddress}>
                  <TableCell className="font-medium">{`${truncateAddress(pod.ethPodAddress)}`}</TableCell>
                  <TableCell>{truncateAddress(pod.btcAddress)}</TableCell>
                  <TableCell>{`${new BTC("sats", Big(query.data || "0")).convert("BTC").toString()} BTC`}</TableCell>
                  <TableCell>{pod.operator ? pod.operator : "Chorus"}</TableCell>
                  <TableCell>{pod.delegated ? "True" : "False"}</TableCell>
                </TableRow>
              ))
            })()}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}

export default FundBODEntryDialog
