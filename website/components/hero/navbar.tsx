"use client";

import Link from "next/link";
import { useLenis } from "lenis/react";

export function Navbar() {
  const lenis = useLenis();

  function scrollToFeatures(e: React.MouseEvent) {
    e.preventDefault();
    lenis?.scrollTo("#features", { duration: 1.4, easing: (t) => 1 - Math.pow(1 - t, 4) });
  }

  return (
    <nav className="absolute top-0 left-0 right-0 z-50 flex items-center justify-between px-8 py-7">
      {/* Left — hamburger + nav link */}
      <div className="flex items-center gap-6">
        <button
          aria-label="Open menu"
          className="flex flex-col gap-[5px] group cursor-pointer"
        >
          <span className="block w-6 h-[1.5px] bg-white/60 group-hover:bg-white transition-colors duration-200" />
          <span className="block w-4 h-[1.5px] bg-white/60 group-hover:bg-white transition-colors duration-200" />
        </button>
        <a
          href="#features"
          onClick={scrollToFeatures}
          className="hidden sm:block font-sans text-sm text-white/50 hover:text-white transition-colors duration-200 tracking-widest uppercase"
        >
          Features
        </a>
      </div>

      {/* Center — Logo */}
      <Link href="/" className="flex items-center gap-2.5 select-none">
        {/* Crown / Kingdom icon */}
        <svg
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          className="text-white"
        >
          <path
            d="M3 18h18M5 18V9l4 4 3-7 3 7 4-4v9"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <span className="font-serif text-white text-[1.125rem] tracking-tight">
          Waddle
        </span>
      </Link>

      {/* Right — CTA pill */}
      <Link
        href="#download"
        className="flex items-center gap-3 border border-white/25 rounded-full pl-5 pr-1.5 py-1.5 text-sm text-white/80 hover:border-white/60 hover:text-white transition-all duration-300 group"
      >
        <span className="font-serif tracking-wide text-[0.8rem]">Download</span>
        <span className="flex items-center justify-center w-7 h-7 rounded-full bg-white/10 group-hover:bg-white/20 transition-colors duration-300">
          <svg
            width="12"
            height="12"
            viewBox="0 0 12 12"
            fill="none"
            className="text-white -rotate-45"
          >
            <path
              d="M1 11L11 1M11 1H4M11 1V8"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </span>
      </Link>
    </nav>
  );
}
