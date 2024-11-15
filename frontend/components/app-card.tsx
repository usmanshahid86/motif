"use client"
import { truncateAddress } from '@/lib/utils';
import { Copy, Globe } from 'lucide-react';
import Link from 'next/link';
import React from 'react'
import Button from './ui/button';
import { toast } from '@/hooks/use-toast';

type Props = {
  name: string;
  address: string;
  description: string;
  url?: string;
}

function AppCard({ name, address, description, url }: Props) {
  return (
    <div className='bg-card p-4 rounded-sm gap-y-4 flex flex-col border h-[250px]'>
      <div className='border-b pb-2'>
        <div className='text-2xl line-clamp-1'>{name}</div>
        <div className='text-sm text-muted-foreground flex gap-x-2 items-center'>
          <div>{truncateAddress(address)}</div>
          <Copy className='cursor-pointer hover:text-foreground h-3 w-3 transition-colors' onClick={() => {
            navigator.clipboard.writeText(address)
            toast({
              title: "Copied to clipboard",
              description: "Copied the App contract address to your clipboard.",
            })
          }} />
        </div>
        {
          url &&
          <Link href={url} target='_blank'>
            <Globe className='h-4 w-4 mt-1 cursor-pointer hover:text-brand-secondary' />
          </Link>
        }
      </div>
      <div className='flex flex-col justify-between h-full'>
        <div className='space-y-1'>
          <div className='text-xs'>Description:</div>
          <p className='text-sm line-clamp-2'>{description}</p>
        </div>
        <div className='flex flex-col gap-y-2 text-sm'>
          <Link href={`/app/dashboard?delegate=${address}`} passHref>
            <Button>
              Delegate
            </Button>
          </Link>
        </div>
      </div>
    </div>
  )
}

export default AppCard
