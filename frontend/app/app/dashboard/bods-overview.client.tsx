"use client";
import { useLocalStore } from '@/lib/providers/store-provider';
import React, { useMemo } from 'react'
import { truncateAddress } from '@/lib/utils';
import { useWeb3React } from '@web3-react/core';
import { StakedAssetCard } from '@/components/staked-asset-card';
import { useQuery } from '@tanstack/react-query';
import { getPodBitcoinBalance } from '@/lib/bod';

function BodsOverview() {
  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods);

  const {
    account,
  } = useWeb3React()

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  const query = useQuery({ queryKey: ['bods-balance', pods[0]], queryFn: () => getPodBitcoinBalance(pods[0].ethPodAddress), refetchInterval: 15000 })

  const delegatedBods = useMemo(() => {
    return pods.filter((pod) => pod.delegated)
  }, [pods])

  const unDelegatedBods = useMemo(() => {
    return pods.filter((pod) => !pod.delegated)
  }, [pods])

  return (
    <div className='space-y-4'>
      <div className='space-y-2'>
        <h3 className='md:text-xl'>Delegated BODs</h3>
        <div className="space-y-4">
          {
            delegatedBods.length > 0 ?
              delegatedBods.map((pod) => (
                <StakedAssetCard
                  key={pod.ethPodAddress}
                  name={`BOD ${truncateAddress(pod.ethPodAddress)}`}
                  balance={query.data ? query.data.toString() : "0"}
                  pendingBalance={"0"}
                  operator={"Chorus"}
                  delegatedApp={pod.delegatedApp}
                  address={pod.ethPodAddress}
                />)) : <div className='text-sm text-muted-foreground'>No Delegated BODs were found</div>
          }
        </div>
      </div>

      <div className='w-full border-b flex h-[1px]' />
      <div className='space-y-2'>
        <h3 className='md:text-xl'>Un-Delegated BODs</h3>
        <div className="space-y-4">
          {
            unDelegatedBods.length > 0 ?
              unDelegatedBods.map((pod) => (
                <StakedAssetCard
                  key={pod.ethPodAddress}
                  name={`BOD ${truncateAddress(pod.ethPodAddress)}`}
                  balance={query.data ? query.data.toString() : "0"}
                  pendingBalance={"0"}
                  operator={"Chorus"}
                  delegatedApp={pod.delegatedApp}
                  address={pod.ethPodAddress}
                />)) : <div className='text-sm text-muted-foreground'>No Un-Delegated BODs were found</div>
          }
        </div>
      </div>

    </div>
  )
}

export default BodsOverview
