import React from "react";
import Logo from "./logo";
import Link from "next/link";

function Footer() {
  return (
    <div className="mt-12 border-t">
      <footer className="mx-auto py-8 xl:px-0">
        <div className="mx-auto flex items-center justify-between px-6 max-w-screen-xl w-full">
          <Link className="hover:opacity-60" href="/">
            <Logo className="hidden w-28 md:block" />
          </Link>
          <p className="max-w-[250px] text-end font-ui text-xs text-primary/80 md:max-w-full md:text-sm">
            Copyright 2024 BitDSM. All Rights Reserved
          </p>
        </div>
      </footer>
    </div>
  );
}

export default Footer;
