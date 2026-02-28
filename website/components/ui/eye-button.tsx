"use client";

import { useEffect, useRef } from "react";
import styled, { keyframes } from "styled-components";

const agitate = keyframes`
  0%   { transform: scale(1.2) translate(0%, -10%); }
  25%  { transform: scale(1.2) translate(-10%, 10%); }
  50%  { transform: scale(1.2) translate(10%, -5%); }
  75%  { transform: scale(1.2) translate(-10%, -5%); }
  100% { transform: scale(1.2) translate(10%, 10%); }
`;

const squint = keyframes`
  0%   { background: var(--back-color); }
  25%  { background: linear-gradient(0deg, #000 0% 9%,  var(--back-color) 10% 90%, #000 91% 100%); }
  50%  { background: linear-gradient(0deg, #000 0% 18%, var(--back-color) 19% 81%, #000 82% 100%); }
  75%  { background: linear-gradient(0deg, #000 0% 27%, var(--back-color) 28% 72%, #000 73% 100%); }
  100% { background: linear-gradient(0deg, #000 0% 35%, var(--back-color) 36% 64%, #000 65% 100%); }
`;

const StyledWrapper = styled.div`
  .btn-container {
    display: flex;
    flex-direction: row;
    gap: 0.6rem;
    align-items: center;
  }

  .btn-button {
    --back-color: #fff;
    background: rgba(255, 255, 255, 0.08);
    border: 1.5px solid rgba(255, 255, 255, 0.25);
    border-radius: 10rem;
    cursor: pointer;
    padding: 0.6rem;
    position: relative;
    backdrop-filter: blur(8px);
    transition: border-color 0.2s ease, background 0.2s ease;
  }

  .btn-button:hover,
  .btn-button:hover .btn-lid {
    animation: ${squint} 100ms forwards;
  }

  .btn-button:hover {
    border-color: rgba(150, 204, 0, 0.6);
    background: rgba(150, 204, 0, 0.08);
  }

  .btn-button:active .btn-pupil {
    animation: ${agitate} 100ms infinite 500ms;
    border-width: 0.4rem;
    padding: 0.6rem;
  }

  .btn-lid {
    --back-color: transparent;
    border-radius: 10rem;
    height: 100%;
    left: 0;
    position: absolute;
    top: 0;
    width: 100%;
    pointer-events: none;
  }

  .btn-pupil {
    background: #96cc00;
    border: 0.5rem solid rgba(150, 204, 0, 0.3);
    border-radius: 10rem;
    padding: 0.4rem;
    transition: transform 200ms ease-out;
    pointer-events: none;
  }
`;

function Eye({ containerRef }: { containerRef: React.RefObject<HTMLDivElement | null> }) {
  const pupilRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const move = (e: MouseEvent) => {
      const pupil = pupilRef.current;
      const container = containerRef.current;
      if (!pupil || !container) return;

      const rect = container.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;

      const dx = (e.clientX - cx) / (window.innerWidth / 2);
      const dy = (e.clientY - cy) / (window.innerHeight / 2);

      const MAX = 5;
      const x = Math.max(-1, Math.min(1, dx)) * MAX;
      const y = Math.max(-1, Math.min(1, dy)) * MAX;

      pupil.style.transform = `translate(${x}px, ${y}px)`;
    };

    window.addEventListener("mousemove", move, { passive: true });
    return () => window.removeEventListener("mousemove", move);
  }, [containerRef]);

  return (
    <button className="btn-button" aria-label="Eye">
      <div className="btn-lid" />
      <div className="btn-pupil" ref={pupilRef} />
    </button>
  );
}

export function EyeButton() {
  const containerRef = useRef<HTMLDivElement>(null);

  return (
    <StyledWrapper>
      <div className="btn-container" ref={containerRef}>
        <Eye containerRef={containerRef} />
        <Eye containerRef={containerRef} />
      </div>
    </StyledWrapper>
  );
}
