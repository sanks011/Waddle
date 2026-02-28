"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useLenis } from "lenis/react";
import { EyeButton } from "@/components/ui/eye-button";

export function Navbar() {
  const lenis = useLenis();
  const [menuOpen, setMenuOpen] = useState(false);

  function scrollToFeatures(e: React.MouseEvent) {
    e.preventDefault();
    setMenuOpen(false);
    lenis?.scrollTo("#features", { duration: 1.4, easing: (t) => 1 - Math.pow(1 - t, 4) });
  }

  function handleHamburger(e: React.MouseEvent) {
    if (window.innerWidth >= 640) {
      // Desktop — scroll directly to features, no drawer
      scrollToFeatures(e);
    } else {
      // Mobile — toggle drawer
      setMenuOpen((o) => !o);
    }
  }

  return (
    <>
      <nav className="absolute top-0 left-0 right-0 z-50 grid items-center grid-cols-3 px-8 py-7">
        {/* Left — hamburger + nav link */}
        <div className="flex items-center gap-6">
          <button
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            onClick={handleHamburger}
            className="flex flex-col gap-[5px] group cursor-pointer"
          >
            {/* X on mobile when open; hamburger always on desktop */}
            <span className={`block w-6 h-[1.5px] transition-all duration-200 ${menuOpen ? "bg-white rotate-45 translate-y-[3.5px] sm:rotate-0 sm:translate-y-0 sm:bg-white/60 sm:group-hover:bg-white" : "bg-white/60 group-hover:bg-white"}`} />
            <span className={`block h-[1.5px] transition-all duration-200 ${menuOpen ? "w-6 bg-white -rotate-45 -translate-y-[3.5px] sm:w-4 sm:rotate-0 sm:translate-y-0 sm:bg-white/60 sm:group-hover:bg-white" : "w-4 bg-white/60 group-hover:bg-white"}`} />
          </button>
        </div>

        {/* Center — Logo (truly centered via grid) */}
        <Link href="/" className="flex items-center justify-center gap-2.5 select-none">
          <Image
            src="/penguin.svg"
            alt="Waddle"
            width={40}
            height={40}
            className="object-contain"
          />
          <span className="font-serif text-white text-[1.125rem] tracking-tight">
            Waddle
          </span>
        </Link>

        {/* Right — eye-tracking button (desktop only) */}
        <div className="justify-end hidden sm:flex">
          <EyeButton />
        </div>
      </nav>

      {/* Mobile drawer — only visible on mobile, slides down from top */}
      <div
        className={`sm:hidden fixed inset-x-0 top-0 z-40 transition-transform duration-300 ease-in-out ${
          menuOpen ? "translate-y-0" : "-translate-y-full"
        }`}
      >
        {/* Backdrop blur panel */}
        <div className="flex flex-col gap-1 px-8 pt-24 pb-10 border-b bg-black/85 backdrop-blur-xl border-white/10">

          {/* Nav item */}
          <a
            href="#features"
            onClick={scrollToFeatures}
            className="flex items-center justify-between py-4 border-b border-white/10 group"
          >
            <span className="font-sans text-lg tracking-widest text-white uppercase">
              Features
            </span>
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-white/40 group-hover:text-[#96cc00] group-hover:translate-x-1 transition-all duration-200"
            >
              <path d="M5 12h14M12 5l7 7-7 7" />
            </svg>
          </a>

          {/* Tagline */}
          <p className="mt-4 font-sans text-xs tracking-widest uppercase text-white/30">
            Your kingdom awaits
          </p>
        </div>

        {/* Tap-outside backdrop */}
        <div
          className="h-screen bg-black/40"
          onClick={() => setMenuOpen(false)}
        />
      </div>
    </>
  );
}
