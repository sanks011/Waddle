import type { Metadata } from "next";
import { Geist, Geist_Mono, Playfair_Display, Roboto } from "next/font/google";
import "./globals.css";
import "./features.css";
import "lenis/dist/lenis.css";
import { LenisProvider } from "@/components/providers/lenis-provider";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const roboto = Roboto({
  variable: "--font-roboto",
  subsets: ["latin"],
  weight: ["300", "400", "500", "700"],
});

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  style: ["normal", "italic"],
});

export const metadata: Metadata = {
  title: "KingdomRunner",
  description: "Turn every step into an epic quest.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} ${playfair.variable} ${roboto.variable} antialiased bg-black`}
      >
        <LenisProvider>{children}</LenisProvider>
      </body>
    </html>
  );
}
