"use client";

import { useState } from "react";

// Cell types: 1=yours, 2=yours-edge, 3=enemy, 0=neutral
type CellType = 0 | 1 | 2 | 3;

const INITIAL_GRID: CellType[][] = [
  [0, 0, 0, 0, 1, 1, 0, 0],
  [0, 0, 0, 1, 1, 1, 1, 0],
  [0, 0, 1, 1, 1, 2, 1, 0],
  [0, 1, 1, 1, 2, 0, 0, 0],
  [0, 1, 1, 2, 0, 3, 3, 0],
  [0, 0, 2, 0, 0, 3, 0, 0],
];

const CELL_STYLES: Record<CellType, string> = {
  1: "bg-[#96cc00] hover:brightness-110",
  2: "bg-[#78a300] hover:brightness-110",
  3: "bg-red-500/70 hover:brightness-110",
  0: "bg-white/[0.06] hover:bg-white/[0.14]",
};

// Cycle: neutral → yours → enemy → neutral
const CYCLE: Record<CellType, CellType> = { 0: 1, 1: 3, 2: 1, 3: 0 };

export function TerritoryMap() {
  const [grid, setGrid] = useState<CellType[][]>(INITIAL_GRID);

  function toggleCell(row: number, col: number) {
    setGrid((prev) =>
      prev.map((r, ri) =>
        r.map((cell, ci) => (ri === row && ci === col ? CYCLE[cell] : cell))
      )
    );
  }

  const yourCells  = grid.flat().filter((c) => c === 1 || c === 2).length;
  const enemyCells = grid.flat().filter((c) => c === 3).length;

  return (
    <div className="w-full max-w-[250px] mx-auto">
      {/* Mini status bar */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="font-roboto text-[10px] text-[#96cc00] font-bold tracking-widest uppercase">
            Live Map
          </span>
          <span className="w-1.5 h-1.5 rounded-full bg-[#96cc00] animate-pulse" />
        </div>
        <span className="font-roboto text-[10px] text-white/40">Zone A-7</span>
      </div>

      {/* Grid */}
      <div
        className="grid gap-[3px]"
        style={{ gridTemplateColumns: "repeat(8, 1fr)" }}
      >
        {grid.map((row, ri) =>
          row.map((cell, ci) => (
            <button
              key={`${ri}-${ci}`}
              onClick={() => toggleCell(ri, ci)}
              title={cell === 0 ? "Claim this cell" : cell === 3 ? "Remove enemy" : "Release cell"}
              className={`
                aspect-square rounded-[3px] transition-all duration-150
                ${CELL_STYLES[cell]}
                active:scale-90
              `}
            />
          ))
        )}
      </div>

      {/* Legend + live stats */}
      <div className="flex items-center justify-between mt-3 pt-2.5 border-t border-white/10">
        <div className="flex items-center gap-3">
          {[
            { color: "#96cc00", label: "Your turf" },
            { color: "#ef4444", label: "Enemy" },
            { color: "rgba(255,255,255,0.12)", label: "Open" },
          ].map(({ color, label }) => (
            <div key={label} className="flex items-center gap-1">
              <span
                className="w-2.5 h-2.5 rounded-[2px] flex-shrink-0"
                style={{ background: color }}
              />
              <span className="font-roboto text-[9px] text-white/50">{label}</span>
            </div>
          ))}
        </div>
        <span className="font-roboto text-[9px] text-white/30">
          {yourCells}v{enemyCells}
        </span>
      </div>
    </div>
  );
}
