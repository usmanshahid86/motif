"use client";

import { LocalStoreProvider } from '@/lib/providers/store-provider';
// import { MetaMaskProvider } from '@metamask/sdk-react';
import { Web3ContextProvider } from '../lib/providers/web3-provider';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient()

function Providers({ children }: { children: React.ReactNode }) {
  // const host =
  //   typeof window !== "undefined"
  //     ? window.location.host
  //     : "http://localhost:3000";

  return (
    <QueryClientProvider client={queryClient}>
      <Web3ContextProvider>
        {/* <MetaMaskProvider
        debug={false}
        sdkOptions={{
          dappMetadata: {
            name: "Twilight Staking",
            url: host,
          },
        }}
      > */}
        <LocalStoreProvider>
          {children}
        </LocalStoreProvider>
        {/* </MetaMaskProvider> */}
      </Web3ContextProvider>
    </QueryClientProvider>
  );
}

export default Providers