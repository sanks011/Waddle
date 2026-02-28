"use client";

import styled from "styled-components";

const StyledWrapper = styled.div`
  .loading-container {
    width: 120px;
    height: 60px;
    position: relative;
    overflow: hidden;
  }

  .ground {
    position: absolute;
    bottom: 0;
    width: 100%;
    height: 3px;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
    animation: ground-move 2s linear infinite;
  }

  @keyframes ground-move {
    0%   { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }

  .skeleton {
    position: absolute;
    bottom: 6px;
    left: 0;
    width: 40px;
    height: 50px;
    animation: crawl 2s linear infinite;
  }

  @keyframes crawl {
    0%   { transform: translateX(-50px); }
    100% { transform: translateX(130px); }
  }

  .head {
    position: absolute;
    top: 0;
    left: 12px;
    width: 14px;
    height: 14px;
    background-color: #fff;
    border-radius: 50%;
    animation: head-bob 0.5s ease-in-out infinite alternate;
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.2);
  }

  @keyframes head-bob {
    0%   { transform: translateY(0); }
    100% { transform: translateY(-3px); }
  }

  .eye {
    position: absolute;
    width: 2px;
    height: 2px;
    background-color: #222;
    border-radius: 50%;
    top: 5px;
  }
  .eye.left  { left: 4px; }
  .eye.right { left: 8px; }

  .mouth {
    position: absolute;
    width: 6px;
    height: 2px;
    background-color: #222;
    border-radius: 0 0 3px 3px;
    top: 9px;
    left: 4px;
    animation: mouth-talk 0.5s ease-in-out infinite alternate;
  }

  @keyframes mouth-talk {
    0%   { height: 1px; }
    100% { height: 3px; }
  }

  .body {
    position: absolute;
    top: 14px;
    left: 14px;
    width: 10px;
    height: 16px;
    background-color: #fff;
    border-radius: 5px;
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.2);
  }

  .arm {
    position: absolute;
    width: 5px;
    height: 16px;
    background-color: #fff;
    top: 14px;
    border-radius: 25px;
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.2);
  }

  .arm.left  { left: 10px; transform-origin: top center; animation: arm-left 1s ease-in-out infinite; }
  .arm.right { left: 24px; transform-origin: top center; animation: arm-right 1s ease-in-out infinite; }

  @keyframes arm-left {
    0%, 100% { transform: rotate(30deg); }
    50%       { transform: rotate(-20deg); }
  }
  @keyframes arm-right {
    0%, 100% { transform: rotate(-20deg); }
    50%       { transform: rotate(30deg); }
  }

  .leg {
    position: absolute;
    width: 5px;
    height: 18px;
    background-color: #fff;
    top: 28px;
    border-radius: 25px;
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.2);
  }

  .leg.left  { left: 14px; transform-origin: top center; animation: leg-left 1s ease-in-out infinite; }
  .leg.right { left: 20px; transform-origin: top center; animation: leg-right 1s ease-in-out infinite; }

  @keyframes leg-left {
    0%, 100% { transform: rotate(10deg); }
    50%       { transform: rotate(-30deg); }
  }
  @keyframes leg-right {
    0%, 100% { transform: rotate(-30deg); }
    50%       { transform: rotate(10deg); }
  }
`;

export function RunnerLoader() {
  return (
    <StyledWrapper>
      <div className="loading-container">
        <div className="ground" />
        <div className="skeleton">
          <div className="head">
            <div className="eye left" />
            <div className="eye right" />
            <div className="mouth" />
          </div>
          <div className="body" />
          <div className="arm left" />
          <div className="arm right" />
          <div className="leg left" />
          <div className="leg right" />
        </div>
      </div>
    </StyledWrapper>
  );
}
