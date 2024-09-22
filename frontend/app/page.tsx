import { Button } from "@/components/ui/button";
import { Lock, TrendingUp, Zap } from "lucide-react";

import { GitHubLogoIcon } from "@radix-ui/react-icons";

import Link from "next/link";

export default function LandingPage() {
  return (
    <>
      <section className="mt-10 w-full py-12 text-zinc-900 md:py-24 lg:py-32 xl:py-48">
        <div className="container mx-auto px-4 md:px-6">
          <div className="flex flex-col items-center space-y-4 text-center">
            <div className="max-w-xl space-y-4">
              <h1 className="text-2xl font-bold tracking-tighter sm:text-3xl md:text-4xl lg:text-5xl/none">
                Unlock your liquidity with{" "}
                <span className="underline">non-custodial</span>{" "}
                staking
              </h1>
              <div className="flex justify-center">
                <Link
                  className="cursor-pointer hover:text-zinc-900/80"
                  target={"_blank"}
                  href={"#"}
                >
                  <GitHubLogoIcon className="h-6 w-6" />
                </Link>
              </div>
              <p className="text-lg">
                Introducing BitDSM - the Bitcoin Delegated Staking Mechanism
              </p>
              <Link passHref href="/app">
                <Button
                  className="mt-4 font-semibold"
                  type="submit"
                  variant="outline"
                >
                  Enter App
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>
      <div className="w-full p-4">
        <section className="w-full rounded-[40px] bg-zinc-950 py-12 text-zinc-100 md:py-24 lg:py-32">
          <div className="container mx-auto px-4 md:px-6">
            <h2 className="mb-12 text-center text-3xl font-bold tracking-tighter sm:text-5xl">
              How Does It Work?
            </h2>
            <div className="grid gap-10 sm:grid-cols-2 md:grid-cols-3">
              <div className="flex flex-col items-center space-y-2 rounded-[40px] border border-zinc-600 p-4 duration-500 hover:-translate-y-4">
                <Lock className="h-8 w-8" />
                <h3 className="text-2xl font-bold">Desposit BTC</h3>
                <p className="text-center text-zinc-200">
                  Deposit your Bitcoin into a BOD (Bitcoin Pod)
                </p>
              </div>
              <div className="flex flex-col items-center space-y-2 rounded-[40px] border border-zinc-600 p-4 duration-500 hover:-translate-y-4">
                <TrendingUp className="h-8 w-8" />
                <h3 className="text-2xl font-bold">Sign a PSBT</h3>
                <p className="text-center text-zinc-200">
                  Co-sign a PSBT to slash in case of liquidation
                </p>
              </div>
              <div className="flex flex-col items-center space-y-2 rounded-[40px] border border-zinc-600 p-4 duration-500 hover:-translate-y-4">
                <Zap className="h-8 w-8" />
                <h3 className="text-2xl font-bold">Liquidity Unlocked</h3>
                <p className="text-center text-zinc-200">
                  Your liquidity is now unlocked! Claim your BitC.
                </p>
              </div>
            </div>
          </div>
        </section>
      </div>

      <footer className="flex w-full shrink-0 flex-col items-center gap-2 border-t px-4 py-6 sm:flex-row md:px-6"></footer>
    </>
  );
}
