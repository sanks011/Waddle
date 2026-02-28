"use client";

import { useState, useCallback } from "react";
import { Check } from "lucide-react";
import confetti from "canvas-confetti";

const INITIAL_GOALS = [
  { label: "Burn 500 kcal",    done: true  },
  { label: "Walk 6,000 steps", done: true  },
  { label: "Drink 8 glasses",  done: false },
  { label: "Hit 120g protein", done: false },
  { label: "Defend territory", done: true  },
];

const COLORS = ["#96cc00", "#4338ca", "#8b5cf6", "#facc15", "#f472b6", "#34d399"];

export function DailyGoals() {
  const [goals, setGoals] = useState(INITIAL_GOALS);

  const toggle = useCallback((index: number, e: React.MouseEvent) => {
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top  + rect.height / 2;
    const wasUnchecked = !goals[index].done;

    setGoals((prev) =>
      prev.map((g, i) => (i === index ? { ...g, done: !g.done } : g))
    );

    if (wasUnchecked) {
      const origin = { x: cx / window.innerWidth, y: cy / window.innerHeight };
      confetti({ particleCount: 80, spread: 70, startVelocity: 30, origin, colors: COLORS, ticks: 200, scalar: 0.9, gravity: 0.8 });
    }
  }, [goals]);

  const doneCount = goals.filter((g) => g.done).length;

  return (
    <div className="flex flex-col gap-2.5 w-full">
      {/* Header row */}
      <div className="flex items-center justify-between mb-1">
        <span className="font-roboto text-xs font-semibold text-[#1e4002]/60 uppercase tracking-wider">
          Daily Quest
        </span>
        <span className="font-roboto text-xs bg-[#96cc00]/20 text-[#78a300] font-bold px-2 py-0.5 rounded-full transition-all duration-300">
          {doneCount} / {goals.length}
        </span>
      </div>

      {/* Goal rows */}
      {goals.map((g, i) => (
        <div key={g.label} className="flex items-center gap-3">
          {/* Checkbox button */}
          <button
            onClick={(e) => toggle(i, e)}
            aria-label={g.done ? `Uncheck ${g.label}` : `Check ${g.label}`}
            className={`
              w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0
              cursor-pointer select-none outline-none
              transition-all duration-200 ease-out
              focus-visible:ring-2 focus-visible:ring-offset-1 focus-visible:ring-[#96cc00]
              ${g.done
                ? "bg-[#96cc00] scale-[1.08] shadow-[0_0_0_3px_rgba(150,204,0,0.25)]"
                : "border-2 border-[#e0e7ff] hover:border-[#96cc00]/60 hover:scale-105"
              }
            `}
          >
            {g.done && (
              <Check size={11} color="white" strokeWidth={3} />
            )}
          </button>

          {/* Label */}
          <span
            className={`font-roboto text-sm transition-all duration-300 ${
              g.done
                ? "line-through text-[#1e4002]/40"
                : "text-[#1e4002] font-medium"
            }`}
          >
            {g.label}
          </span>
        </div>
      ))}
    </div>
  );
}
