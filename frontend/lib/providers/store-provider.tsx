"use client";

import { type StoreApi, Mutate, useStore } from "zustand";
import { createLocalStore } from '../state/store';
import React, {
  createContext,
  useContext,
  useEffect,
  useRef,
} from "react";
import { LocalSlices } from '../state/utils';
import { useWeb3React } from '@web3-react/core';
import { HOLESKY_CHAIN_ID } from './web3-provider';
export const localStoreContext = createContext<StoreApi<LocalSlices> | null>(null);

export interface localStoreProviderProps {
  children: React.ReactNode;
}

export const LocalStoreProvider = ({
  children,
}: localStoreProviderProps) => {
  const storeRef = useRef<Mutate<StoreApi<LocalSlices>, [["zustand/persist", never], ["zustand/immer", never]]>>();

  if (!storeRef.current) {
    storeRef.current = createLocalStore();
  }

  const { connector, account } = useWeb3React()

  useEffect(() => {
    async function connectWallet() {
      if (!account && connector && connector.connectEagerly) {
        await connector.connectEagerly(HOLESKY_CHAIN_ID);
      }
    }
    connectWallet()
  }, [])

  return (
    <localStoreContext.Provider value={storeRef.current}>
      {children}
    </localStoreContext.Provider>
  )
}

export const useLocalStore = <T,>(
  selector: (state: LocalSlices) => T,
): T => {
  const localStoreCtx = useContext(localStoreContext);

  if (!localStoreCtx) {
    throw new Error("useLocalStore must be used within a LocalStoreProvider");
  }

  return useStore(localStoreCtx, selector);
}
