"use client"

import { truncateAddress, truncateAppName } from "@/lib/utils";
import DelegateButton from "./delegate-button";
import { Copy } from 'lucide-react';
import { toast } from '@/hooks/use-toast';
import BTC from '@/lib/denoms';
import Big from 'big.js';

export const StakedAssetCard = ({
  name,
  balance,
  operator,
  address,
  slashed,
  delegatedApp,
}: {
  name: string;
  balance: string;
  pendingBalance: string;
  operator: string;
  delegatedApp: string;
  address: string,
  slashed?: string;
}) => (
  <div className='p-4 bg-card rounded-md grid grid-cols-2 md:grid-cols-6 gap-2'>
    <div className='col-span-2 flex space-x-4 h-full w-full border-b md:border-b-0 pb-1'>
      <div className='flex justify-between items-center py-1 text-xl w-full flex-wrap'>
        <div>
          <div>{name}</div>
          <div className='flex items-center gap-1 text-sm text-muted-foreground'>
            {truncateAddress(address)}
            <Copy className='cursor-pointer hover:text-foreground h-4 w-4 transition-colors' onClick={() => {
              navigator.clipboard.writeText(address)
              toast({
                title: "Copied to clipboard",
                description: "Copied the BOD funding address to your clipboard.",
              })
            }} />
          </div>
        </div>
        <DelegateButton />
      </div>
      <div className='h-full w-[1px] bg-border hidden md:block' />
    </div>

    <div className='col-span-1 flex space-x-4 h-full w-full'>
      <div className='flex flex-col m-auto items-center py-1'>
        <div className='text-sm font-semibold'>
          Available Balance
        </div>
        <div>
          {new BTC("sats", Big(balance)).convert("BTC").toString()} BTC
        </div>
      </div>

      <div className='h-full w-[1px] bg-border' />
    </div>

    <div className='col-span-1 flex space-x-4 h-full w-full'>
      <div className='flex flex-col m-auto items-center py-1'>
        <div className='text-sm font-semibold'>
          Pending Withdrawal
        </div>
        <div>
          0 BTC
        </div>
      </div>
      <div className='h-full w-[1px] bg-border hidden md:block' />
    </div>

    <div className='col-span-1 flex space-x-4 h-full w-full'>
      <div className='flex flex-col m-auto items-center py-1'>
        <div className='text-sm font-semibold'>
          Operator
        </div>
        <div>
          {operator}
        </div>
      </div>

      <div className='h-full w-[1px] bg-border' />
    </div>


    <div className='col-span-1 flex space-x-4 h-full w-full'>
      <div className='flex flex-col m-auto items-center py-1'>
        <div className='text-sm font-semibold'>
          Delegated App
        </div>
        <div>
          {delegatedApp ? truncateAppName(delegatedApp) : "False"}
        </div>
      </div>

      {slashed && <div className='h-full w-[1px] bg-border' />}
    </div>

    {slashed && (
      <div className='col-span-1 flex space-x-4 h-full w-full'>
        <div className='flex flex-col m-auto items-center py-1'>
          <div className='text-sm font-semibold'>
            Slashed
          </div>
          <div>
            {slashed} BTC
          </div>
        </div>
      </div>
    )}
  </div>
)
