import { Button } from "@/components/ui/button";
import React from "react";
import AppWrapper from "./app-wrapper.client";

function Page() {
  return (
    <div className="mt-8 h-full pb-12 flex w-full px-4 text-zinc-900">
      <div className='flex flex-col space-y-4 w-full mx-auto max-w-4xl'>
        <h2 className="text-2xl font-bold tracking-tighter sm:text-3xl">
          Dashboard
        </h2>

        <AppWrapper />
      </div>
      {/* <Button>Connect Wallet</Button> */}
    </div >
  );
}

export default Page;
