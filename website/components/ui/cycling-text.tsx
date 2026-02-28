"use client";

import { useEffect, useState } from "react";

const STYLES = [
  {
    // Playfair Display — original elegant italic serif
    fontVar: "var(--font-playfair)",
    fontStyle: "italic",
    fontWeight: 700,
    letterSpacing: "-0.025em",
    label: "playfair",
  },
  {
    // Great Vibes — flowing royal calligraphy
    fontVar: "var(--font-great-vibes)",
    fontStyle: "normal",
    fontWeight: 400,
    letterSpacing: "0.02em",
    label: "great-vibes",
  },
  {
    // Cinzel Decorative — Roman/medieval carved caps
    fontVar: "var(--font-cinzel)",
    fontStyle: "normal",
    fontWeight: 700,
    letterSpacing: "0.04em",
    label: "cinzel",
  },
  {
    // Dancing Script — handwritten quest-scroll
    fontVar: "var(--font-dancing)",
    fontStyle: "normal",
    fontWeight: 700,
    letterSpacing: "-0.01em",
    label: "dancing",
  },
  {
    // Abril Fatface — heavy dramatic display
    fontVar: "var(--font-abril)",
    fontStyle: "italic",
    fontWeight: 400,
    letterSpacing: "-0.02em",
    label: "abril",
  },
];

const DISPLAY_MS = 2800;
const TRANSITION_MS = 500;

export function CyclingText({ text, className }: { text: string; className?: string }) {
  const [index, setIndex] = useState(0);
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const cycle = setInterval(() => {
      // Fade out
      setVisible(false);
      setTimeout(() => {
        setIndex((i) => (i + 1) % STYLES.length);
        // Fade in
        setVisible(true);
      }, TRANSITION_MS);
    }, DISPLAY_MS + TRANSITION_MS);

    return () => clearInterval(cycle);
  }, []);

  const s = STYLES[index];

  return (
    <span
      className={className}
      style={{
        fontFamily: s.fontVar,
        fontStyle: s.fontStyle,
        fontWeight: s.fontWeight,
        letterSpacing: s.letterSpacing,
        display: "inline-block",
        opacity: visible ? 1 : 0,
        filter: visible ? "blur(0px)" : "blur(10px)",
        transform: visible ? "translateY(0)" : "translateY(-12px)",
        transition: `opacity ${TRANSITION_MS}ms cubic-bezier(0.4,0,0.2,1), filter ${TRANSITION_MS}ms cubic-bezier(0.4,0,0.2,1), transform ${TRANSITION_MS}ms cubic-bezier(0.4,0,0.2,1)`,
        willChange: "opacity, filter, transform",
      }}
    >
      {text}
    </span>
  );
}
