import Link from "next/link";
import { Download, ArrowUpRight, Smartphone, Play } from "lucide-react";

const footerLinks = {
  Features: [
    { label: "Territory System", href: "#territory" },
    { label: "Kingdom Defense", href: "#defense" },
    { label: "Calorie Tracker", href: "#calories" },
    { label: "Hydration Alerts", href: "#hydration" },
    { label: "Protein Log", href: "#protein" },
    { label: "Daily Quests", href: "#quests" },
  ],
  Company: [
    { label: "About Us", href: "#about" },
    { label: "Blog", href: "#blog" },
    { label: "Careers", href: "#careers" },
    { label: "Press Kit", href: "#press" },
  ],
  Support: [
    { label: "Help Center", href: "#help" },
    { label: "Community", href: "#community" },
    { label: "Privacy Policy", href: "#privacy" },
    { label: "Terms of Service", href: "#terms" },
  ],
};

function SocialIcon({ href, label, children }: { href: string; label: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      aria-label={label}
      className="w-9 h-9 rounded-full border border-[#e0e7ff] bg-white flex items-center justify-center text-[#4338ca]/60 hover:text-[#4338ca] hover:border-[#4338ca]/40 hover:bg-[#f5f3ff] transition-all duration-200"
    >
      {children}
    </Link>
  );
}

export function Footer() {
  return (
    <footer className="bg-white border-t border-[#e0e7ff]">

      {/* ── CTA Banner ─────────────────────────────────────── */}
      <div className="bg-[#0c1f00] px-6 py-16">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-8">
          <div className="text-center md:text-left">
            <h2 className="font-serif text-[clamp(2rem,4vw,3rem)] font-bold text-white leading-tight mb-3">
              Ready to claim your first<br className="hidden md:block" />
              <span className="italic text-[#96cc00]"> territory?</span>
            </h2>
            <p className="font-roboto text-white/50 max-w-sm">
              Lace up. Step outside. Your kingdom starts the moment you take your first step.
            </p>
          </div>
          <div className="flex flex-col sm:flex-row gap-3">
            <Link
              href="#download"
              className="font-roboto inline-flex items-center gap-2.5 bg-[#96cc00] text-[#0c1f00] font-bold px-7 py-3.5 rounded-full text-sm hover:bg-[#a8e000] transition-colors duration-200 whitespace-nowrap"
            >
              <Download size={15} strokeWidth={2.5} /> Download Free
            </Link>
            <Link
              href="#how-it-works"
              className="font-roboto inline-flex items-center gap-2 border border-white/20 text-white/80 hover:text-white hover:border-white/50 font-medium px-7 py-3.5 rounded-full text-sm transition-all duration-200 whitespace-nowrap"
            >
              See how it works <ArrowUpRight size={14} />
            </Link>
          </div>
        </div>
      </div>

      {/* ── Main footer body ───────────────────────────────── */}
      <div className="max-w-7xl mx-auto px-6 py-14">
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-12">

          {/* Brand column */}
          <div className="col-span-2 sm:col-span-3 lg:col-span-2 flex flex-col gap-5">
            {/* Logo */}
            <div className="flex items-center gap-2.5">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" className="text-[#1e4002]">
                <path
                  d="M3 18h18M5 18V9l4 4 3-7 3 7 4-4v9"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              <span className="font-serif text-[1.1rem] font-bold text-[#1e4002] tracking-tight">
                Waddle
              </span>
            </div>
            <p className="font-roboto text-[#1e4002]/50 text-sm leading-relaxed max-w-[220px]">
              The only fitness app where your steps build an empire. Walk more. Own more. Defend everything.
            </p>
            {/* App badges */}
            <div className="flex gap-3">
              <Link
                href="#"
                className="font-roboto flex items-center gap-2 bg-[#f4ffe0] border border-[#c8e87a]/50 rounded-xl px-3.5 py-2.5 text-[11px] font-semibold text-[#1e4002] hover:bg-[#96cc00]/15 transition-colors duration-200"
              >
                <Smartphone size={13} strokeWidth={2} className="text-[#78a300]" />
                App Store
              </Link>
              <Link
                href="#"
                className="font-roboto flex items-center gap-2 bg-[#f4ffe0] border border-[#c8e87a]/50 rounded-xl px-3.5 py-2.5 text-[11px] font-semibold text-[#1e4002] hover:bg-[#96cc00]/15 transition-colors duration-200"
              >
                <Play size={11} strokeWidth={2} className="text-[#78a300] fill-[#78a300]" />
                Google Play
              </Link>
            </div>
            {/* Socials */}
            <div className="flex items-center gap-2">
              <SocialIcon href="#" label="Twitter / X">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.746l7.73-8.835L1.254 2.25h6.333l4.36 5.765 5.297-5.765Zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                </svg>
              </SocialIcon>
              <SocialIcon href="#" label="Instagram">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="2" y="2" width="20" height="20" rx="5" />
                  <circle cx="12" cy="12" r="5" />
                  <circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none" />
                </svg>
              </SocialIcon>
              <SocialIcon href="#" label="TikTok">
                <svg width="12" height="13" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1V9.01a6.34 6.34 0 00-.79-.05 6.34 6.34 0 00-6.34 6.34 6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.33-6.34V8.71a8.18 8.18 0 004.78 1.52V6.74a4.85 4.85 0 01-1.01-.05z" />
                </svg>
              </SocialIcon>
            </div>
          </div>

          {/* Link columns — rendered from config */}
          {Object.entries(footerLinks).map(([title, links]) => (
            <div key={title} className="flex flex-col gap-4">
              <h4 className="font-roboto text-[0.7rem] font-bold text-[#1e4002]/40 tracking-[0.18em] uppercase">
                {title}
              </h4>
              <ul className="flex flex-col gap-2.5">
                {links.map((link) => (
                  <li key={link.label}>
                    <Link
                      href={link.href}
                      className="font-roboto text-sm text-[#1e4002]/70 hover:text-[#1e4002] transition-colors duration-150"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      {/* ── Bottom bar ─────────────────────────────────────── */}
      <div className="border-t border-[#e0e7ff]">
        <div className="max-w-7xl mx-auto px-6 py-5 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p className="font-roboto text-xs text-[#1e4002]/35">
            © {new Date().getFullYear()} Waddle. All rights reserved.
          </p>
          <div className="flex items-center gap-5">
            {["Privacy", "Terms", "Cookies"].map((item) => (
              <Link
                key={item}
                href="#"
                className="font-roboto text-xs text-[#1e4002]/35 hover:text-[#1e4002]/70 transition-colors"
              >
                {item}
              </Link>
            ))}
          </div>
          <p className="font-roboto text-xs text-[#1e4002]/25 font-medium">
            Made for walkers, by walkers
          </p>
        </div>
      </div>

    </footer>
  );
}
