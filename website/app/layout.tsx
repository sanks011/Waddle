import type { Metadata } from "next";
import { Geist, Geist_Mono, Playfair_Display, Roboto, Great_Vibes, Cinzel_Decorative, Dancing_Script, Abril_Fatface } from "next/font/google";
import "./globals.css";
import "./features.css";
import "lenis/dist/lenis.css";
import { LenisProvider } from "@/components/providers/lenis-provider";
import { SmoothCursor } from "@/components/ui/smooth-cursor";

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

const greatVibes = Great_Vibes({
  variable: "--font-great-vibes",
  subsets: ["latin"],
  weight: "400",
});

const cinzel = Cinzel_Decorative({
  variable: "--font-cinzel",
  subsets: ["latin"],
  weight: ["400", "700", "900"],
});

const dancing = Dancing_Script({
  variable: "--font-dancing",
  subsets: ["latin"],
  weight: ["400", "700"],
});

const abril = Abril_Fatface({
  variable: "--font-abril",
  subsets: ["latin"],
  weight: "400",
});

export const metadata: Metadata = {
  title: "Waddle",
  description: "Turn every step into an epic quest.",
  icons: {
    icon: [
      { url: "/penguin.svg", type: "image/svg+xml" },
    ],
    apple: "/penguin.svg",
    shortcut: "/penguin.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        suppressHydrationWarning
        className={`${geistSans.variable} ${geistMono.variable} ${playfair.variable} ${roboto.variable} ${greatVibes.variable} ${cinzel.variable} ${dancing.variable} ${abril.variable} antialiased bg-black`}
      >
        <SmoothCursor />
        <LenisProvider>{children}</LenisProvider>
      </body>
    </html>
  );
}
