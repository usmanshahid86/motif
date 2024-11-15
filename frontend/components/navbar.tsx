"use client"
import React from "react";
import Logo from "./logo";
import Link from "next/link";
import MobileNav from "./mobile-nav";
import ConnectWallet from './connect-wallet';

const NavLink = ({
  href,
  title,
  target,
}: {
  href: string;
  title: string;
  target?: string;
}) => {
  return (
    <Link target={target} className="hover:text-brand-secondary" href={href}>
      {title}
    </Link>
  );
};

const NavigationItems = [
  {
    href: "/app",
    title: "Stake",
  },
  {
    href: "https://github.com/BitDSM",
    title: "Github",
    target: "_blank",
  },
  {
    href: "/app/dashboard",
    title: "Dashboard",
  },
];

const Navbar = () => {
  return (
    <>
      <div className="text-center items-center justify-center flex w-full py-2 brand-gradient-bg text-white">
        <span>
          BitDSM is now live on the Holesky Testnet/Bitcoin Signet !
        </span>
      </div>
      <nav className="border-b w-full bg-background">
        <div className="mx-auto flex items-center px-6 py-4 max-w-screen-xl w-full justify-between">
          <Link className="hover:opacity-60" href="/">
            <Logo className="w-28 md:block" />
          </Link>
          <div className="hidden md:flex items-center space-x-4 ml-auto">
            {NavigationItems.map((item) => (
              <NavLink
                target={item.target}
                key={item.href}
                href={item.href}
                title={item.title}
              />
            ))}
            <ConnectWallet />
          </div>
          <MobileNav navItems={NavigationItems} />
        </div>
      </nav>
    </>
  );
};

export default Navbar
