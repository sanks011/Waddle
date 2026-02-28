"use client";

import { useEffect, useState } from "react";
import { useLenis } from "lenis/react";

export function BackToTop() {
  const [visible, setVisible] = useState(false);
  const lenis = useLenis();

  useEffect(() => {
    const onScroll = () => {
      const scrolled = window.scrollY + window.innerHeight;
      const total = document.documentElement.scrollHeight;
      // Show when user has scrolled past 60% of the page
      setVisible(scrolled / total > 0.6);
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const scrollToTop = () => {
    lenis?.scrollTo(0, {
      duration: 1.6,
      easing: (t) => 1 - Math.pow(1 - t, 4),
    });
  };

  return (
    <button
      onClick={scrollToTop}
      aria-label="Back to top"
      className="cursor-pointer fixed bottom-8 right-8 z-[9997] flex items-center justify-center w-12 h-12 rounded-full bg-[#96cc00] shadow-lg transition-all duration-300"
      style={{
        opacity: visible ? 1 : 0,
        transform: visible ? "translateY(0) scale(1)" : "translateY(20px) scale(0.8)",
        pointerEvents: visible ? "auto" : "none",
        boxShadow: "0 4px 24px rgba(150,204,0,0.45)",
      }}
    >
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="#1a3800"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M12 19V5M5 12l7-7 7 7" />
      </svg>
    </button>
  );
}
