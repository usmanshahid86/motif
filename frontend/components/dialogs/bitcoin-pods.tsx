"use client"

import React from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog'
import Button from '../ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

function BitcoinPodDialog() {

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button>View List of BitcoinPods</Button>
      </DialogTrigger>
      <DialogContent className='max-w-3xl'>
        <DialogHeader>
          <DialogTitle>BitcoinPods</DialogTitle>
          <div>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[100px]">ID</TableHead>
                  <TableHead>Address</TableHead>
                  <TableHead>Operator</TableHead>
                  <TableHead>BTC</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow>
                  <TableCell className="font-medium">1</TableCell>
                  <TableCell>0xa58e81fe9b61b5c3fe2afd33cf304c454abfc7cb</TableCell>
                  <TableCell>Chorus</TableCell>
                  <TableCell>0.001 BTC</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
        </DialogHeader>
      </DialogContent>
    </Dialog>
  )
}

export default BitcoinPodDialog
