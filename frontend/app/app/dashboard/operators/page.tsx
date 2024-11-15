import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import Link from 'next/link'
import React from 'react'
import operators from "@/lib/operators.json";

async function Page() {

  return <>
    <div>
      <h1 className='text-xl md:text-4xl'>Operators</h1>
    </div>
    <div>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-[100px]">Name</TableHead>
            <TableHead>Address</TableHead>
            <TableHead>Staked</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {
            operators.operators.map((operator) => (
              <TableRow key={operator.id}>
                <TableCell className="font-medium">{operator.name}</TableCell>
                <TableCell>{operator.address}</TableCell>
                <TableCell>{operator.tvl}</TableCell>
                <TableCell>
                  <Link className='hover:underline hover:text-brand-secondary' target="_blank" href={`https://holesky.etherscan.io/address/${operator.address}`}>
                    Link
                  </Link>
                </TableCell>

              </TableRow>
            ))
          }
          <TableRow>
          </TableRow>
        </TableBody>
      </Table>
    </div>
  </>

}


export default Page
