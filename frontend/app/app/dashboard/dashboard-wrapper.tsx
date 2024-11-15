"use client"
import React from 'react'
import TotalStaked from './total-staked.client'
import ClaimRewardsButton from './claim-rewards.client'
import FundBODButton from '@/components/fund-bod-button'
import WithdrawButton from '@/components/withdraw-button'
import StakeButton from '@/components/stake-button'
import BodsOverview from './bods-overview.client'
import { useWeb3React } from '@web3-react/core'
import { Coins } from 'lucide-react'

function DashboardWrapper() {
  const { account } = useWeb3React()

  if (!account) {
    return <div className='space-y-8 md:space-y-12 flex flex-col w-full p-4 md:p-0'>
      <div>
        <h1 className='text-xl md:text-4xl'>Dashboard</h1>
      </div>
      <div className='mx-auto text-center space-y-2'>
        <p className='text-primary/80 text-sm md:text-base'>Please connect your wallet to view this page</p>
        <p className='text-primary/80 text-sm md:text-base'>The BitDSM platform is currently only compatible with OKX Wallet.</p>
      </div>
    </div>
  }

  return (
    <>
      <div className='space-y-4 p-4 md:p-0'>
        <h1 className='text-xl md:text-4xl'>Dashboard</h1>
        <div className='flex flex-col md:grid md:grid-cols-2 gap-4 min-h-[200px]'>
          <div className='rounded-md bg-card gap-y-4 p-4 flex flex-col justify-between'>
            <TotalStaked />

            <div className='flex flex-col sm:flex-row md:flex-col lg:flex-row gap-4 flex-wrap'>
              <StakeButton />
              <FundBODButton />
              <WithdrawButton />
            </div>
          </div>
          <div className='rounded-md bg-card p-4 flex flex-col gap-y-4 justify-between'>
            <div className='space-y-2'>
              <div className='flex items-center space-x-1'>
                <Coins className='h-4 w-4' />
                <div className='text-sm md:text-base'>Total Rewards</div>
              </div>
              <div className='text-lg md:text-xl'>0 pts</div>
            </div>

            <div className='flex gap-x-4'>
              <ClaimRewardsButton />
            </div>

          </div>
        </div>
      </div>
      <div className='space-y-4 p-4 md:p-0'>
        <BodsOverview />
      </div>
    </>
  )
}

export default DashboardWrapper

