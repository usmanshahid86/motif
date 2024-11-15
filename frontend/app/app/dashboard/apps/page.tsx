import AppCard from '@/components/app-card'
import { Input } from '@/components/ui/input'
import { getApps } from '@/lib/apps';
import React from 'react'

export const revalidate = 60

async function Page() {
  const apps = await getApps();
  return <>
    <div>
      <h1 className='text-xl md:text-4xl'>Apps</h1>
    </div>

    <div className='max-w-xl'>
      <Input placeholder='Search apps' />

    </div>

    <div className='grid grid-cols-4 gap-4'>
      {apps.map((app) => (
        <AppCard
          name={app.name}
          address={app.id}
          description={app.description}
          url={app.url}
          key={app.id}
        />
      ))}
    </div>
  </>

}


export default Page
