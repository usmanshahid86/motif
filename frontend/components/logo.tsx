import { cn } from '@/lib/utils';
import Image from "next/image";
import React from "react";

type Props = {
  className?: string;
}

const Logo = ({
  className
}: Props) => {
  return (
    <Image
      src="/images/bitdsm-logo.png"
      className={cn(className)}
      width={200}
      height={30}
      alt={"bitdsm logo"}
      quality={100}
    />
  );
};

export default Logo;
