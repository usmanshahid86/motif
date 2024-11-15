import type { Metadata } from "next";
import "./globals.css";
import Footer from "@/components/footer";
import Providers from "@/components/providers";
import Navbar from '@/components/navbar';
import { Toaster } from '@/components/ui/toaster';

export const metadata: Metadata = {
  title: "BitDSM | Bitcoin Delegated Staking Mechanism",
  description: "Bitcoin Delegated Staking Mechanism",
  icons: {
    icon: [
      {
        rel: 'icon',
        type: 'image/png',
        media: '(prefers-color-scheme: light)',
        url: '/favicon-dark.png'
      },
      {
        rel: 'icon',
        type: 'image/png',
        media: '(prefers-color-scheme: dark)',
        url: '/favicon-light.png'
      }
    ]
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
    // className={`${andaleMono.variable} ${atlasGrotesk.variable} ${mannerProLight.variable}`}
    >
      <Providers>
        <body className="font-body">
          <Navbar />
          <main className="min-h-[calc(100vh-12.5rem)] mx-auto mb-24 px-2 md:px-8 lg:px-4 sm:mt-8 w-full max-w-screen-xl">
            {children}
          </main>

          <Toaster />
          <Footer />
        </body>
      </Providers>
    </html>
  );
}
