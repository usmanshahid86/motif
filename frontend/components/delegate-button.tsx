"use client"
import React, { useEffect, useMemo, useState } from 'react'
import Button from './ui/button'
import { Dialog, DialogTitle, DialogContent, DialogHeader } from './ui/dialog'
import { delegateBod, undelegateBod } from '@/lib/delegate';
import { useWeb3React } from '@web3-react/core';
import { useLocalStore } from '@/lib/providers/store-provider';
import { toast } from '@/hooks/use-toast';
import { useQuery } from '@tanstack/react-query';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import { useQueryState } from '@/lib/hooks/use-query-state';
import { getApps } from '@/lib/apps';
import { Skeleton } from './ui/skeleton';
import { Input } from './ui/input';
import { cn } from '@/lib/utils';
import { Loader2 } from 'lucide-react';
import { Checkbox } from './ui/checkbox';

function DelegateButton() {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedApp, setSelectedApp] = useState<{ name: string, id: string } | null>(null);

  const updateBitcoinPod = useLocalStore((state) => state.global.updateBitcoinPod);

  const {
    currentQueryValue: delegateAddress,
    setQueryValue,
  } = useQueryState("delegate")

  const {
    account,
  } = useWeb3React()

  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods)

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  const query = useQuery({ queryKey: ['apps'], queryFn: () => getApps(), refetchInterval: 15000 })

  const pod = pods[0]

  const filteredApps = useMemo(() => {
    const result = query.data?.filter((app) => {
      return app.name.toLowerCase().includes(searchTerm?.toLowerCase() || "") ||
        app.id.toLowerCase().includes(searchTerm?.toLowerCase() || "")
    })

    return result || []
  }, [query.data, searchTerm])

  useEffect(() => {
    if (delegateAddress && !pod.delegated) {
      setOpen(true);
      setSearchTerm(delegateAddress || "");
      setQueryValue("");
      return;
    }

  }, [delegateAddress, pod])

  if (pod.delegated) {
    return <Button
      onClick={async () => {
        setLoading(true)
        try {
          if (!account) {
            toast({
              title: "Error undelegating",
              description: "Please connect your wallet to undelegate your Bitcoin Pod",
              variant: "destructive",
            })
            return;
          }

          await undelegateBod(pod.ethPodAddress)

          updateBitcoinPod(account, {
            ...pod,
            delegated: false,
            delegatedApp: "",
          })

          toast({
            title: "Undelegated successfully",
            description: "You have undelegated your Bitcoin Pod, you can now withdraw or delegate to another app",
          })
        }
        catch (err) {
          console.error(err)

          toast({
            title: "Error undelegating",
            description: "An error occurred while undelegating your Bitcoin Pod",
            variant: "destructive",
          })
        }
        setLoading(false)
      }}
    >
      {
        loading ? <Loader2 className='w-4 h-4 animate-spin' /> : "Undelegate"
      }
    </Button>
  }
  return (
    <>
      <div>
        <Button onClick={() => setOpen(true)}>
          {
            pod.delegated ? "Undelegate" : "Delegate"
          }
        </Button>
      </div>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className='max-w-xl'>
          <DialogHeader>
            <DialogTitle>{pod.delegated ? "Undelegate" : "Delegate"} Bitcoin Pod</DialogTitle>
          </DialogHeader>
          <div className='space-y-4'>
            <Input placeholder='Search apps' value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />

            <div className='max-h-[200px] overflow-y-auto px-0.5 py-2'>
              <Table>
                <TableHeader className="sticky top-0 bg-background z-10">
                  <TableRow>
                    <TableHead className="w-[120px]">Name</TableHead>
                    <TableHead>Address</TableHead>
                  </TableRow>
                </TableHeader>
                {
                  query.isLoading || !query.data ?
                    (
                      <TableBody>
                        <TableRow>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                        </TableRow>
                        <TableRow>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                        </TableRow>
                        <TableRow>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                          <TableCell>
                            <Skeleton className='h-6 w-full' />
                          </TableCell>
                        </TableRow>
                      </TableBody>
                    )
                    :
                    <TableBody>
                      {
                        filteredApps.map((app) => {
                          return (
                            <TableRow onClick={() => {
                              if (selectedApp?.id === app.id) {
                                setSelectedApp(null);
                                return;
                              }
                              setSelectedApp(app);
                            }} key={app.id} className={cn('hover:bg-white cursor-pointer', selectedApp?.id === app.id ? "bg-white" : "")}>
                              <TableCell>{app.name}</TableCell>
                              <TableCell>{app.id}</TableCell>
                              <TableCell><Checkbox checked={selectedApp?.id === app.id} /></TableCell>
                            </TableRow>
                          )
                        })
                      }
                    </TableBody>
                }
              </Table>

            </div>
            <Button
              disabled={!selectedApp || loading}
              onClick={async () => {
                if (!selectedApp) {
                  toast({
                    title: "Error delegating",
                    description: "Please select an app to delegate to",
                    variant: "destructive",
                  })
                  return;
                }

                setLoading(true)
                try {
                  if (!account) {
                    toast({
                      title: "Error delegating",
                      description: "Please connect your wallet to delegate your Bitcoin Pod",
                      variant: "destructive",
                    })
                    return;
                  }

                  await delegateBod(pod.ethPodAddress, selectedApp.id)

                  updateBitcoinPod(account, {
                    ...pod,
                    delegated: true,
                    delegatedApp: selectedApp.name,
                  })

                  toast({
                    title: "Delegated successfully",
                    description: "You have successfully delegated your Bitcoin Pod to " + selectedApp.name,
                  })
                }
                catch (err) {
                  console.error(err)

                  toast({
                    title: "Error delegating",
                    description: "An error occurred while delegating your Bitcoin Pod",
                    variant: "destructive",
                  })
                }
                setLoading(false)
              }} className="w-full mt-4">
              {
                loading ? <Loader2 className='w-4 h-4 animate-spin' /> : "Delegate"
              }
            </Button>

          </div>

        </DialogContent>
      </Dialog >
    </>
  )
}

export default DelegateButton

