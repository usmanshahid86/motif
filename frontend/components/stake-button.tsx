"use client";
import React, { useState } from 'react'
import Button from './ui/button';
import StakingDialog from './dialogs/staking-dialog';
import { useWeb3React } from '@web3-react/core';

function StakeButton() {
  const [open, setOpen] = useState(false);

  const {
    account,
  } = useWeb3React()

  return (
    <>
      <Button brand onClick={() => setOpen(true)} disabled={!account}>Create BOD</Button>
      <StakingDialog open={open} onOpenChange={setOpen} />
    </>

  )
}

export default StakeButton
