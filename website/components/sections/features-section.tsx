import { Castle, ShieldAlert, Zap } from "lucide-react";
import { CalorieRing } from "@/components/sections/calorie-ring";
import { WaterTracker } from "@/components/sections/water-tracker";
import { DailyGoals } from "@/components/sections/daily-goals";
import { TerritoryMap } from "@/components/sections/territory-map";

/* ── Tiny reusable sub-components ─────────────────────── */

function SectionPill({ children }: { children: React.ReactNode }) {
  return (
    <span className="font-roboto inline-flex items-center gap-2 border border-[#96cc00]/40 bg-[#f4ffe0] text-[#78a300] rounded-full px-4 py-1.5 text-[0.7rem] font-semibold tracking-[0.2em] uppercase">
      <span className="w-1.5 h-1.5 rounded-full bg-[#96cc00]" />
      {children}
    </span>
  );
}

/* DailyGoals + TerritoryMap are interactive client components — see their respective files */

/* ── Defense Items mockup ─────────────────────────────── */
function DefenseItems() {
  const items = [
    {
      Icon: Castle,
      name: "Stone Tower",
      level: "Lv 3",
      desc: "Slows intruders by 40%",
      color: "#96cc00",
      iconBg: "#f4ffe0",
    },
    {
      Icon: ShieldAlert,
      name: "Iron Wall",
      level: "Lv 5",
      desc: "Blocks entry for 24 hrs",
      color: "#4338ca",
      iconBg: "#e0e7ff",
    },
    {
      Icon: Zap,
      name: "Shock Trap",
      level: "Lv 2",
      desc: "Stuns challenger on entry",
      color: "#8b5cf6",
      iconBg: "#f5f3ff",
    },
  ];

  return (
    <div className="flex flex-col gap-2.5 w-full">
      {items.map((item) => (
        <div
          key={item.name}
          className="flex items-center gap-3.5 bg-[#f8faff] border border-[#e0e7ff] rounded-2xl px-4 py-3.5"
        >
          {/* Icon bubble */}
          <div
            className="flex items-center justify-center flex-shrink-0 w-10 h-10 rounded-xl"
            style={{ background: item.iconBg }}
          >
            <item.Icon size={18} color={item.color} strokeWidth={2} />
          </div>

          {/* Name + desc */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <p className="font-roboto text-[#1e1b4b] text-sm font-semibold">{item.name}</p>
              <span
                className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                style={{ background: item.color + "18", color: item.color }}
              >
                {item.level}
              </span>
            </div>
            <p className="font-roboto text-[#1e1b4b]/45 text-xs">{item.desc}</p>
          </div>

          {/* Status dot */}
          <div
            className="w-2.5 h-2.5 rounded-full flex-shrink-0"
            style={{ background: item.color }}
          />
        </div>
      ))}
    </div>
  );
}

/* ── Protein Log ──────────────────────────────────────── */
function ProteinLog() {
  const entries = [
    { food: "Chicken breast", protein: 31, kcal: 165 },
    { food: "Greek yogurt", protein: 17, kcal: 130 },
    { food: "Brown rice", protein: 5, kcal: 216 },
    { food: "Eggs × 2", protein: 12, kcal: 148 },
  ];
  const goal = 120;
  const current = entries.reduce((a, e) => a + e.protein, 0);

  return (
    <div className="flex flex-col gap-2.5 w-full">
      <div className="flex items-center justify-between mb-1">
        <span className="font-roboto text-xs font-semibold text-[#1e4002]/60 uppercase tracking-wider">Today</span>
        <span className="font-roboto text-xs font-bold text-[#8b5cf6]">
          {current}g <span className="font-normal text-[#1e4002]/40">/ {goal}g protein</span>
        </span>
      </div>
      {entries.map((e) => (
        <div key={e.food} className="flex items-center gap-2">
          <div className="flex-1">
            <p className="font-roboto text-xs font-medium text-[#1e4002] leading-none mb-1">{e.food}</p>
            <div className="w-full bg-[#f5f3ff] rounded-full h-1">
              <div
                className="bg-[#8b5cf6] h-1 rounded-full protein-bar-fill"
                style={{ "--bar-width": `${(e.protein / goal) * 100}%` } as React.CSSProperties}
              />
            </div>
          </div>
          <span className="font-roboto text-[10px] text-[#8b5cf6] font-bold w-10 text-right flex-shrink-0">
            {e.protein}g
          </span>
        </div>
      ))}
    </div>
  );
}

/* DailyGoals is now an interactive client component — see daily-goals.tsx */

/* ══════════════════════════════════════════════════════
   MAIN FEATURE SECTION
════════════════════════════════════════════════════════ */
export function FeaturesSection() {
  return (
    <section id="features" className="bg-[#000000] relative z-10" style={{ marginTop: -2 }}>
      {/* ── Soft blur transition from hero using radial gradient & border radius ───────── */}
      <div className="bg-white w-full rounded-t-[40px] sm:rounded-t-[60px] pt-12 mt-4 relative overflow-hidden">
        {/* Subtle top inner shadow/glow to blend edge */}
        <div className="absolute top-0 inset-x-0 h-16 bg-gradient-to-b from-[#f8f8f8] to-transparent pointer-events-none" />

        {/* ── Section header ────────────────────────── */}
        <div className="px-6 pt-12 pb-20 mx-auto max-w-7xl relative z-10">
        <div className="flex flex-col items-center gap-4 mb-16 text-center">
          <SectionPill>What You Get</SectionPill>
          <h2 className="font-serif text-[clamp(2.4rem,5vw,4rem)] font-bold text-[#1e4002] leading-[1.1] tracking-tight max-w-2xl">
            Walk more.<br />
            <span className="italic font-normal text-[#96cc00]">Rule everything.</span>
          </h2>
          <p className="font-roboto text-[#1e4002]/50 max-w-md text-base leading-relaxed">
            Every step you take on real streets becomes power. Claim turf, build defenses, track your body — all in one app.
          </p>
        </div>

        {/* ════════════════════════════════════════════
            FEATURE CARD 1 — Territory System
            Screenshot ref: left mockup, right text
        ═══════════════════════════════════════════*/}
        <div className="rounded-3xl bg-[#0c1f00] overflow-hidden mb-6 grid grid-cols-1 lg:grid-cols-2 min-h-[440px]">

          {/* Left — territory map mockup */}
          <div className="relative flex flex-col items-center justify-center gap-6 p-10 bg-[#0c1f00]">
            {/* Faint grid background */}
            <div
              className="absolute inset-0 opacity-[0.04]"
              style={{
                backgroundImage: "linear-gradient(#96cc00 1px, transparent 1px), linear-gradient(90deg, #96cc00 1px, transparent 1px)",
                backgroundSize: "24px 24px",
              }}
            />
            {/* Map card */}
            <div className="relative z-10 bg-[#1e4002]/60 backdrop-blur border border-[#96cc00]/20 rounded-2xl p-5 w-full max-w-[280px]">
              <TerritoryMap />
            </div>

            {/* Floating stat pills */}
            <div className="relative z-10 flex flex-wrap justify-center gap-3">
              {[
                { val: "2.4 km²", label: "Territory" },
                { val: "12 days", label: "Streak" },
              ].map((s) => (
                <div
                  key={s.label}
                  className="bg-[#96cc00]/10 border border-[#96cc00]/25 rounded-full px-4 py-2 text-center"
                >
                  <p className="font-roboto text-[#96cc00] font-bold text-sm">{s.val}</p>
                  <p className="font-roboto text-white/40 text-[10px]">{s.label}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Right — text */}
          <div className="flex flex-col justify-center p-10 lg:p-14">
            <p className="font-roboto text-[#96cc00] text-xs font-bold tracking-[0.2em] uppercase mb-4">
              01 — Territory
            </p>
            <h3 className="font-serif text-[clamp(2rem,3.5vw,2.8rem)] font-bold text-white leading-[1.1] mb-5">
              Walk it.<br />
              Own it.<br />
              <span className="italic text-[#96cc00]">Defend it.</span>
            </h3>
            <p className="max-w-sm mb-8 text-base leading-relaxed font-roboto text-white/50">
              Every route you walk daily becomes your territory on the real map. Skip a day? Someone else can challenge it. Your streaks literally guard your kingdom.
            </p>
            <ul className="flex flex-col gap-3">
              {[
                "Auto-claim routes you walk 3 days in a row",
                "Challenger notifications when someone enters your zone",
                "Territory grows bigger the longer your streak",
              ].map((item) => (
                <li key={item} className="flex items-start gap-3">
                  <span className="mt-0.5 w-4 h-4 rounded-full bg-[#96cc00]/20 flex items-center justify-center flex-shrink-0">
                    <svg viewBox="0 0 8 6" width="8" height="6" fill="none">
                      <path d="M1 3l2 2 4-4" stroke="#96cc00" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                  <span className="text-sm font-roboto text-white/60">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* ════════════════════════════════════════════
            FEATURE CARD 2 — Defense System
            Screenshot ref: text left, items right
        ═══════════════════════════════════════════*/}
        <div className="rounded-3xl bg-[#dbeafe] overflow-hidden mb-6 grid grid-cols-1 lg:grid-cols-2 min-h-[400px]">

          {/* Left — text */}
          <div className="flex flex-col justify-center order-2 p-10 lg:p-14 lg:order-1">
            <p className="font-roboto text-[#4338ca] text-xs font-bold tracking-[0.2em] uppercase mb-4">
              02 — Kingdom Defense
            </p>
            <h3 className="font-serif text-[clamp(2rem,3.5vw,2.8rem)] font-bold text-[#1e1b4b] leading-[1.1] mb-5">
              Build walls.<br />
              Set traps.<br />
              <span className="italic text-[#4338ca]">Stay undefeated.</span>
            </h3>
            <p className="font-roboto text-[#1e1b4b]/60 text-base leading-relaxed mb-8 max-w-sm">
              Use items you earn from walking streaks to fortify your territory. Towers slow down challengers. Walls block entry. Traps make them think twice.
            </p>
            <ul className="flex flex-col gap-3">
              {[
                "Earn defense items from weekly walking goals",
                "Place towers, walls & traps on your territory",
                "Beat quests to unlock rare legendary items",
              ].map((item) => (
                <li key={item} className="flex items-start gap-3">
                  <span className="mt-0.5 w-4 h-4 rounded-full bg-[#4338ca]/15 flex items-center justify-center flex-shrink-0">
                    <svg viewBox="0 0 8 6" width="8" height="6" fill="none">
                      <path d="M1 3l2 2 4-4" stroke="#4338ca" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                  <span className="font-roboto text-[#1e1b4b]/70 text-sm">{item}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Right — defense items mockup */}
          <div className="relative flex flex-col items-center justify-center order-1 gap-6 p-10 lg:order-2">
            {/* Faint pattern */}
            <div
              className="absolute inset-0 opacity-[0.06]"
              style={{
                backgroundImage: "radial-gradient(circle, #4338ca 1px, transparent 1px)",
                backgroundSize: "20px 20px",
              }}
            />
            <div className="relative z-10 bg-white border border-[#e0e7ff] rounded-2xl p-5 w-full max-w-[360px] shadow-sm">
              <div className="flex items-center justify-between mb-5">
                <span className="font-roboto text-[10px] text-[#4338ca] font-bold tracking-widest uppercase">Defense Loadout</span>
                <span className="font-roboto text-[10px] text-[#1e1b4b]/40 font-medium">3 / 6 slots</span>
              </div>
              <DefenseItems />
            </div>
            {/* XP badge */}
            <div className="relative z-10 inline-flex items-center gap-2 bg-[#4338ca] text-white rounded-full px-5 py-2.5 text-sm font-semibold shadow-lg">
              <span className="font-roboto">+240 XP</span>
              <span className="text-xs font-normal font-roboto text-white/60">from last defense</span>
            </div>
          </div>
        </div>

        {/* ════════════════════════════════════════════
            BENTO GRID — 4 smaller feature cards
        ═══════════════════════════════════════════*/}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">

          {/* Card 3 — Calorie Burn */}
          <div className="rounded-3xl border border-[#e0e7ff] bg-[#f4ffe0] p-8 flex flex-col gap-6">
            <div>
              <p className="font-roboto text-[#96cc00] text-xs font-bold tracking-[0.2em] uppercase mb-3">
                03 — Calorie Tracker
              </p>
              <h3 className="font-serif text-2xl font-bold text-[#1e4002] leading-tight mb-2">
                See every calorie.<br />
                <span className="italic font-normal text-[#78a300]">Burn more than you eat.</span>
              </h3>
              <p className="font-roboto text-[#1e4002]/50 text-sm leading-relaxed">
                Real-time calorie burn from your walks. Log what you eat. Your daily target — right on your wrist.
              </p>
            </div>
            <CalorieRing />
          </div>

          {/* Card 4 — Water Reminder */}
          <div className="rounded-3xl border border-[#e0e7ff] bg-white p-8 flex flex-col gap-6">
            <div>
              <p className="font-roboto text-[#4338ca] text-xs font-bold tracking-[0.2em] uppercase mb-3">
                04 — Hydration
              </p>
              <h3 className="font-serif text-2xl font-bold text-[#1e1b4b] leading-tight mb-2">
                Stay hydrated.<br />
                <span className="italic font-normal text-[#4338ca]">We&apos;ll remind you.</span>
              </h3>
              <p className="font-roboto text-[#1e1b4b]/50 text-sm leading-relaxed">
                Smart nudges timed to your walk schedule. One tap to log a glass. No more forgetting.
              </p>
            </div>
            <WaterTracker />
          </div>

          {/* Card 5 — Protein Log */}
          <div className="rounded-3xl border border-[#e0e7ff] bg-white p-8 flex flex-col gap-6">
            <div>
              <p className="font-roboto text-[#8b5cf6] text-xs font-bold tracking-[0.2em] uppercase mb-3">
                05 — Protein Log
              </p>
              <h3 className="font-serif text-2xl font-bold text-[#1e1b4b] leading-tight mb-2">
                Food in.<br />
                <span className="italic font-normal text-[#8b5cf6]">Macros calculated.</span>
              </h3>
              <p className="font-roboto text-[#1e1b4b]/50 text-sm leading-relaxed">
                Type in what you ate — the app figures out protein, carbs, and fat for you. Set a protein target, watch it fill up.
              </p>
            </div>
            <ProteinLog />
          </div>

          {/* Card 6 — Daily Goals */}
          <div className="rounded-3xl border border-[#e0e7ff] bg-[#f5f3ff] p-8 flex flex-col gap-6">
            <div>
              <p className="font-roboto text-[#8b5cf6] text-xs font-bold tracking-[0.2em] uppercase mb-3">
                06 — Daily Quest
              </p>
              <h3 className="font-serif text-2xl font-bold text-[#1e1b4b] leading-tight mb-2">
                Your goals.<br />
                <span className="italic font-normal text-[#8b5cf6]">Your rules.</span>
              </h3>
              <p className="font-roboto text-[#1e1b4b]/50 text-sm leading-relaxed">
                Set daily calorie and protein goals. Complete them, earn XP, level up your runner. Miss them — your territory weakens.
              </p>
            </div>
            <DailyGoals />
          </div>

        </div>
        {/* ── End bento grid ─────────────────────── */}

      </div>
      {/* ── End inner white wrapper ────────────────────── */}
      </div>
    </section>
  );
}
