import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'
import { cn } from '@/lib/utils';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  close: () => void;
  className?: string;
}

function CreatedBODDialog({
  close,
  className,
}: Props) {

  return (
    <div className={cn('space-y-8', className)}>

      <div className='space-y-4'>
        <div>
          <p>{`Congratulations! Your Bitcoin Pod has been created and deployed. You can now choose an app and start delegating it.`}</p>
        </div>

        <Button className='w-full' onClick={() => close()}>Close</Button>
      </div>
    </div>
  )
}

export default CreatedBODDialog
