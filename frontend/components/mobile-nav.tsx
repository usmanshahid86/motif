"use client";
import React, { useState } from "react";
import {
  Drawer,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from "./ui/drawer";
import Link from "next/link";
import { Menu } from "lucide-react";
import Logo from "./logo";

function MobileNav({
  navItems,
}: {
  navItems: { href: string; title: string }[];
}) {
  const [open, setOpen] = useState(false);

  return (
    <Drawer open={open} onOpenChange={setOpen} direction="left">
      <DrawerTrigger asChild>
        <button className="block md:hidden">
          <Menu />
        </button>
      </DrawerTrigger>
      <DrawerContent
        className="left-0 top-0 mt-0 h-full w-screen max-w-80 rounded-l-none"
        hideTab
      >
        <DrawerHeader className="text-start">
          <DrawerTitle className="font-bold">
            <Logo className="w-[76px]" />
          </DrawerTitle>
        </DrawerHeader>
        <div className="flex w-full flex-col space-y-4 pt-2">
          {navItems.map((item) => (
            <Link
              className="px-4"
              onClick={() => setOpen(false)}
              key={item.href}
              href={item.href}
            >
              {item.title}
            </Link>
          ))}
        </div>
      </DrawerContent>
    </Drawer>
  );
}

export default MobileNav;
