import { cn } from '@/lib/utils'
import React from 'react'

function Column({
  title,
  content,
}: {
  title: string,
  content: string
}) {
  return <div className='md:space-y-2 flex flex-col items-center'>
    <span className='text-lg md:text-2xl font-semibold'>{title}</span>
    <span className='md:text-xl'>{content}</span>
  </div>
}

const COLUMNS = [
  {
    id: "tvl",
    title: "TVL",
    content: "0.54 BTC"
  },
  {
    id: "apps",
    title: "Apps",
    content: "4"
  },
  {
    id: "pods",
    title: "Pods",
    content: "8",
  },
  {
    id: "operators",
    title: "Operators",
    content: "3"
  }
]

function MarketingStats() {
  return (
    <div className='mx-auto bg-card w-full rounded-md grid grid-cols-4 p-4 items-center justify-center'>
      {
        COLUMNS.map((col, index) =>
          <div className={cn('items-center justify-center flex space-x-2 border-r', index === COLUMNS.length - 1 && 'border-r-0')} key={col.id} >
            <Column title={col.title} content={col.content} />
          </div>
        )
      }
    </div>
  )
}

export default MarketingStats
