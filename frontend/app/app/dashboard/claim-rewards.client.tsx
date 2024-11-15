"use client"
import React from 'react'
import Button from '@/components/ui/button'
import { useWeb3React } from '@web3-react/core'
import { toast } from '@/hooks/use-toast'
function ClaimRewardsButton() {
  const {
    account,
  } = useWeb3React()

  return (
    <Button onClick={() => {
      toast({
        title: "Rewards are unavailable",
        description: "Currently, rewards are not available!"
      })
    }} disabled={!account}>Claim Rewards</Button>
  )
}

export default ClaimRewardsButton
