"use client"
// import { useMetamaskAddress } from '@/lib/hooks/metamask';
import React from 'react'
import Button from './ui/button';
import { useWeb3React } from '@web3-react/core';
import { HOLESKY_CHAIN_ID } from '../lib/providers/web3-provider';
import { useToast } from '@/hooks/use-toast';

function ConnectWallet() {
  const {
    account,
    connector,
  } = useWeb3React()

  const { toast } = useToast()

  return (
    <Button onClick={(e) => {
      e.preventDefault();

      if (!account) {
        try {
          connector.activate(HOLESKY_CHAIN_ID);

          toast({
            title: "Connected to OKX Wallet",
            description: "OKX Wallet was successfully connected.",
          });
        }
        catch (err) {
          toast({
            variant: "destructive",
            title: "Unexpected Error",
            description:
              "An unexpected error occurred with Metamask, please try to refresh the page.",
          });
          console.error(err)
        }
        return;
      }

      if (connector) {
        connector.deactivate?.()
        connector.resetState()

        toast({
          title: "Disconnected OKX Wallet",
          description: "OKX Wallet was successfully disconnected.",
        });
      }

    }} brand>
      {
        account ? <span>{account.slice(0, 6)}...{account.slice(-4)}</span> : <span>Connect Wallet</span>
      }
    </Button>
  )
}

export default ConnectWallet
