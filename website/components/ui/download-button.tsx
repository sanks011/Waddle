"use client";

import styled, { keyframes } from "styled-components";

const shimmer = keyframes`
  0%   { transform: translateX(-120%) skewX(-18deg); }
  100% { transform: translateX(320%)  skewX(-18deg); }
`;

const pulse = keyframes`
  0%, 100% { box-shadow: 0 0 0 0 rgba(150,204,0,0.55), 0 8px 32px rgba(150,204,0,0.25); }
  60%       { box-shadow: 0 0 0 14px rgba(150,204,0,0),  0 8px 32px rgba(150,204,0,0.25); }
`;

const nudge = keyframes`
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(3px); }
`;

const StyledWrapper = styled.div`
  .cta-btn {
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 14px;
    padding: 0 24px;
    height: 60px;
    background: #96cc00;
    border: none;
    border-radius: 18px;
    overflow: hidden;
    cursor: pointer !important;
    animation: ${pulse} 2.8s ease-in-out infinite;
    transition: transform 0.22s cubic-bezier(0.34,1.56,0.64,1),
                background 0.2s ease;
    min-width: 200px;
  }

  /* shimmer sweep */
  .cta-btn::before {
    content: "";
    position: absolute;
    inset: 0;
    width: 38%;
    background: linear-gradient(
      90deg,
      transparent,
      rgba(255,255,255,0.52),
      transparent
    );
    transform: translateX(-120%) skewX(-18deg);
    animation: ${shimmer} 3.2s ease-in-out infinite;
    animation-delay: 0.6s;
    pointer-events: none;
  }

  /* top gloss line */
  .cta-btn::after {
    content: "";
    position: absolute;
    top: 0;
    left: 12%;
    right: 12%;
    height: 1px;
    background: rgba(255,255,255,0.55);
    border-radius: 0 0 4px 4px;
    pointer-events: none;
  }

  .cta-text-group {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
    z-index: 1;
  }

  .cta-label {
    font-family: var(--font-cinzel), serif;
    font-style: normal;
    font-weight: 700;
    font-size: 1.05rem;
    color: #1a3800;
    letter-spacing: 0.08em;
    line-height: 1;
    white-space: nowrap;
    text-transform: uppercase;
  }

  .cta-sublabel {
    font-family: var(--font-geist-mono), monospace;
    font-size: 0.58rem;
    font-weight: 500;
    color: #2d5a03;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    white-space: nowrap;
  }

  .cta-icon-wrap {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    background: rgba(30,64,2,0.18);
    border-radius: 12px;
    flex-shrink: 0;
    z-index: 1;
    transition: transform 0.28s cubic-bezier(0.34,1.56,0.64,1);
  }

  .cta-icon-wrap svg {
    width: 17px;
    height: 17px;
    fill: #1a3800;
  }

  .cta-btn:hover {
    transform: translateY(-3px) scale(1.03);
    background: #a6dc00;
  }

  .cta-btn:hover .cta-icon-wrap {
    animation: ${nudge} 0.6s ease-in-out 2;
  }

  .cta-btn:active {
    transform: translateY(0) scale(0.97);
  }
`;

export function DownloadButton() {
  return (
    <StyledWrapper>
      <button className="cta-btn" type="button">
        <span className="cta-text-group">
          <span className="cta-label">Download</span>
        </span>
        <span className="cta-icon-wrap">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 35 35">
            <path d="M17.5,22.131a1.249,1.249,0,0,1-1.25-1.25V2.187a1.25,1.25,0,0,1,2.5,0V20.881A1.25,1.25,0,0,1,17.5,22.131Z" />
            <path d="M17.5,22.693a3.189,3.189,0,0,1-2.262-.936L8.487,15.006a1.249,1.249,0,0,1,1.767-1.767l6.751,6.751a.7.7,0,0,0,.99,0l6.751-6.751a1.25,1.25,0,0,1,1.768,1.767l-6.752,6.751A3.191,3.191,0,0,1,17.5,22.693Z" />
            <path d="M31.436,34.063H3.564A3.318,3.318,0,0,1,.25,30.749V22.011a1.25,1.25,0,0,1,2.5,0v8.738a.815.815,0,0,0,.814.814H31.436a.815.815,0,0,0,.814-.814V22.011a1.25,1.25,0,1,1,2.5,0v8.738A3.318,3.318,0,0,1,31.436,34.063Z" />
          </svg>
        </span>
      </button>
    </StyledWrapper>
  );
}
