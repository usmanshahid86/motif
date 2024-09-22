import Link from "next/link";
import React from "react";

function Navbar() {
  return (
    <header className="flex h-14 w-full items-center px-4 text-black lg:px-6 border-b">
      <Link className="flex items-center justify-center" href="/">
        <span className="font-semibold">BitDSM</span>
      </Link>
      <nav className="ml-auto flex gap-4 sm:gap-6">
        <Link
          className="text-sm font-semibold underline-offset-4 hover:underline"
          href="/app"
        >
          App
        </Link>
      </nav>
    </header>
  );
}

export default Navbar;
