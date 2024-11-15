
"use client"
import React, { useMemo, useState } from 'react'
import Button from './ui/button';
import { useWeb3React } from '@web3-react/core';
import { useLocalStore } from '@/lib/providers/store-provider';
import WithdrawDialog from './dialogs/withdraw-dialog';

function WithdrawButton() {
  const [open, setOpen] = useState(false);

  const {
    account,
  } = useWeb3React()

  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  return (
    <>
      <Button onClick={() => setOpen(true)} disabled={!pods.length}>
        Withdraw
      </Button>
      <WithdrawDialog open={open} onOpenChange={setOpen} />
    </>
  );
}

export default WithdrawButton
