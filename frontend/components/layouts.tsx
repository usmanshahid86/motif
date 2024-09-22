"use client";
import React from "react";

import {
  DynamicContextProvider,
  DynamicWidget,
} from "@dynamic-labs/sdk-react-core";

import { BitcoinWalletConnectors } from "@dynamic-labs/bitcoin";
import { EthereumWalletConnectors } from '@dynamic-labs/ethereum';

type Props = {
  children: React.ReactNode;
};

function Layouts({ children }: Props) {
  return (
    <DynamicContextProvider
      settings={{
        // Find your environment id at https://app.dynamic.xyz/dashboard/developer
        environmentId: "338c1ef9-c0a5-4d3d-abd7-29dc3fb79363",
        walletConnectors: [BitcoinWalletConnectors, EthereumWalletConnectors],
      }}
    >
      {children}
    </DynamicContextProvider>
  );
}

export default Layouts;
