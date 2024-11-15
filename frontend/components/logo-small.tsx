import { cn } from "@/lib/utils";
import React from "react";

type Props = {
  className?: string;
};

const LogoSmall = ({ className }: Props) => {
  return (
    <svg
      className={cn(className)}
      viewBox="0 0 73 74"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <g id="Group 10125282">
        <g id="Group 10124931">
          <path
            id="Vector 4386"
            d="M72.508 0.0667546L0 0.0667419C-4.99756e-06 28.6495 24.2656 36.3714 36.3984 36.6595L72.508 0.0667546Z"
            fill="black"
          />
          <path
            id="Vector 4387"
            d="M8.39233e-05 73.93L72.5081 73.93C72.5081 44.818 48.2424 36.953 36.1096 36.6596L8.39233e-05 73.93Z"
            fill="black"
          />
        </g>
      </g>
    </svg>
  );
};

export default LogoSmall;
