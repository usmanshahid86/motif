import React, { useEffect } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../ui/dialog'
import { useDialogFactory } from '@/hooks/use-dialog-factory';
import StakeToBitDSMDialog from './stake-bidsm';
import ChooseOperatorDialog from './choose-operator';
import CreatedBODDialog from './created-bod';
import { useWeb3React } from '@web3-react/core';

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}


function StakingDialog({
  open,
  onOpenChange,
}: Props) {

  const { account } = useWeb3React()

  const {
    setView,
    currentView,
  } = useDialogFactory({
    stakeEntry: {
      title: 'Stake to BitDSM',
      content: ({ setView }) => <StakeToBitDSMDialog setView={setView} />,
    },
    chooseOperator: {
      title: 'Choose an Operator',
      content: ({ setView }) => <ChooseOperatorDialog setView={setView} />
    },
    createdBOD: {
      title: 'Created BOD',
      content: ({ setView }) => <CreatedBODDialog setView={setView} close={() => {
        onOpenChange(false)
        setView("stakeEntry")
      }} />
    }
  })

  useEffect(() => {
    if (!account) return;

    setView("stakeEntry")
  }, [account])


  return (
    <Dialog
      open={open}
      onOpenChange={(value) => {
        onOpenChange(value)
        setView("stakeEntry")
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

export default StakingDialog
