import { createStore } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import { immer } from "zustand/middleware/immer";
import { createGlobalSlice, GlobalSlice } from "./local/global";
import { LocalSlices } from "./utils";
import deepMerge from "deepmerge";

export const createLocalStore = () => {
  return createStore<
    LocalSlices,
    [["zustand/persist", never], ["zustand/immer", never]]
  >(
    persist(
      immer<LocalSlices>((...actions) => ({
        global: createGlobalSlice(...actions),
      })),
      {
        name: "bitdsm",
        storage: createJSONStorage(() => localStorage),
        version: 0.1,
        merge: (persistedState, currentState) => {
          return deepMerge(
            {
              global: {
                ...currentState.global,
              },
            },
            persistedState as GlobalSlice
          );
        },
      }
    )
  );
};
