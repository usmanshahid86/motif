import React from 'react'

const COLUMNS = [
  {
    id: "tvl",
    title: "TVL",
    content: "0.54 BTC"
  },
  {
    id: "operators",
    title: "Operators",
    content: "3"
  },
  {
    id: "total-rewards",
    "title": "Total Rewards",
    content: "0 pts",
  },
  {
    id: "apps",
    title: "Apps",
    content: "3"
  },

]

function AppOverview() {
  return (
    <div className='space-y-4'>
      <h2 className='text-lg md:text-2xl'>Overview</h2>

      <div className='gap-2 flex flex-wrap'>
        {COLUMNS.map((column) => (
          <div key={column.id} className='flex flex-col bg-card p-4 rounded-sm w-[150px]'>
            <span className='text-sm text-muted-foreground'>{column.title}</span>
            <span className='font-semibold'>{column.content}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

export default AppOverview
