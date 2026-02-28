"use client";

import { useEffect, useRef, useState } from "react";
import { AnimatedCircularProgressBar } from "@/components/ui/animated-circular-progress-bar";

const TARGET   = 1860;
const MAX      = 2500;
const DURATION = 2000; // ms

/* ── Zone definitions ─────────────────────────────────── */
type Zone = {
  label: string;
  primary: string;
  secondary: string;
  glow: string;
  badge: string;
  badgeText: string;
  text: string;
  sub: string;
};

function getZone(val: number): Zone {
  const pct = val / MAX;
  if (pct < 0.50) {
    return {
      label:     "LOW",
      primary:   "#4338ca",
      secondary: "#e0e7ff",
      glow:      "rgba(67,56,202,0.32)",
      badge:     "#e0e7ff",
      badgeText: "#4338ca",
      text:      "#1e1b4b",
      sub:       "#4338ca",
    };
  } else if (pct < 0.74) {
    return {
      label:     "ON TRACK",
      primary:   "#96cc00",
      secondary: "#e8f9c0",
      glow:      "rgba(150,204,0,0.32)",
      badge:     "#f4ffe0",
      badgeText: "#78a300",
      text:      "#1e4002",
      sub:       "#78a300",
    };
  } else {
    return {
      label:     "CRUSHING IT",
      primary:   "#8b5cf6",
      secondary: "#f5f3ff",
      glow:      "rgba(139,92,246,0.38)",
      badge:     "#f5f3ff",
      badgeText: "#8b5cf6",
      text:      "#3b0764",
      sub:       "#8b5cf6",
    };
  }
}

export function CalorieRing() {
  const [value,   setValue]   = useState(0);
  const [display, setDisplay] = useState(0);
  const ref      = useRef<HTMLDivElement>(null);
  const animated = useRef(false);

  const zone = getZone(value);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !animated.current) {
          animated.current = true;
          const start = performance.now();

          const tick = (now: number) => {
            const elapsed  = now - start;
            const progress = Math.min(elapsed / DURATION, 1);
            // ease-out quart — fast start, dramatic slow finish
            const eased   = 1 - Math.pow(1 - progress, 4);
            const current = Math.round(eased * TARGET);
            setValue(current);
            setDisplay(current);
            if (progress < 1) requestAnimationFrame(tick);
          };

          requestAnimationFrame(tick);
          observer.disconnect();
        }
      },
      { threshold: 0.35 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div ref={ref} className="flex flex-col items-center gap-4">

      {/* Ring — no glow wrapper */}
      <div className="relative flex items-center justify-center">

        {/* Progress ring */}
        <AnimatedCircularProgressBar
          max={MAX}
          min={0}
          value={value}
          gaugePrimaryColor={zone.primary}
          gaugeSecondaryColor={zone.secondary}
          className="[&>span]:hidden relative z-10"
        />

        {/* Center text overlay */}
        <div className="absolute inset-0 z-20 flex flex-col items-center justify-center pointer-events-none">
          <span
            className="font-roboto text-xl font-bold tabular-nums"
            style={{ color: zone.text, transition: "color 0.5s ease" }}
          >
            {display.toLocaleString()}
          </span>
          <span
            className="font-roboto text-[10px] font-medium"
            style={{ color: zone.sub, transition: "color 0.5s ease" }}
          >
            / 2,500 kcal
          </span>
        </div>
      </div>

      {/* Zone badge */}
      <span
        className="font-sans text-[9px] font-bold tracking-[0.18em] uppercase px-3 py-1 rounded-full"
        style={{
          background: zone.badge,
          color:      zone.badgeText,
          transition: "background 0.5s ease, color 0.5s ease",
        }}
      >
        {zone.label}
      </span>

      {/* Macro pills */}
      <div className="flex gap-4 text-center">
        {[
          { label: "Fat",     val: "38g",  color: "#96cc00" },
          { label: "Carbs",   val: "210g", color: "#4338ca" },
          { label: "Protein", val: "94g",  color: "#8b5cf6" },
        ].map((m) => (
          <div key={m.label}>
            <p className="font-roboto text-xs font-bold" style={{ color: m.color }}>{m.val}</p>
            <p className="font-roboto text-[10px] text-[#1e4002]/50">{m.label}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
