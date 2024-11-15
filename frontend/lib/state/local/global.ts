import { BitcoinPod } from "@/types";
import { LocalSlices, StateImmerCreator } from "../utils";

export interface GlobalSlice {
  bitcoinPods: Record<string, BitcoinPod[]>;
  updateBitcoinPod: (userAddress: string, data: BitcoinPod) => void;
  removeBitcoinPod: (userAddress: string, ethPodAddress: string) => void;
  addBitcoinPod: (userAddress: string, pod: BitcoinPod) => void;
}

export const initialGlobalSiceState: GlobalSlice = {
  bitcoinPods: {},
  updateBitcoinPod: () => {
    return {} as BitcoinPod;
  },
  removeBitcoinPod: () => {},
  addBitcoinPod: () => {
    return {} as BitcoinPod;
  },
};

export const createGlobalSlice: StateImmerCreator<LocalSlices, GlobalSlice> = (
  set
) => ({
  ...initialGlobalSiceState,
  updateBitcoinPod: (userAddress: string, data: BitcoinPod) => {
    set((state) => {
      const address = userAddress.toLowerCase();

      state.global.bitcoinPods[address] = state.global.bitcoinPods[
        address
      ].filter((pod) => pod.ethPodAddress !== data.ethPodAddress);

      state.global.bitcoinPods[address] = [
        ...state.global.bitcoinPods[address],
        data,
      ];
    });
  },
  removeBitcoinPod: (userAddress: string, ethPodAddress: string) => {
    set((state) => {
      const address = userAddress.toLowerCase();

      if (state.global.bitcoinPods[address]) {
        state.global.bitcoinPods[address] = state.global.bitcoinPods[
          address
        ].filter((pod) => pod.ethPodAddress !== ethPodAddress);
      }
    });
  },
  addBitcoinPod: (userAddress: string, pod: BitcoinPod) => {
    set((state) => {
      const address = userAddress.toLowerCase();
      if (!state.global.bitcoinPods[address]) {
        state.global.bitcoinPods[address] = [] as BitcoinPod[];
      }

      state.global.bitcoinPods[address] = [
        ...state.global.bitcoinPods[address],
        pod,
      ];
    });
  },
});
