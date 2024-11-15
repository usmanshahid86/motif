import { DialogViewKey } from '@/hooks/use-dialog-factory';
import Button from '../ui/button'

import { useWeb3React } from '@web3-react/core';
import { toast } from '@/hooks/use-toast';
import { useMemo, useRef, useState } from 'react';
import { useLocalStore } from '@/lib/providers/store-provider';
import { Input } from '../ui/input';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '../ui/table';
import { cn } from '@/lib/utils';
import { Loader2 } from 'lucide-react';
import { createBitcoinMultisigAddress, createPOD, getOperators } from '@/lib/bod';
import { OKXBitcoinSignet, Operator } from '@/types';
import { useQuery } from '@tanstack/react-query';
import { Skeleton } from '../ui/skeleton';
import { Checkbox } from '../ui/checkbox';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
  className?: string;
}

function ChooseOperatorDialog({
  setView,
  className,
}: Props) {
  const {
    account,
    provider,
  } = useWeb3React()

  const addBitcoinPod = useLocalStore((state) => state.global.addBitcoinPod)
  const bitcoinPods = useLocalStore((state) => state.global.bitcoinPods)

  const query = useQuery({ queryKey: ['operators'], queryFn: () => getOperators() })

  const pods = useMemo(() => {
    return account && bitcoinPods[account.toLowerCase()] ? bitcoinPods[account.toLowerCase()] : []
  }, [account, bitcoinPods])

  const [selectedOperator, setSelectedOperator] = useState<Operator | null>(null)

  const [loading, setLoading] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)
  const [searchTerm, setSearchTerm] = useState('')

  return (
    <div className={cn('space-y-8', className)}>

      <div className='space-y-4'>
        <div>
          <Input
            ref={searchRef}
            placeholder='Look up by Operator Name'
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div className='max-h-[200px] overflow-y-auto overflow-x-hidden px-0.5 py-2'>
          <Table >
            <TableHeader>
              <TableRow>
                <TableHead className="w-[120px]">Operator</TableHead>
                <TableHead>Address</TableHead>
                <TableHead>TVL</TableHead>
                <TableHead></TableHead>
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
                <TableBody >
                  {(() => {

                    const filteredOperators = query.data.filter((operator) => {
                      return operator.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                        operator.address.toLowerCase().includes(searchTerm.toLowerCase())
                    });

                    if (filteredOperators.length === 0) {
                      return (
                        <TableRow>
                          <TableCell colSpan={4} className="text-center text-muted-foreground">
                            No operators found
                          </TableCell>
                        </TableRow>
                      );
                    }

                    return filteredOperators.map((operator) => (
                      <TableRow onClick={() => {
                        if (selectedOperator?.id !== operator.id) {
                          setSelectedOperator(operator)
                          return;
                        }
                        setSelectedOperator(null)
                      }} className={cn('hover:bg-white cursor-pointer', selectedOperator?.id === operator.id && 'bg-white')} key={operator.address}>
                        <TableCell className="font-medium">{operator.name}</TableCell>
                        <TableCell>{operator.address}</TableCell>
                        <TableCell>{operator.tvl}</TableCell>
                        <TableCell><Checkbox checked={selectedOperator?.id === operator.id} /></TableCell>
                      </TableRow>
                    ))
                  })()}
                </TableBody>
            }
          </Table>

        </div>
        <Button className='w-full' onClick={async (e) => {
          e.preventDefault();

          try {
            if (!selectedOperator?.id) {
              toast({
                title: "Please select an operator.",
                description: "Please select an operator to continue.",
              });
              return;
            }

            if (!provider || !provider.provider || !account) {
              toast({
                title: "Please make sure you have OKX wallet installed.",
                description: "OKX Wallet is required to stake your BTC to BitDSM.",
              });
              return;
            }

            const okxSignet = provider.provider as OKXBitcoinSignet

            if (!okxSignet.bitcoinSignet) {
              toast({
                title: "Bitcoin network not supported",
                description: "Please make sure your OKX wallet has Bitcoin network enabled.",
              });
              return;
            }

            if (pods)
              setLoading(true)

            try {
              const signetResult = await okxSignet.bitcoinSignet.connect();

              toast({
                title: "Connected to Bitcoin Signet",
                description: "Bitcoin Signet was successfully connected.",
              })

              const result = await createBitcoinMultisigAddress(signetResult.publicKey, selectedOperator.id);
              console.log("multisig", result)

              const { podAddress, txHash } = await createPOD(selectedOperator.address, result.addressHex)

              console.log(podAddress)

              if (!podAddress || !txHash) {
                toast({
                  variant: "destructive",
                  title: "Unexpected Error",
                  description: "An unexpected error occurred with creating the POD.",
                });
                return;
              }

              addBitcoinPod(account, {
                btcAddress: result.newAddress,
                btcAddressHex: result.addressHex,
                ethPodAddress: podAddress,
                delegated: false,
                delegatedApp: "",
                sats: "0",
                txHash: txHash,
                operator: selectedOperator.id,
              })

              setView("createdBOD")
            }
            catch (err) {
              console.error(err)
              toast({
                variant: "destructive",
                title: "Unexpected Error",
                description:
                  "An unexpected error occurred with OKX Wallet, please try to refresh the page.",
              });
            }
          }
          catch (err) {
            console.error(err)
          }

          setLoading(false)
        }}>
          {loading ? <Loader2 className='animate-spin' /> : 'Connect BTC Wallet and Create BOD'}
        </Button>
      </div>
    </div >
  )
}

export default ChooseOperatorDialog
