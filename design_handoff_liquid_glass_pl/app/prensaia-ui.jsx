// PL theme tokens + shared UI primitives for the PrensaIA re-skin.

const PL_THEMES = {
  light: {
    page: "#F1ECE8",
    card: "#FFFFFF",
    cardSunk: "#F4EFEC",
    text1: "#1A1A1A",
    text2: "#3A3A3A",
    text3: "#6B6B6B",
    accent: "#611029",       // wine-800 — primary interactive
    accentText: "#611029",
    accentSoft: "rgba(97,16,41,0.10)",
    accentSoftStrong: "rgba(97,16,41,0.16)",
    onAccent: "#FFFFFF",
    gold: "#B89239",
    goldFill: "#CBA04A",
    onGold: "#4F0A21",
    divider: "rgba(10,10,10,0.08)",
    field: "#F0EAE6",
    chrome: "rgba(255,255,255,0.72)",
    logo: "logo-pl",
    statusDark: false,
    shadow: "0 10px 30px rgba(79,10,33,0.10), 0 2px 8px rgba(10,10,10,0.05)",
    redLive: "#C4376E",
  },
  dark: {
    page: "#160509",
    card: "#270B16",
    cardSunk: "#1E0710",
    text1: "#F6F4F1",
    text2: "rgba(246,244,241,0.74)",
    text3: "rgba(246,244,241,0.50)",
    accent: "#D77FA1",       // bright wine for legibility on dark
    accentText: "#E79BB7",
    accentSoft: "rgba(196,55,110,0.20)",
    accentSoftStrong: "rgba(196,55,110,0.30)",
    onAccent: "#FFFFFF",
    accentFill: "#B02A5B",   // magenta-600 button fill
    gold: "#D9B565",
    goldFill: "#CBA04A",
    onGold: "#2A0610",
    divider: "rgba(255,255,255,0.10)",
    field: "#33101F",
    chrome: "rgba(30,7,16,0.80)",
    logo: "logo-pl-gold",
    statusDark: true,
    shadow: "0 14px 36px rgba(0,0,0,0.45)",
    redLive: "#E2638F",
  },
};

// Speaker palette — restrained, brand-harmonious (wine, gold, magenta, ink, slate)
const SPEAKER_COLORS = ["#611029", "#B89239", "#B02A5B", "#3A6B5A", "#3D5A80", "#8A5A2B", "#6B4B7A"];
function speakerColor(id) { return SPEAKER_COLORS[((id % 7) + 7) % 7]; }

// Primary fill respects dark mode (magenta) vs light (wine)
function primaryFill(th) { return th.accentFill || th.accent; }

// ── Icon set (Lucide-style stroke, 24×24) ───────────────────────────────
function Icon({ name, size = 22, color = "currentColor", strokeWidth = 1.9, fill = "none", style }) {
  const P = {
    upload: <><path d="M12 16V4"/><path d="M7 9l5-5 5 5"/><path d="M5 16v3a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-3"/></>,
    mic: <><rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0"/><path d="M12 17.5V21"/><path d="M8.5 21h7"/></>,
    livemic: <><rect x="9.5" y="3" width="5" height="9.5" rx="2.5"/><path d="M6.5 11a5.5 5.5 0 0 0 11 0"/><path d="M12 16.5V20"/><path d="M3 7v3M3.2 6.2v4.6M21 7v3M20.8 6.2v4.6"/></>,
    photo: <><rect x="3" y="4.5" width="18" height="15" rx="2.5"/><circle cx="8.5" cy="9.5" r="1.6"/><path d="M21 16l-5-4.5L7 19"/></>,
    book: <><path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15.5H6.5A1.5 1.5 0 0 0 5 20z"/><path d="M5 18.5A1.5 1.5 0 0 1 6.5 17H19"/></>,
    history: <><path d="M3 4v5h5"/><path d="M3.5 9a9 9 0 1 1-1.2 4.5"/><path d="M12 8v4l3 2"/></>,
    play: <path d="M8 5.5v13l11-6.5z" fill={color} stroke="none"/>,
    pause: <><rect x="7" y="5" width="3.5" height="14" rx="1" fill={color} stroke="none"/><rect x="13.5" y="5" width="3.5" height="14" rx="1" fill={color} stroke="none"/></>,
    stop: <rect x="6" y="6" width="12" height="12" rx="2" fill={color} stroke="none"/>,
    copy: <><rect x="9" y="9" width="11" height="11" rx="2.5"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></>,
    share: <><path d="M4 12v7a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-7"/><path d="M12 15V3"/><path d="M8 7l4-4 4 4"/></>,
    ellipsis: <><circle cx="5" cy="12" r="1.6" fill={color} stroke="none"/><circle cx="12" cy="12" r="1.6" fill={color} stroke="none"/><circle cx="19" cy="12" r="1.6" fill={color} stroke="none"/></>,
    pencil: <><path d="M4 16.5V20h3.5L18 9.5 14.5 6z"/><path d="M13 7.5L16.5 11"/></>,
    sparkles: <><path d="M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6z"/><path d="M18 14l.8 2.2L21 17l-2.2.8L18 20l-.8-2.2L15 17l2.2-.8z"/></>,
    scissors: <><circle cx="6" cy="6" r="2.6"/><circle cx="6" cy="18" r="2.6"/><path d="M8.3 7.7L20 18M8.3 16.3L20 6"/></>,
    tag: <><path d="M3 12.5V4.5A1.5 1.5 0 0 1 4.5 3h8l8.5 8.5a1.5 1.5 0 0 1 0 2.1l-6.4 6.4a1.5 1.5 0 0 1-2.1 0z"/><circle cx="7.5" cy="7.5" r="1.3" fill={color} stroke="none"/></>,
    quote: <><path d="M9 7H5.5A1.5 1.5 0 0 0 4 8.5V12a1.5 1.5 0 0 0 1.5 1.5H8V16a2 2 0 0 1-2 2"/><path d="M19 7h-3.5A1.5 1.5 0 0 0 14 8.5V12a1.5 1.5 0 0 0 1.5 1.5H18V16a2 2 0 0 1-2 2"/></>,
    news: <><path d="M3 5.5A1.5 1.5 0 0 1 4.5 4H17a1 1 0 0 1 1 1v13a1.5 1.5 0 0 0 1.5 1.5H6a3 3 0 0 1-3-3z"/><path d="M18 8h1.5A1.5 1.5 0 0 1 21 9.5V18a1.5 1.5 0 0 1-1.5 1.5"/><path d="M6.5 8.5h7M6.5 12h7M6.5 15h4"/></>,
    align: <><path d="M4 6h16M4 10h11M4 14h16M4 18h9"/></>,
    chevron: <path d="M9 5l7 7-7 7"/>,
    chevUpDown: <><path d="M8 9l4-4 4 4"/><path d="M16 15l-4 4-4-4"/></>,
    plus: <><path d="M12 5v14M5 12h14"/></>,
    arrowRight: <><path d="M4 12h16"/><path d="M14 6l6 6-6 6"/></>,
    sendUp: <><circle cx="12" cy="12" r="9"/><path d="M12 16.5v-9M8.5 11L12 7.5 15.5 11"/></>,
    question: <><path d="M5 19l-2 2V6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2z"/><path d="M9.2 9.2a2.8 2.8 0 0 1 5.3 1c0 1.9-2.7 2.3-2.7 2.3"/><circle cx="11.9" cy="15.4" r="0.4" fill={color} stroke={color}/></>,
    check: <><circle cx="12" cy="12" r="9"/><path d="M8 12.2l2.6 2.6L16 9.5"/></>,
    trash: <><path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
    close: <><path d="M6 6l12 12M18 6L6 18"/></>,
    waveform: <><path d="M3 12h2M7 7v10M11 4v16M15 8v8M19 11v2M21 12h0"/></>,
    speed: <><circle cx="12" cy="13" r="8"/><path d="M12 13l3.5-3.5"/><path d="M12 3.5h0M9 2.5h6"/></>,
    warn: <><path d="M12 3l9 16H3z"/><path d="M12 9v5"/><circle cx="12" cy="16.5" r="0.4" fill={color} stroke={color}/></>,
    users: <><circle cx="9" cy="8" r="3.2"/><path d="M3 19a6 6 0 0 1 12 0"/><path d="M16 5.2A3.2 3.2 0 0 1 16 11.4M21 19a6 6 0 0 0-4-5.6"/></>,
    download: <><path d="M12 4v10M8 10l4 4 4-4"/><path d="M5 19h14"/></>,
    clock: <><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color}
      strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {P[name]}
    </svg>
  );
}

// PL sun-burst logo
function PLLogo({ th, size = 64 }) {
  return <img src={`assets/${th.logo}.png`} alt="PL" style={{ width: size, height: size * (273/300), objectFit: "contain", display: "block" }} />;
}

// Buttons
function PrimaryButton({ th, icon, children, onClick, style }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
      width: "100%", padding: "16px 18px", border: "none", cursor: "pointer",
      background: primaryFill(th), color: th.onAccent, borderRadius: 16,
      fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 16,
      letterSpacing: "0.01em", boxShadow: `0 8px 20px ${th.accentSoftStrong}`, ...style,
    }}>
      {icon && <Icon name={icon} size={20} color={th.onAccent} strokeWidth={2} />}
      <span style={{ whiteSpace: "nowrap" }}>{children}</span>
    </button>
  );
}

function SecondaryButton({ th, icon, children, onClick, style }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
      width: "100%", padding: "16px 18px", border: "none", cursor: "pointer",
      background: th.accentSoft, color: th.accentText, borderRadius: 16,
      fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 16,
      letterSpacing: "0.01em", ...style,
    }}>
      {icon && <Icon name={icon} size={20} color={th.accentText} strokeWidth={2} />}
      <span style={{ whiteSpace: "nowrap" }}>{children}</span>
    </button>
  );
}

// Surface card
function Card({ th, children, style }) {
  return (
    <div style={{
      background: th.card, borderRadius: 24, padding: 20,
      boxShadow: th.shadow, ...style,
    }}>{children}</div>
  );
}

// Gold/wine capsule highlight — the brand signature
function Capsule({ th, children, variant = "gold", style }) {
  const wine = variant === "wine";
  return (
    <span style={{
      display: "inline-block", background: wine ? th.accent : th.goldFill,
      color: wine ? th.onAccent : th.onGold, fontWeight: 800,
      padding: "2px 13px", borderRadius: 999, lineHeight: 1.32, whiteSpace: "nowrap",
      fontFamily: "var(--font-display)", ...style,
    }}>{children}</span>
  );
}

// Section eyebrow (gold, uppercase, tracked)
function Eyebrow({ th, icon, children, color }) {
  const c = color || th.gold;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
      {icon && <Icon name={icon} size={15} color={c} strokeWidth={2} />}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 11.5,
        letterSpacing: "0.12em", textTransform: "uppercase", color: c }}>{children}</span>
    </div>
  );
}

Object.assign(window, {
  PL_THEMES, SPEAKER_COLORS, speakerColor, primaryFill,
  Icon, PLLogo, PrimaryButton, SecondaryButton, Card, Capsule, Eyebrow,
});
