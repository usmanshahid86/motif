import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'
import { cn } from '@/lib/utils';
import Link from 'next/link';
import { useMemo } from 'react';
import { useLocalStore } from '@/lib/providers/store-provider';
import { useWeb3React } from '@web3-react/core';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  close: () => void;
  className?: string;
}

function WithdrawCompletedDialog({
  close,
  className,
}: Props) {

  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);

  const { account } = useWeb3React()

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  const pod = pods[0];

  return (
    <div className={cn('space-y-8', className)}>

      <div className='space-y-4'>
        <div>
          <p>{`Your Bitcoin is being withdrawn from the BOD. Once the transaction is confirmed, you will receive the funds to your Bitcoin Wallet.`}</p>
          <Link className='hover:underline' target="_blank" href={`https://mempool.space/signet/tx/${pod.withdrawTxHash}`}>View on Mempool</Link>
        </div>

        <Button className='w-full' onClick={() => close()}>Close</Button>
      </div>
    </div>
  )
}

export default WithdrawCompletedDialog
