"use client";

import { useEffect, useRef } from "react";
import confetti from "canvas-confetti";
import { Navbar } from "./navbar";
import { DownloadButton } from "@/components/ui/download-button";
import { CyclingText } from "@/components/ui/cycling-text";

export function HeroSection() {
    const videoRef = useRef<HTMLVideoElement>(null);

    useEffect(() => {
        const video = videoRef.current;
        if (!video) return;

        const FADE = 0.9;   // seconds to fade in / out
        const MAX_OP = 0.9; // peak opacity
        let rafId: number;

        const tick = () => {
            if (video.duration && !video.paused) {
                const t = video.currentTime;
                const remaining = video.duration - t;
                let op: number;

                if (t < FADE) {
                    op = (t / FADE) * MAX_OP;
                } else if (remaining < FADE) {
                    op = (remaining / FADE) * MAX_OP;
                } else {
                    op = MAX_OP;
                }

                video.style.opacity = op.toString();
            }
            rafId = requestAnimationFrame(tick);
        };

        rafId = requestAnimationFrame(tick);
        return () => cancelAnimationFrame(rafId);
    }, []);

    return (
        <section className="relative min-h-screen w-full bg-[#000000] overflow-hidden">

            {/* ── Background video ──────────────────────────────── */}
            <video
                ref={videoRef}
                src="/Sky_changing.mp4"
                autoPlay
                muted
                loop
                playsInline
                className="absolute inset-0 object-cover object-center w-full h-full"
                style={{ opacity: 0, willChange: "opacity" }}
            />

            {/* ── Dark gradient overlay so text stays legible ───── */}
            <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/20 to-black z-[1]" />

            {/* ── Navbar ────────────────────────────────────────── */}
            <Navbar />

            {/* ── Hero copy — upper portion of viewport ────────── */}
            {/*
        Mirror the screenshot layout:
        content lives in the top ~32% so the image can breathe below.
        Text is horizontally centred with a flush left / right rhythm
        created by the two-line headline split.
      */}
            <div className="absolute inset-x-0 top-0 flex flex-col items-center text-center pt-16 sm:pt-[7.5rem] px-5 sm:px-6 z-[2]">

                {/* ── Launch badge ─────────────────────────────── */}
                <button
                    type="button"
                    onClick={() =>
                        confetti({
                            particleCount: 120,
                            spread: 80,
                            origin: { y: 0.35 },
                            colors: ["#96cc00", "#ffffff", "#a8e000", "#f4ffe0", "#1e4002"],
                        })
                    }
                    className="group inline-flex items-center bg-white/[0.06] border border-white/10 rounded-full pl-4 pr-1 py-1 mb-5 sm:mb-8 cursor-pointer hover:border-white/20 hover:bg-white/[0.12] transition-all duration-300"
                >
                    {/* Text */}
                    <span className="font-sans text-[0.75rem] font-medium text-white/60 group-hover:text-white transition-colors duration-300 tracking-wide">
                        We just launched!
                    </span>
                    {/* Divider */}
                    <span className="flex-shrink-0 w-px h-4 mx-3 bg-white/20" />
                    {/* Icon box */}
                    <span className="w-7 h-7 rounded-full bg-white/[0.08] border border-white/10 flex items-center justify-center text-[0.8rem] leading-none group-hover:bg-white/[0.22] group-hover:border-white/30 transition-all duration-300">
                        🎉
                    </span>
                </button>

                {/* ── Main headline ───────────────────────────────── */}
                {/*
          Two-line split like the reference screenshot.
          Line 1 — lighter / regular weight → sets the subject
          Line 2 — italic bold         → lands the punch
        */}
                <h1 className="font-serif leading-[1.08] select-none w-full">
                    {/* line 1 */}
                    <span className="block text-[clamp(2.2rem,7vw,6.5rem)] font-normal text-white/90 tracking-[-0.02em]">
                        Every Step,
                    </span>
                    {/* line 2 */}
                    <span className="block text-[clamp(2.2rem,7vw,6.5rem)] text-white tracking-[-0.025em]">
                        <CyclingText text="A New Quest." />
                    </span>
                </h1>

                {/* ── Subtitle ────────────────────────────────────── */}
                <p className="mt-5 sm:mt-6 max-w-sm sm:max-w-md text-[clamp(0.9rem,1.8vw,1.05rem)] text-white/80 font-sans leading-relaxed tracking-wide">
                    Walk, jog, or sprint — watch your kingdom grow.<br className="hidden sm:block" />
                    Earn rewards, beat quests, and enjoy moving.
                </p>
                {/* ── Download CTA ──────────────────────────────── */}
                <div className="mt-8">
                    <DownloadButton />
                </div>            </div>

            {/* ── Scroll indicator — anchored to bottom ────────── */}
            <div className="absolute bottom-10 inset-x-0 flex flex-col items-center gap-3 pointer-events-none z-[2]">
                {/* thin animated line */}
                <div className="w-[1px] h-10 overflow-hidden">
                    <div className="w-full h-full bg-gradient-to-b from-transparent via-white/40 to-transparent animate-scrollLine" />
                </div>
                {/* chevron */}
                <svg
                    width="14"
                    height="8"
                    viewBox="0 0 14 8"
                    fill="none"
                    className="text-white/30 animate-bounce"
                    style={{ animationDelay: "0.3s" }}
                >
                    <path
                        d="M1 1l6 6 6-6"
                        stroke="currentColor"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                    />
                </svg>
            </div>
        </section>
    );
}
