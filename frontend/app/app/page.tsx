import Button from '@/components/ui/button'
import React from 'react'
import AppOverview from './app-overview'
import StakingTutorial from './staking-tutorial'
import Link from 'next/link'
import BitcoinPodDialog from '@/components/dialogs/bitcoin-pods'

function Page() {
  return (
    <div className='space-y-12'>
      <div className='space-y-4'>
        <h1 className='text-lg md:text-2xl'>BitDSM - Securing the Future of Bitcoin DeFi</h1>
        <div className='rounded-md bg-card p-4 space-y-4'>
          <p>{`BitDSM, A Non-Custodial Delegation Mechanism for Bitcoins, powers native Bitcoin delegation to multiple blockchain networks via BitcoinPods, enabling truly decentralized liquid restaking and collateralized DeFi lending, issuance, and BTC bridging, maximizing yields and minimizing risks for BTC holders.`}</p>
          <div className='flex gap-1 flex-wrap w-full justify-between'>
            <Link href={"/app/dashboard"} passHref>
              <Button brand>Launch App</Button>
            </Link>
            <BitcoinPodDialog />
            <Link target="_blank" href={"https://github.com/BitDSM/BitDSM?tab=readme-ov-file#bitdsm--bitcoin-delegated-staking-mechanism"} passHref>
              <Button className='hover:bg-secondary/80'>Learn more</Button>
            </Link>
          </div>
        </div>
      </div>

      <AppOverview />

      <StakingTutorial />
    </div>
  )
}

export default Page
