"use client";
import ConnectWallet from '@/components/connect-wallet';
import Button from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { useMetamaskAddress } from '@/lib/hooks/metamask';
import React, { useRef, useState } from 'react'

function TestWrapper() {
  const { account } = useMetamaskAddress();

  const { toast } = useToast();

  const [address, setAddress] = useState<string | null>(null);
  const [unsignedPSBT, setUnsignedPSBT] = useState<string | null>(null);
  const [signedPSBTResult, setSignedPSBTResult] = useState<string | null>(null);

  const withdrawAddressRef = useRef<HTMLInputElement>(null);
  const btcPublicKeyRef = useRef<HTMLInputElement>(null);
  const signedPSBTRef = useRef<HTMLInputElement>(null);

  async function getUnsignedPSBT(e: React.MouseEvent<HTMLButtonElement>) {
    e.preventDefault();

    if (!withdrawAddressRef.current?.value) {
      toast({
        title: 'Withdraw Address is required',
        description: 'Please enter a valid withdraw address',
      });
      return;
    }

    if (!account) {
      toast({
        title: 'Please connect your wallet',
      });
      return;
    }

    try {
      const response = await fetch("http://142.93.159.73:8080/eigen/get_unsigned_psbt", {
        method: "POST",
        body: JSON.stringify({
          WithdrawAddr: withdrawAddressRef.current.value,
          EthAddr: account,
        }),
      })

      const result = await response.json();

      console.log(result);
      setUnsignedPSBT(result);
    }
    catch (error) {
      console.error(error);
    }

  }

  async function getAddress(e: React.MouseEvent<HTMLButtonElement>) {
    e.preventDefault();

    if (!btcPublicKeyRef.current?.value) {
      toast({
        title: 'BTC Public Key is required',
        description: 'Please enter a valid BTC public key',
      });
      return;
    }

    if (!account) {
      toast({
        title: 'Please connect your wallet',
      });
      return;
    }

    try {
      const response = await fetch("http://142.93.159.73:8080/eigen/get_address", {
        method: "POST",
        body: JSON.stringify({
          EthAddr: account,
          PubKey: btcPublicKeyRef.current.value,
        }),
      })

      const result = await response.text()

      console.log(result);
      setAddress(result);
    }
    catch (error) {
      console.error(error);
    }
  }

  async function submitSignedPSBT(e: React.MouseEvent<HTMLButtonElement>) {
    e.preventDefault();

    console.log(signedPSBTRef.current?.value);

    if (!signedPSBTRef.current?.value) {
      toast({
        title: 'Signed PSBT is required',
        description: 'Please enter a valid signed PSBT',
      });
      return;
    }

    try {
      const response = await fetch("http://142.93.159.73:8080/eigen/submit_signed_psbt", {
        method: "POST",
        body: JSON.stringify({
          Psbt: signedPSBTRef.current.value,
        }),
      })

      const result = await response.text()

      console.log(result);
      setSignedPSBTResult(result);

    }
    catch (error) {
      console.error(error);
    }
  }

  return (

    <div className='space-y-4'>
      <h1 className='text-2xl font-semibold'>Testing BitDSM Operator API</h1>

      <div className='space-y-2'>
        <span className='text-lg font-semibold'>Get Address</span>
        <div className='space-y-1'>
          <label>
            Ethereum Address: {account ? account : 'Not connected'}
          </label>

          <ConnectWallet />
        </div>

        <div className='space-y-1 max-w-xs'>
          <label>BTC Public Key</label>
          <Input defaultValue="02a7aa7f4ecf997e3efa16baf4aba3c855aa15e93cf2eaae78d490c9fec0bcc2f5" ref={btcPublicKeyRef} />
        </div>

        <Button onClick={getAddress}>Get Address</Button>
        <div>{address ? address : 'No address generated'}</div>
      </div>

      <div className='w-full h-px bg-gray-200' />

      <div className='space-y-2'>
        <span className='text-lg font-semibold'>Get Unsigned PSBT</span>
        <div className='space-y-1'>
          <label>
            Ethereum Address: {account ? account : 'Not connected'}
          </label>

          <ConnectWallet />

        </div>

        <div className='space-y-1 max-w-xs'>
          <label>Withdraw Address</label>
          <Input ref={withdrawAddressRef} />
        </div>

        <Button onClick={getUnsignedPSBT}>Get Unsigned PSBT</Button >

        <div>{unsignedPSBT ? unsignedPSBT : 'No unsigned PSBT generated'}</div>
      </div>

      <div className='w-full h-px bg-gray-200' />

      <div className='space-y-2'>
        <span className='text-lg font-semibold'>Submit Signed PSBT</span>
        <div className='space-y-1 max-w-xs'>
          <label>Signed PSBT</label>
          <Input ref={signedPSBTRef} />
        </div>

        <Button onClick={submitSignedPSBT}>Submit Signed PSBT</Button>

        <div>{signedPSBTResult ? signedPSBTResult : 'No result'}</div>
      </div>
    </div>
  )
}

export default TestWrapper
