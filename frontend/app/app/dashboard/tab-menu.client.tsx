"use client";

import { cn } from '@/lib/utils'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import React from 'react'

const DashboardTabs = [
  {
    title: "Home",
    href: "/app/dashboard",
  },
  {
    title: "Operators",
    href: "/app/dashboard/operators",
  },
  {
    title: "Apps",
    href: "/app/dashboard/apps",
  },
]

function DashboardTabMenu() {
  const pathname = usePathname()

  return (
    <div className='flex space-x-4 items-center border p-2 rounded-sm'>
      {
        DashboardTabs.map((tab) => (
          <Link href={tab.href} key={tab.href}>
            <div className={
              cn(
                'cursor-pointer hover:bg-brand-secondary hover:text-white transition-colors text-center rounded-md bg-card p-2 px-4 w-[100px]',
                pathname === tab.href && 'bg-brand-secondary text-white',
              )
            }
            >
              {tab.title}
            </div>

          </Link>
        ))
      }
    </div>
  )
}

export default DashboardTabMenu

