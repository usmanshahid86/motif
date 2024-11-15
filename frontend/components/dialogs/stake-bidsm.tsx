import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'
import { cn } from '@/lib/utils';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

function StakeToBitDSMDialog({
  setView,
  className,
}: Props) {

  return (
    <div className={cn('space-y-8', className)}>

      <div className='space-y-4'>
        <div>
          <p>{`Let's first create and deploy a Bitcoin POD (BOD), which is a non-custodial vault that makes it possible to participate in a variety of DeFi activities such as liquid restaking, lending/borrowing, minting stable coins and/or wrapped BTC, etc.`}</p>
        </div>

        <Button className='w-full' onClick={() => setView('chooseOperator')}>Create a BOD</Button>

      </div>
    </div>
  )
}

export default StakeToBitDSMDialog
