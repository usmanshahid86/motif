import Button from '@/components/ui/button'
import React from 'react'
import MarketingStats from './marketing-stats'
import Link from 'next/link'
import { Box, Currency, Lock, Unlink } from 'lucide-react'

function Home() {
  return (
    <div className='space-y-8 flex flex-col'>
      <div className='flex flex-col space-y-4 md:grid md:grid-cols-8 md:gap-x-4 py-8'>
        <div className="absolute inset-0 -z-10 h-[calc(100%-8rem)] w-full bg-[linear-gradient(to_right,#8080800a_1px,transparent_1px),linear-gradient(to_bottom,#8080800a_1px,transparent_1px)] bg-[size:14px_24px]"></div>
        <div className='space-y-8 md:col-span-6 md:min-h-[400px] relative flex flex-col'>
          <div className='space-y-4 max-w-xl'>
            <h1 className='text-2xl md:text-3xl lg:text-5xl'><span className='text-brand-accent'>Bitcoin</span> Delegated Staking Mechanism</h1>
            <p className='md:text-lg max-w-md'>BitDSM secures the future of Bitcoin DeFi. Powered by <span className='font-semibold'>BODS</span> - A Non Custodial Delegation Mechanism.</p>
          </div>

          <div>
            <Link href={"/app"} passHref>
              <Button brand>Launch App</Button>
            </Link>
          </div>

        </div>
      </div>
      <div className='space-y-4'>
        <div className='text-2xl'>BitDSM Ecosystem</div>
        <MarketingStats />
      </div>
      <div className='flex flex-col-reverse md:grid md:grid-cols-6 p-4 w-full bg-card rounded-md'>
        <div className='col-span-2 space-y-4 my-auto'>
          <h2 className='text-2xl font-semibold'>Bitcoin DeFi</h2>
          <p>{`Bitcoin Pods (BODS), are non-custodial vaults modeled after EigenPods that make BTC delegation on POS chains possible, enabling DeFi services to be built on top of BitDSM`}</p>
          <Link passHref href={"/app"}>
            <Button className='mt-4' brand>Launch App</Button>
          </Link>
        </div>
        <div className='col-span-4 p-4 grid grid-cols-2 grid-rows-2 h-full'>
          <div className='border-b border-r p-4 flex flex-col items-center space-y-4 text-center'>
            <Unlink className='h-12 w-12 rounded-sm bg-brand-secondary text-white p-2' />
            <p className='max-w-[80%]'>Secure PoS chains with Bitcoin and mint LST/LRT on Ethereum</p>
          </div>
          <div className='border-b p-4 flex flex-col items-center space-y-4 text-center'>
            <Lock className='h-12 w-12 rounded-sm bg-brand-secondary text-white p-2' />
            <p className='max-w-[80%]'>Lock BODS and use them as collateral for lending on Ethereum</p>
          </div>
          <div className='border-r p-4 flex flex-col items-center space-y-4 text-center'>
            <Box className='h-12 w-12 rounded-sm bg-brand-secondary text-white p-2' />
            <p className='max-w-[80%]'>Use BODS as deposit addresses for wrapped BTC or as insurance for BTC bridges</p>
          </div>
          <div className='p-4 flex flex-col items-center space-y-4 text-center'>
            <Currency className='h-12 w-12 rounded-sm bg-brand-secondary text-white p-2' />
            <p className='max-w-[80%]'>Mint a stable asset by using BODS as CDPS</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Home
