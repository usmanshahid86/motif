import "zustand/middleware/immer";
import { StateCreator } from "zustand";
import { GlobalSlice } from "./local/global";

export type StateImmerCreator<SlicesT, SliceT> = StateCreator<
  SlicesT,
  [["zustand/immer", never]],
  [],
  SliceT
>;

export interface LocalSlices {
  global: GlobalSlice;
}
