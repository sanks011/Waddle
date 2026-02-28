import { Navbar } from "./navbar";

export function HeroSection() {
  return (
    <section className="relative min-h-screen w-full bg-[#000000] overflow-hidden">
      {/* ── Navbar ────────────────────────────────────────── */}
      <Navbar />

      {/* ── Hero copy — upper portion of viewport ────────── */}
      {/*
        Mirror the screenshot layout:
        content lives in the top ~32% so the image can breathe below.
        Text is horizontally centred with a flush left / right rhythm
        created by the two-line headline split.
      */}
      <div className="absolute inset-x-0 top-0 flex flex-col items-center text-center pt-[7.5rem] px-6">

        {/* ── Tiny badge ──────────────────────────────────── */}
        <div className="inline-flex items-center gap-2 border border-white/15 rounded-full px-4 py-1.5 mb-8">
          <span className="w-1.5 h-1.5 rounded-full bg-white/60" />
          <span className="text-[0.7rem] text-white/50 tracking-[0.22em] uppercase font-[family-name:var(--font-geist-sans)]">
            Gamified Cardio · Walk &amp; Jog
          </span>
        </div>

        {/* ── Main headline ───────────────────────────────── */}
        {/*
          Two-line split like the reference screenshot.
          Line 1 — lighter / regular weight → sets the subject
          Line 2 — italic bold         → lands the punch
        */}
        <h1 className="font-[family-name:var(--font-playfair)] leading-[1.08] select-none">
          {/* line 1 */}
          <span className="block text-[clamp(3rem,8vw,6.5rem)] font-[400] text-white/90 tracking-[-0.02em]">
            Every Step,
          </span>
          {/* line 2 */}
          <span className="block text-[clamp(3rem,8vw,6.5rem)] font-[700] italic text-white tracking-[-0.025em]">
            A New Quest.
          </span>
        </h1>

        {/* ── Subtitle ────────────────────────────────────── */}
        <p className="mt-6 max-w-md text-[clamp(0.875rem,1.5vw,1rem)] text-white/40 font-[family-name:var(--font-geist-sans)] leading-relaxed tracking-wide">
          Walk, jog, or sprint — and watch your kingdom grow.<br className="hidden sm:block" />
          Earn rewards, beat quests, and actually enjoy moving.
        </p>
      </div>

      {/* ── Scroll indicator — anchored to bottom ────────── */}
      <div className="absolute bottom-10 inset-x-0 flex flex-col items-center gap-3 pointer-events-none">
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
