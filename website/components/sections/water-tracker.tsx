"use client";

import { useEffect, useRef, useState } from "react";

/* ─── Glass data — varied fill levels for visual depth ───── */
const GLASSES = [
  { fill: 95, delay: 0    }, // full
  { fill: 93, delay: 150  }, // full
  { fill: 90, delay: 300  }, // full
  { fill: 68, delay: 450  }, // drops
  { fill: 46, delay: 580  }, // drops more
  { fill: 26, delay: 700  }, // low
  { fill: 10, delay: 820  }, // nearly empty
  { fill: 0,  delay: 0    }, // empty
];

const FILLED_COUNT = GLASSES.filter((g) => g.fill > 0).length;
const TOTAL        = GLASSES.length;

/* ─── CSS keyframes injected once ───────────────────────── */
const CSS = `
  @keyframes waveA {
    0%   { transform: translateX(0); }
    100% { transform: translateX(-50%); }
  }
  @keyframes waveB {
    0%   { transform: translateX(-50%); }
    100% { transform: translateX(0); }
  }
  @keyframes waveC {
    0%   { transform: translateX(0); }
    100% { transform: translateX(-50%); }
  }
  @keyframes slosh {
    0%   { transform: skewX(0deg)   translateX(0); }
    18%  { transform: skewX(-6deg)  translateX(-4px); }
    36%  { transform: skewX(5deg)   translateX(4px); }
    52%  { transform: skewX(-3deg)  translateX(-2px); }
    66%  { transform: skewX(2deg)   translateX(2px); }
    80%  { transform: skewX(-1deg)  translateX(-1px); }
    100% { transform: skewX(0deg)   translateX(0); }
  }
  @keyframes glassAppear {
    0%   { opacity: 0; transform: translateY(8px) scale(0.92); }
    100% { opacity: 1; transform: translateY(0)   scale(1); }
  }
  @keyframes bubbleUp {
    0%   { transform: translateY(0)    scale(1);    opacity: 0.7; }
    80%  { opacity: 0.4; }
    100% { transform: translateY(-90px) scale(0.5); opacity: 0; }
  }
  @keyframes glowPulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(99,102,241,0); }
    50%       { box-shadow: 0 4px 20px 2px rgba(99,102,241,0.28); }
  }
  @keyframes dropIn {
    0%   { height: 0%;        }
    60%  { height: calc(var(--target-fill) * 1.04); }
    80%  { height: calc(var(--target-fill) * 0.97); }
    100% { height: var(--target-fill); }
  }
`;

function Bubble({ left, duration, delay }: { left: string; duration: string; delay: string }) {
  return (
    <div
      className="absolute bottom-[8%] rounded-full bg-white/40"
      style={{
        left,
        width: 3, height: 3,
        animation: `bubbleUp ${duration} ease-in infinite ${delay}`,
      }}
    />
  );
}

function GlassCup({
  fill, delay, animate,
}: {
  fill: number; delay: number; animate: boolean;
}) {
  const [poured,  setPoured]  = useState(false);
  const [settled, setSettled] = useState(false);
  const isFilled = fill > 0;

  useEffect(() => {
    if (!animate || !isFilled) return;
    const t1 = setTimeout(() => setPoured(true),  delay);
    const t2 = setTimeout(() => setSettled(true), delay + 950);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [animate, isFilled, delay]);

  return (
    <div
      style={{
        width: 38, height: 52, position: "relative",
        animation: animate && isFilled
          ? `glassAppear 0.4s cubic-bezier(0.34,1.56,0.64,1) ${delay}ms both`
          : undefined,
      }}
    >
      {/* ── Water fill layer (clipped to glass shape) ── */}
      <div
        className="absolute inset-0 overflow-hidden"
        style={{ clipPath: "polygon(13% 3%, 87% 3%, 79% 97%, 21% 97%)", zIndex: 1 }}
      >
        {/* Water body */}
        <div
          className="absolute bottom-0 left-0 right-0"
          style={{
            ["--target-fill" as string]: `${fill}%`,
            height: poured ? `${fill}%` : "0%",
            background: "linear-gradient(180deg, #818cf8 0%, #4338ca 60%, #3730a3 100%)",
            transition: poured
              ? `height 0.85s cubic-bezier(0.22, 1, 0.36, 1) 0ms`
              : undefined,
            animation: settled ? `slosh 1.1s ease-out forwards` : undefined,
          }}
        >
          {/* Wave layer 1 — primary */}
          <div
            className="absolute w-[200%]"
            style={{
              top: -7, height: 10, left: 0,
              animation: "waveA 1.6s linear infinite",
            }}
          >
            <svg viewBox="0 0 76 10" preserveAspectRatio="none" className="w-full h-full">
              <path d="M0 5 Q9.5 0 19 5 Q28.5 10 38 5 Q47.5 0 57 5 Q66.5 10 76 5 L76 10 L0 10 Z"
                fill="rgba(129,140,248,0.9)" />
            </svg>
          </div>
          {/* Wave layer 2 — secondary, opposite direction */}
          <div
            className="absolute w-[200%]"
            style={{
              top: -5, height: 8, left: 0,
              animation: "waveB 2.3s linear infinite",
              opacity: 0.55,
            }}
          >
            <svg viewBox="0 0 76 8" preserveAspectRatio="none" className="w-full h-full">
              <path d="M0 4 Q9.5 8 19 4 Q28.5 0 38 4 Q47.5 8 57 4 Q66.5 0 76 4 L76 8 L0 8 Z"
                fill="#6366f1" />
            </svg>
          </div>
          {/* Wave layer 3 — deep, slow */}
          <div
            className="absolute w-[200%]"
            style={{
              top: -3, height: 6, left: 0,
              animation: "waveC 3.4s linear infinite",
              opacity: 0.3,
            }}
          >
            <svg viewBox="0 0 76 6" preserveAspectRatio="none" className="w-full h-full">
              <path d="M0 3 Q19 0 38 3 Q57 6 76 3 L76 6 L0 6 Z" fill="#4338ca" />
            </svg>
          </div>

          {/* Bubbles — only when settled */}
          {settled && fill > 50 && (
            <>
              <Bubble left="22%" duration="2.8s" delay="0.1s" />
              <Bubble left="55%" duration="3.5s" delay="0.9s" />
              <Bubble left="38%" duration="4.1s" delay="1.8s" />
            </>
          )}

          {/* Water sheen */}
          <div className="absolute top-[10%] left-[15%] rounded-full"
            style={{ width: "35%", height: "10%",
              background: "rgba(255,255,255,0.22)", filter: "blur(3px)" }} />
        </div>
      </div>

      {/* ── Glass outline (on top) ── */}
      <svg viewBox="0 0 38 52" fill="none"
        className="absolute inset-0 w-full h-full"
        style={{
          zIndex: 2, pointerEvents: "none",
          filter: settled && isFilled
            ? "drop-shadow(0 3px 8px rgba(99,102,241,0.35))"
            : "none",
          transition: "filter 0.6s ease",
        }}
      >
        {/* Body */}
        <path d="M5 2 L33 2 L30 50 L8 50 Z"
          fill="rgba(255,255,255,0.06)"
          stroke={poured ? "#818cf8" : "#dde1f9"}
          strokeWidth="1.5"
          style={{ transition: "stroke 0.5s ease" }}
        />
        {/* Left highlight */}
        <path d="M10 7 L9 43" stroke="rgba(255,255,255,0.6)"
          strokeWidth="1.5" strokeLinecap="round" />
        {/* Right soft highlight */}
        <path d="M27 8 L28 38" stroke="rgba(255,255,255,0.2)"
          strokeWidth="1" strokeLinecap="round" />
        {/* Top rim glint */}
        <path d="M7 2.5 L31 2.5" stroke="rgba(255,255,255,0.55)"
          strokeWidth="1" strokeLinecap="round" />
        {/* Bottom base */}
        <path d="M9 50 L29 50" stroke={poured ? "#6366f1" : "#e0e7ff"}
          strokeWidth="2" strokeLinecap="round"
          style={{ transition: "stroke 0.5s ease" }}
        />
      </svg>
    </div>
  );
}

/* ─── Main export ────────────────────────────────────────── */
export function WaterTracker() {
  const ref = useRef<HTMLDivElement>(null);
  const [animate,  setAnimate]  = useState(false);
  const [barWidth, setBarWidth] = useState(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) { setAnimate(true); obs.disconnect(); }
    }, { threshold: 0.35 });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  useEffect(() => {
    if (!animate) return;
    const t = setTimeout(
      () => setBarWidth((FILLED_COUNT / TOTAL) * 100),
      GLASSES[FILLED_COUNT - 1].delay + 1100
    );
    return () => clearTimeout(t);
  }, [animate]);

  return (
    <div ref={ref} className="flex flex-col items-start gap-4">
      <style>{CSS}</style>

      {/* Glasses */}
      <div className="flex gap-2.5 flex-wrap items-end">
        {GLASSES.map((g, i) => (
          <GlassCup key={i} fill={g.fill} delay={g.delay} animate={animate} />
        ))}
      </div>

      {/* Label */}
      <p className="font-roboto text-sm font-semibold text-[#1e4002]">
        {FILLED_COUNT} of {TOTAL} glasses
      </p>

      {/* Progress bar */}
      <div className="w-full bg-[#e0e7ff] rounded-full h-1.5 overflow-hidden">
        <div
          className="h-1.5 rounded-full"
          style={{
            width: `${barWidth}%`,
            background: "linear-gradient(90deg, #818cf8, #4338ca)",
            transition: "width 1s cubic-bezier(0.16, 1, 0.3, 1)",
          }}
        />
      </div>

      {/* Quote */}
      <p className="font-roboto text-[11px] text-[#1e1b4b]/40 leading-relaxed italic border-l-2 border-[#c7d2fe] pl-3">
        Humans should drink <span className="font-semibold not-italic text-[#4338ca]/60">6–8 glasses</span> of water daily —
        roughly <span className="font-semibold not-italic text-[#4338ca]/60">2–3 litres</span> to stay healthy &amp; energized.
      </p>    </div>
  );
}