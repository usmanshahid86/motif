import ConnectWallet from '@/components/connect-wallet'
import Button from '@/components/ui/button'
import React from 'react'
import Link from 'next/link'

function StakingTutorial() {
  return (
    <div className='space-y-4'>
      <h2 className='text-lg md:text-2xl'>How to Stake and Earn</h2>

      <div className='bg-card p-4 rounded-md grid grid-cols-2 grid-rows-2 md:grid-rows-1 md:grid-cols-4 gap-4 min-h-[300px]'>
        <div className='col-span-1 space-y-4'>
          <div className='flex items-center gap-2'>
            <div className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-200">
              <span className="text-lg font-semibold">1</span>
            </div>
            <p className='text-muted-foreground'>
              Connect your wallet
            </p>
          </div>
          <ConnectWallet />
        </div>
        <div className='col-span-1 space-y-4'>
          <div className='flex items-center gap-2'>
            <div className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-200">
              <span className="text-lg font-semibold">2</span>
            </div>
            <p className='text-muted-foreground'>
              Create a BOD
            </p>
          </div>
          <Link href="/app/dashboard" passHref>
            <Button className='mt-4' brand>Create BOD</Button>
          </Link>
        </div>
        <div className='col-span-1 space-y-4'>
          <div className='flex items-center gap-2'>
            <div className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-200">
              <span className="text-lg font-semibold">3</span>
            </div>
            <p className='text-muted-foreground'>
              Deposit Funds
            </p>
          </div>
          <p className="max-w-[90%]">
            Deposit BTC to your BOD.
          </p>
        </div>

        <div className='col-span-1 space-y-4'>
          <div className='flex items-center gap-2'>
            <div className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-200">
              <span className="text-lg font-semibold">4</span>
            </div>
            <p className='text-muted-foreground'>
              Delegate to an Operator
            </p>
          </div>
          <p className="max-w-[90%]">
            Delegate the BTC to an Operator.
          </p>
        </div>
      </div>
    </div>
  )
}

export default StakingTutorial
