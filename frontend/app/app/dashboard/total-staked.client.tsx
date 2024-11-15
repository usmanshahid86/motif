"use client"
import Big from 'big.js'
import React, { useMemo } from 'react'
import { useLocalStore } from '@/lib/providers/store-provider'
import { useWeb3React } from '@web3-react/core'
import BTC from '@/lib/denoms'
import { useQuery } from '@tanstack/react-query'
import { getPodBitcoinBalance } from '@/lib/bod'
import { Loader2, LockOpen } from 'lucide-react'

function TotalStaked() {
  const { bitcoinPods } = useLocalStore((state) => state.global)

  const {
    account,
  } = useWeb3React()

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  const query = useQuery({ queryKey: ['bods-balance', pods[0]], queryFn: () => getPodBitcoinBalance(pods[0].ethPodAddress), refetchInterval: 15000 })

  return (
    <div className='space-y-2'>
      <div className='flex items-center space-x-1'>
        <LockOpen className='h-4 w-4' />
        <div className='text-sm sm:text-base md:text-base'>Total Staked</div>
      </div>
      <div className='flex items-center space-x-1'>
        <div className='text-lg sm:text-xl md:text-xl break-all'>
          {new BTC("sats", Big(query.data ? query.data.toString() : "0")).convert("BTC").toFixed(8)} BTC
        </div>
        {(query.isFetching || query.isPending) && <Loader2 className='h-4 w-4 sm:h-4.5 md:h-5 sm:w-4.5 md:w-5 animate-spin' />}
      </div>
    </div>
  )
}

export default TotalStaked
