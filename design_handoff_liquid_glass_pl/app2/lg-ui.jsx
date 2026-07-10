// PrensaIA v2 — Liquid Glass (iOS 26) primitives with PL identity.

const LG_THEMES = {
  light: {
    base: "#F2EBE4",
    baseRGBA: a => `rgba(242,235,228,${a})`,
    ambient: [
      "radial-gradient(42% 30% at 12% 4%, rgba(203,160,74,0.34), transparent 70%)",
      "radial-gradient(50% 34% at 98% 18%, rgba(176,42,91,0.20), transparent 70%)",
      "radial-gradient(72% 46% at 50% 110%, rgba(97,16,41,0.28), transparent 74%)",
    ].join(", "),
    text1: "#20090F", text2: "#4A3038", text3: "#84666E",
    accent: "#611029", accentText: "#611029",
    accentSoft: "rgba(97,16,41,0.09)", onAccent: "#FFFFFF",
    gold: "#8E6D25", goldFill: "#CBA04A", onGold: "#4F0A21",
    divider: "rgba(32,9,15,0.08)",
    field: "rgba(255,255,255,0.55)",
    glassBg: "linear-gradient(150deg, rgba(255,255,255,0.94), rgba(255,251,247,0.80))",
    glassClear: "linear-gradient(150deg, rgba(255,255,255,0.62), rgba(255,255,255,0.40))",
    glassWine: "linear-gradient(150deg, rgba(105,20,46,0.97), rgba(79,10,33,0.93))",
    glassRed: "linear-gradient(150deg, rgba(196,55,110,0.96), rgba(150,25,72,0.92))",
    glassEdge: "linear-gradient(155deg, rgba(255,255,255,0.95), rgba(255,255,255,0.30) 26%, rgba(255,255,255,0.08) 55%, rgba(255,255,255,0.60))",
    glassEdgeTint: "linear-gradient(155deg, rgba(255,255,255,0.75), rgba(255,255,255,0.18) 30%, rgba(255,255,255,0.06) 60%, rgba(255,255,255,0.45))",
    glassShadow: "0 12px 32px rgba(79,10,33,0.14), 0 2px 8px rgba(79,10,33,0.07)",
    blur: 22, statusDark: false, logo: "logo-pl", redLive: "#C4376E",
  },
  dark: {
    base: "#150409",
    baseRGBA: a => `rgba(21,4,9,${a})`,
    ambient: [
      "radial-gradient(46% 32% at 14% 2%, rgba(176,42,91,0.42), transparent 70%)",
      "radial-gradient(40% 28% at 94% 12%, rgba(203,160,74,0.15), transparent 70%)",
      "radial-gradient(84% 52% at 50% 114%, rgba(120,22,52,0.58), transparent 76%)",
    ].join(", "),
    text1: "#F8F4F1", text2: "rgba(248,244,241,0.78)", text3: "rgba(248,244,241,0.52)",
    accent: "#B02A5B", accentText: "#E79BB7",
    accentSoft: "rgba(226,123,161,0.14)", onAccent: "#FFFFFF",
    gold: "#D9B565", goldFill: "#CBA04A", onGold: "#2A0610",
    divider: "rgba(255,255,255,0.10)",
    field: "rgba(20,4,10,0.40)",
    glassBg: "linear-gradient(150deg, rgba(84,25,46,0.93), rgba(31,7,17,0.91))",
    glassClear: "linear-gradient(150deg, rgba(74,21,41,0.66), rgba(25,5,13,0.55))",
    glassWine: "linear-gradient(150deg, rgba(176,42,91,0.96), rgba(97,16,41,0.94))",
    glassRed: "linear-gradient(150deg, rgba(226,99,143,0.95), rgba(160,30,80,0.92))",
    glassEdge: "linear-gradient(155deg, rgba(255,255,255,0.42), rgba(255,255,255,0.10) 28%, rgba(255,255,255,0.03) 58%, rgba(255,255,255,0.22))",
    glassEdgeTint: "linear-gradient(155deg, rgba(255,255,255,0.55), rgba(255,255,255,0.14) 30%, rgba(255,255,255,0.04) 60%, rgba(255,255,255,0.30))",
    glassShadow: "0 16px 44px rgba(0,0,0,0.55)",
    blur: 24, statusDark: true, logo: "logo-pl-gold", redLive: "#E2638F",
  },
};

const LG_SPEAKER_COLORS = ["#611029", "#8E6D25", "#B02A5B", "#3A6B5A", "#3D5A80", "#8A5A2B", "#6B4B7A"];
const LG_SPEAKER_DARK = ["#E79BB7", "#D9B565", "#E2638F", "#7FBFA5", "#8FB4DC", "#D2A06B", "#B99BC8"];
function lgSpeaker(th, id) {
  const arr = th.statusDark ? LG_SPEAKER_DARK : LG_SPEAKER_COLORS;
  return arr[((id % 7) + 7) % 7];
}

// ── The Liquid Glass surface ────────────────────────────────────────────
// Renders div/button with .glass class; material driven by CSS vars.
function Glass({ th, as = "div", radius = 24, tint, clear, blur, press, className = "", style, children, onClick, refEl }) {
  const bg = tint === "wine" ? th.glassWine : tint === "red" ? th.glassRed : clear ? th.glassClear : th.glassBg;
  const edge = tint ? th.glassEdgeTint : th.glassEdge;
  const Comp = as;
  return (
    <Comp ref={refEl} onClick={onClick}
      className={`glass ${press ? "press" : ""} ${className}`}
      style={{ borderRadius: radius, "--gbg": bg, "--gedge": edge,
        "--gshadow": th.glassShadow, "--gblur": (blur || th.blur) + "px", ...style }}>
      {children}
    </Comp>
  );
}

// ── Icons (Lucide-style strokes) ────────────────────────────────────────
function Icon({ name, size = 22, color = "currentColor", strokeWidth = 1.9, fill = "none", style }) {
  const P = {
    house: <><path d="M4 11.2L12 4.2l8 7"/><path d="M6.5 9.6V19a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V9.6"/></>,
    upload: <><path d="M12 16V4"/><path d="M7 9l5-5 5 5"/><path d="M5 16v3a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-3"/></>,
    mic: <><rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0"/><path d="M12 17.5V21"/><path d="M8.5 21h7"/></>,
    livemic: <><rect x="9.5" y="3" width="5" height="9.5" rx="2.5"/><path d="M6.5 11a5.5 5.5 0 0 0 11 0"/><path d="M12 16.5V20"/><path d="M3 7v3M3.2 6.2v4.6M21 7v3M20.8 6.2v4.6"/></>,
    photo: <><rect x="3" y="4.5" width="18" height="15" rx="2.5"/><circle cx="8.5" cy="9.5" r="1.6"/><path d="M21 16l-5-4.5L7 19"/></>,
    book: <><path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15.5H6.5A1.5 1.5 0 0 0 5 20z"/><path d="M5 18.5A1.5 1.5 0 0 1 6.5 17H19"/></>,
    history: <><path d="M3 4v5h5"/><path d="M3.5 9a9 9 0 1 1-1.2 4.5"/><path d="M12 8v4l3 2"/></>,
    play: <path d="M8 5.5v13l11-6.5z" fill={color} stroke="none"/>,
    pause: <><rect x="7" y="5" width="3.5" height="14" rx="1" fill={color} stroke="none"/><rect x="13.5" y="5" width="3.5" height="14" rx="1" fill={color} stroke="none"/></>,
    stop: <rect x="6" y="6" width="12" height="12" rx="2.5" fill={color} stroke="none"/>,
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
    chevronLeft: <path d="M15 5l-7 7 7 7"/>,
    chevUpDown: <><path d="M8 9l4-4 4 4"/><path d="M16 15l-4 4-4-4"/></>,
    plus: <><path d="M12 5v14M5 12h14"/></>,
    arrowRight: <><path d="M4 12h16"/><path d="M14 6l6 6-6 6"/></>,
    sendUp: <><circle cx="12" cy="12" r="9"/><path d="M12 16.5v-9M8.5 11L12 7.5 15.5 11"/></>,
    question: <><path d="M5 19l-2 2V6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2z"/><path d="M9.2 9.2a2.8 2.8 0 0 1 5.3 1c0 1.9-2.7 2.3-2.7 2.3"/><circle cx="11.9" cy="15.4" r="0.4" fill={color} stroke={color}/></>,
    check: <><circle cx="12" cy="12" r="9"/><path d="M8 12.2l2.6 2.6L16 9.5"/></>,
    checkSmall: <path d="M5 12.5l4.2 4.2L19 7"/>,
    trash: <><path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
    close: <><path d="M6 6l12 12M18 6L6 18"/></>,
    waveform: <><path d="M3 12h2M7 7v10M11 4v16M15 8v8M19 11v2M21 12h0"/></>,
    warn: <><path d="M12 3l9 16H3z"/><path d="M12 9v5"/><circle cx="12" cy="16.5" r="0.4" fill={color} stroke={color}/></>,
    clock: <><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></>,
    download: <><path d="M12 4v10M8 10l4 4 4-4"/><path d="M5 19h14"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color}
      strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {P[name]}
    </svg>
  );
}

function PLLogo({ th, size = 56 }) {
  return <img src={`assets/${th.logo}.png`} alt="PL" style={{ width: size, height: size * (273/300), objectFit: "contain", display: "block" }} />;
}

// ── Buttons ─────────────────────────────────────────────────────────────
function GlassButton({ th, icon, children, tint, onClick, style, height = 54 }) {
  const c = tint ? th.onAccent : th.accentText;
  return (
    <Glass th={th} as="button" tint={tint} press radius={height / 2 > 18 ? 18 : height / 2}
      style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 9,
        height, padding: "0 20px", width: "100%", ...style }} onClick={onClick}>
      {icon && <Icon name={icon} size={19} color={c} strokeWidth={2.1} />}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15.5,
        letterSpacing: "0.005em", color: c, whiteSpace: "nowrap", position: "relative" }}>{children}</span>
    </Glass>
  );
}

function CircleButton({ th, icon, onClick, size = 44, tint, iconSize }) {
  const c = tint ? th.onAccent : th.accentText;
  return (
    <Glass th={th} as="button" tint={tint} press radius={999}
      style={{ width: size, height: size, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}
      onClick={onClick}>
      <Icon name={icon} size={iconSize || size * 0.46} color={c} strokeWidth={2.1} style={{ position: "relative" }} />
    </Glass>
  );
}

// ── Solid gold capsule — the PL signature (never glass) ─────────────────
function Capsule({ th, children, variant = "gold", style }) {
  const wine = variant === "wine";
  return (
    <span style={{ display: "inline-block", background: wine ? th.accent : th.goldFill,
      color: wine ? th.onAccent : th.onGold, fontWeight: 800, whiteSpace: "nowrap",
      padding: "2.5px 12px", borderRadius: 999, lineHeight: 1.32,
      fontFamily: "var(--font-display)", boxShadow: "0 2px 8px rgba(79,10,33,0.18)", ...style }}>{children}</span>
  );
}

function Eyebrow({ th, icon, children, color }) {
  const c = color || th.gold;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
      {icon && <Icon name={icon} size={14} color={c} strokeWidth={2.2} />}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 11,
        letterSpacing: "0.13em", textTransform: "uppercase", color: c }}>{children}</span>
    </div>
  );
}

function SectionLabel({ th, children, style }) {
  return (
    <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 11.5, letterSpacing: "0.09em",
      textTransform: "uppercase", color: th.text3, padding: "0 10px 9px", ...style }}>{children}</div>
  );
}

// ── Segmented control (glass track + sliding wine-glass thumb) ──────────
function Segmented({ th, value, options, onChange, small, style }) {
  const i = Math.max(0, options.findIndex(o => o.value === value));
  const n = options.length;
  return (
    <Glass th={th} clear radius={999} style={{ padding: 4, ...style }}>
      <div style={{ position: "relative", display: "flex" }}>
        <Glass th={th} tint="wine" radius={999} blur={8} style={{
          position: "absolute", top: 0, bottom: 0, left: 0, width: `${100 / n}%`,
          transform: `translateX(${i * 100}%)`,
          transition: "transform 0.32s cubic-bezier(0.32,0.72,0,1)" }} />
        {options.map(o => (
          <button key={o.value} onClick={() => onChange(o.value)} style={{
            flex: 1, position: "relative", padding: small ? "6px 12px" : "9px 6px", borderRadius: 999,
            fontFamily: "var(--font-display)", fontWeight: 700, fontSize: small ? 12.5 : 12.5,
            letterSpacing: "-0.01em", whiteSpace: "nowrap",
            color: o.value === value ? th.onAccent : th.text3,
            transition: "color 0.25s" }}>{o.label}</button>
        ))}
      </div>
    </Glass>
  );
}

// ── Toggle & stepper ────────────────────────────────────────────────────
function Toggle({ th, on, onClick }) {
  return (
    <Glass th={th} as="button" tint={on ? "wine" : undefined} clear={!on} radius={999} press
      onClick={onClick} style={{ width: 52, height: 32, padding: 2.5, display: "flex",
        justifyContent: on ? "flex-end" : "flex-start", transition: "all 0.2s" }}>
      <div style={{ width: 27, height: 27, borderRadius: 999, background: "#fff",
        boxShadow: "0 1.5px 4px rgba(0,0,0,0.3)", position: "relative" }} />
    </Glass>
  );
}

function StepperChip({ th, children, onClick }) {
  return (
    <Glass th={th} as="button" clear press radius={999} onClick={onClick}
      style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 14px" }}>
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14, color: th.accentText, position: "relative" }}>{children}</span>
      <Icon name="chevUpDown" size={13} color={th.accentText} strokeWidth={2.2} style={{ position: "relative" }} />
    </Glass>
  );
}

// ── Floating tab bar (shrinks on scroll) ────────────────────────────────
const LG_TABS = [
  { id: "inicio", icon: "house", label: "Inicio" },
  { id: "historial", icon: "history", label: "Historial" },
  { id: "diccionario", icon: "book", label: "Diccionario" },
];

function TabBar({ th, tab, onTab, compact }) {
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 16, display: "flex",
      justifyContent: "center", zIndex: 70, pointerEvents: "none" }}>
      <Glass th={th} radius={999} style={{ display: "flex", gap: 3, padding: 5, pointerEvents: "auto",
        transition: "all 0.35s cubic-bezier(0.32,0.72,0,1)" }}>
        {LG_TABS.map(item => {
          const active = tab === item.id;
          return (
            <button key={item.id} onClick={() => onTab(item.id)} style={{
              position: "relative", display: "flex", flexDirection: "column", alignItems: "center",
              justifyContent: "center", gap: 2, borderRadius: 999,
              padding: compact ? "9px 15px" : "8px 19px",
              minWidth: compact ? 48 : 66,
              transition: "all 0.35s cubic-bezier(0.32,0.72,0,1)" }}>
              {active && <Glass th={th} tint="wine" radius={999} blur={8}
                style={{ position: "absolute", inset: 0 }} />}
              <Icon name={item.icon} size={21} color={active ? th.onAccent : th.text3}
                strokeWidth={2} style={{ position: "relative" }} />
              <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 700,
                fontSize: 10, letterSpacing: "0.01em",
                color: active ? th.onAccent : th.text3,
                maxHeight: compact ? 0 : 14, opacity: compact ? 0 : 1, overflow: "hidden",
                transition: "all 0.3s cubic-bezier(0.32,0.72,0,1)" }}>{item.label}</span>
            </button>
          );
        })}
      </Glass>
    </div>
  );
}

// ── Ambient PL backdrop ─────────────────────────────────────────────────
function Ambient({ th }) {
  return (
    <div aria-hidden="true" style={{ position: "absolute", inset: 0, background: `${th.ambient}, ${th.base}`,
      transition: "background 0.4s" }} />
  );
}

function Spinner({ th, size = 18, color }) {
  return (
    <div className="pl-spin" style={{ width: size, height: size, borderRadius: 999, flexShrink: 0,
      border: `2.5px solid ${th.accentSoft}`, borderTopColor: color || th.accentText }} />
  );
}

Object.assign(window, {
  LG_THEMES, lgSpeaker, Glass, Icon, PLLogo, GlassButton, CircleButton,
  Capsule, Eyebrow, SectionLabel, Segmented, Toggle, StepperChip,
  TabBar, LG_TABS, Ambient, Spinner,
});
