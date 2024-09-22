import Big from "big.js";

export type BTCDenoms = "sats" | "BTC";

enum satsFactor {
  "BTC" = 100_000_000,
}

enum BTCFactor {
  "sats" = 0.00000001,
}

export default class BTC {
  currentDenom: BTCDenoms;
  value: Big;

  constructor(denom: BTCDenoms, value: Big) {
    if (!denom || !value) {
      throw new Error("invalid constructor arguments");
    }

    this.currentDenom = denom;
    this.value = value;
  }

  convert(toDenom: BTCDenoms) {
    if (toDenom === this.currentDenom) {
      return this.value;
    }

    let factor = 0;

    switch (toDenom) {
      case "sats": {
        factor = satsFactor[this.currentDenom as keyof typeof satsFactor];
        break;
      }
      case "BTC": {
        factor = BTCFactor[this.currentDenom as keyof typeof BTCFactor];
        break;
      }
    }

    return this.value.mul(new Big(factor));
  }
}
