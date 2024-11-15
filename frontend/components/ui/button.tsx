import React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cn } from "@/lib/utils";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: keyof typeof variantStyles;
  size?: keyof typeof sizeStyles;
  asChild?: boolean;
  className?: string;
  children?: React.ReactNode;
  dark?: boolean;
  brand?: boolean;
}

const variantStyles = {
  primary: "border bg-background rounded-lg hover:bg-background/80",
  secondary: `btn-secondary bg-button-secondary hover:bg-background rounded-lg transition-colors 
    duration-300 disabled:hover:bg-button-secondary`,
  link: "transition-colors bg-transparent underline underline-offset-2 hover:decoration-dashed p-0 disabled:no-underline hover:decoration-theme hover:text-theme",
  icon: `border border-primary bg-transparent rounded-full hover:border-transparent hover:bg-brand-accent-200 dark:hover:bg-button-secondary
    disabled:bg-background disabled:border-gray-500 disabled:hover:bg-background dark:disabled:hover:bg-background disabled:hover:border-gray-500
  `,
  ui: `border hover:border-primary rounded-lg py-0 disabled:hover:border-border`,
} as const;

const sizeStyles = {
  default: "md:px-10 md:py-3 gap-2 px-4 py-2",
  small: "px-4 py-2 gap-2",
  icon: "p-3",
} as const;

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = "primary",
      size = "default",
      asChild,
      dark,
      brand,
      className,
      children,
      ...props
    },
    ref
  ) => {
    return React.createElement(
      asChild ? Slot : "button",
      {
        className: cn(
          "flex relative justify-center items-center flex-shrink-0 disabled:text-gray-500 transition-colors duration-300 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary disabled:cursor-not-allowed",
          sizeStyles[size],
          variantStyles[variant],
          dark
            ? "border-theme-secondary-foreground bg-theme-secondary disabled:text-gray-400"
            : "border-black bg-white",
          brand && "border-none brand-gradient text-white [&>*]:relative disabled:text-white",
          className
        ),
        ref,
        ...props,
      },
      children
    );
  }
);

Button.displayName = "Button";

export default Button;
