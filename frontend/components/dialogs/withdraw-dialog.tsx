
import React from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../ui/dialog'
import { useDialogFactory } from '@/hooks/use-dialog-factory';
import WithdrawEntryDialog from './withdraw-entry';
import WithdrawCompletedDialog from './withdraw-completed';

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function WithdrawDialog({
  open,
  onOpenChange,
}: Props) {

  const {
    currentView,
  } = useDialogFactory({
    withdrawEntry: {
      title: 'Withdraw',
      content: ({ setView }) => <WithdrawEntryDialog setView={setView} />,
    },
    withdrawCompleted: {
      title: 'Withdraw',
      content: ({ setView }) => <WithdrawCompletedDialog setView={setView} close={() => {
        onOpenChange(false)
        setView("withdrawEntry")
      }}
      />,
    },
  })

  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
    >
      <DialogContent className='max-w-xl'>
        <DialogHeader>
          <DialogTitle>{currentView.title}</DialogTitle>
        </DialogHeader>
        {currentView.content}
      </DialogContent>
    </Dialog>
  )
}

export default WithdrawDialog
