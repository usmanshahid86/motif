
import React from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../ui/dialog'
import { useDialogFactory } from '@/hooks/use-dialog-factory';
import FundBODEntryDialog from './fund-bod-entry';
import FundBODDialog from './fund-bod';
import FundedBODDialog from './funded-bod';

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function FundingDialog({
  open,
  onOpenChange,
}: Props) {

  const {
    currentView,
    setView
  } = useDialogFactory({
    fundEntry: {
      title: 'Fund a BOD',
      content: ({ setView }) => <FundBODEntryDialog setView={setView} />,
    },
    fundBod: {
      title: 'Fund a BOD',
      content: ({ setView }) => <FundBODDialog setView={setView} />,
    },
    fundedBod: {
      title: 'Funding In Progress',
      content: ({ setView }) => <FundedBODDialog setView={setView} close={() => {
        onOpenChange(false)
        setView("fundEntry")
      }} />,
    },
  })

  return (
    <Dialog
      open={open}
      onOpenChange={(value) => {
        onOpenChange(value)
        setView("fundEntry")
      }}
    >
      <DialogContent className='max-w-xl max-h-[80vh] overflow-y-auto overflow-x-hidden'>
        <DialogHeader>
          <DialogTitle>{currentView.title}</DialogTitle>
        </DialogHeader>
        {currentView.content}
      </DialogContent>
    </Dialog>
  )
}

export default FundingDialog
