import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'
import { cn } from '@/lib/utils';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

function DepositBODDialog({
  setView,
  className,
}: Props) {

  return (
    <div className={cn('space-y-8', className)}>

      <div className='space-y-4'>
        <div>
          <p>{`Deposit BTC to your BOD.`}</p>
        </div>

        <Button className='w-full' onClick={() => setView('chooseOperator')}>Deposit</Button>
      </div>
    </div>
  )
}

export default DepositBODDialog
