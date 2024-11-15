import React from 'react'
import DashboardTabMenu from './tab-menu.client'
import { Metadata } from 'next';
type Props = {
  children: React.ReactNode
}

export const metadata: Metadata = {
  title: "Dashboard | BitDSM",
  description: "BitDSM Dashboard",
  icons: {
    icon: [
      {
        rel: 'icon',
        type: 'image/png',
        media: '(prefers-color-scheme: light)',
        url: '/favicon-dark.png'
      },
      {
        rel: 'icon',
        type: 'image/png',
        media: '(prefers-color-scheme: dark)',
        url: '/favicon-light.png'
      }
    ]
  }
};

function Layout({ children }: Props) {
  return (
    <div className='space-y-8'>
      <DashboardTabMenu />
      {children}
    </div>
  )
}

export default Layout
