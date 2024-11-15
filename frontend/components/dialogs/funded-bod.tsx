import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'
import { cn } from '@/lib/utils';
import Link from 'next/link';
import { useLocalStore } from '@/lib/providers/store-provider';
import { useMemo } from 'react';
import { useWeb3React } from '@web3-react/core';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  close: () => void;
  className?: string;
}

function FundedBODDialog({
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
          <p>{`Your Bitcoin Pod is being funded. It will be ready to use after it has been confirmed on the Bitcoin network.`}</p>
          <Link className='hover:underline' target="_blank" href={`https://mempool.space/signet/tx/${pod.depositTxHash}`}>View on Mempool</Link>
        </div>

        <Button className='w-full' onClick={() => close()}>Close</Button>
      </div>
    </div>
  )
}

export default FundedBODDialog
