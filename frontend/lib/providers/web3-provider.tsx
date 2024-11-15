import React from "react"
import { Web3ReactProvider } from "@web3-react/core"
import { initializeConnector } from '@web3-react/core'
import { OKXWallet } from '@okwallet/web3-react-okxwallet'

export const HOLESKY_CHAIN_ID = 17000

export const [okxWallet, hooks] = initializeConnector<OKXWallet>((actions) => new OKXWallet({ actions }))

const PRIORITIZED_CONNECTORS = [{ connector: okxWallet, hooks }];

export const Web3ContextProvider = ({ children }: { children: React.ReactNode }) => {
  return <Web3ReactProvider
    connectors={Object.values(PRIORITIZED_CONNECTORS).map((connector) => [connector.connector, connector.hooks])}
  >
    {children}
  </Web3ReactProvider>
}