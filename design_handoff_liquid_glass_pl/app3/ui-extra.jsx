// PrensaIA v3 — primitivas extra sobre app2/lg-ui.jsx (que debe cargarse antes).
// Parche de iconos + menús, diálogos, share sheet, onda de audio, badges.

(function extendIcons() {
  const BaseIcon = window.Icon;
  function Icon(props) {
    const P = {
      radio: <><circle cx="12" cy="12" r="1.8" fill={props.color || "currentColor"} stroke="none"/><path d="M8.6 15.4a4.8 4.8 0 0 1 0-6.8M15.4 8.6a4.8 4.8 0 0 1 0 6.8"/><path d="M5.8 18.2a8.8 8.8 0 0 1 0-12.4M18.2 5.8a8.8 8.8 0 0 1 0 12.4"/></>,
      tap: <><path d="M9 11.5V5.8a1.8 1.8 0 0 1 3.6 0v5" /><path d="M12.6 11.3V9.9a1.7 1.7 0 0 1 3.4 0v2.2a1.6 1.6 0 0 1 3.2.4c0 3.4-1 4.6-1.8 5.9-.6 1-1.7 1.6-3.4 1.6h-1.6c-1.3 0-2.4-.5-3.2-1.5l-3.4-4.2a1.5 1.5 0 0 1 2.3-1.9l1.9 2" /></>,
      film: <><rect x="3.5" y="4.5" width="17" height="15" rx="2.5"/><path d="M7.5 4.5v15M16.5 4.5v15M3.5 9h4M3.5 15h4M16.5 9h4M16.5 15h4"/></>,
      seal: <><path d="M12 3l2 1.8 2.7-.4 1 2.5 2.5 1-.4 2.7L21.6 12l-1.8 2 .4 2.7-2.5 1-1 2.5-2.7-.4L12 21.6l-2-1.8-2.7.4-1-2.5-2.5-1 .4-2.7L2.4 12l1.8-2-.4-2.7 2.5-1 1-2.5 2.7.4z"/><path d="M8.5 12.2l2.4 2.4 4.8-4.8"/></>,
      docText: <><path d="M6 3h8l4 4v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/><path d="M14 3v4h4"/><path d="M8.5 12h7M8.5 15.5h7M8.5 8.5H11"/></>,
      sun: <><circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M19.1 4.9l-1.8 1.8M6.7 17.3l-1.8 1.8"/></>,
      moon: <path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z"/>,
      halfCircle: <><circle cx="12" cy="12" r="8.5"/><path d="M12 3.5v17A8.5 8.5 0 0 0 12 3.5z" fill={props.color || "currentColor"} stroke="none"/></>,
      viewfinder: <><path d="M4 8V5.5A1.5 1.5 0 0 1 5.5 4H8M16 4h2.5A1.5 1.5 0 0 1 20 5.5V8M20 16v2.5a1.5 1.5 0 0 1-1.5 1.5H16M8 20H5.5A1.5 1.5 0 0 1 4 18.5V16"/><path d="M8 10.5h8M8 13.5h5"/></>,
      refresh: <><path d="M20 5v5h-5"/><path d="M20 10a8.2 8.2 0 1 0 1 4"/></>,
      circle: <circle cx="12" cy="12" r="9"/>,
      checkFill: <><circle cx="12" cy="12" r="10" fill={props.color || "currentColor"} stroke="none"/><path d="M7.5 12.4l3 3 6-6.3" stroke="#fff" strokeWidth="2.4"/></>,
      minusFill: <><circle cx="12" cy="12" r="10" fill={props.color || "currentColor"} stroke="none"/><path d="M7.5 12h9" stroke="#fff" strokeWidth="2.4"/></>,
      airdrop: <><path d="M12 2.8a7.2 7.2 0 0 1 4.2 13.1M12 2.8a7.2 7.2 0 0 0-4.2 13.1"/><circle cx="12" cy="10" r="3.2"/><path d="M12 13.2L8.6 21h6.8z"/></>,
      msg: <><path d="M12 3.5c-5 0-9 3.2-9 7.2 0 2.3 1.3 4.3 3.4 5.6-.2 1-.8 2.4-1.9 3.2 1.9 0 3.6-.9 4.6-1.7.9.2 1.9.4 2.9.4 5 0 9-3.3 9-7.4s-4-7.3-9-7.3z"/></>,
      mail: <><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3.5 7l8.5 6 8.5-6"/></>,
      folder: <><path d="M3 7.5A1.5 1.5 0 0 1 4.5 6h4l2 2.5h9A1.5 1.5 0 0 1 21 10v8a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18z"/></>,
      gauge: <><path d="M4.5 17.5a8.5 8.5 0 1 1 15 0"/><path d="M12 14l3.8-4.5"/><circle cx="12" cy="14.5" r="1.6" fill={props.color || "currentColor"} stroke="none"/></>,
      expand: <><path d="M9 4H5.5A1.5 1.5 0 0 0 4 5.5V9"/><path d="M15 4h3.5A1.5 1.5 0 0 1 20 5.5V9"/><path d="M20 15v3.5a1.5 1.5 0 0 1-1.5 1.5H15"/><path d="M4 15v3.5A1.5 1.5 0 0 0 5.5 20H9"/></>,
    };
    if (P[props.name]) {
      return (
        <svg width={props.size || 22} height={props.size || 22} viewBox="0 0 24 24" fill="none"
          stroke={props.color || "currentColor"} strokeWidth={props.strokeWidth || 1.9}
          strokeLinecap="round" strokeLinejoin="round" style={props.style}>
          {P[props.name]}
        </svg>
      );
    }
    return <BaseIcon {...props} />;
  }
  window.Icon = Icon;
})();

// ── Badge (MÍO / IA) — cápsulas sólidas de marca ─────────────────────────
function Badge({ th, kind }) {
  const mine = kind === "mine";
  return (
    <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 9.5,
      letterSpacing: "0.08em", padding: "2.5px 8px", borderRadius: 999, flexShrink: 0,
      background: mine ? th.accent : th.goldFill, color: mine ? th.onAccent : th.onGold }}>
      {mine ? "MÍO" : "IA"}
    </span>
  );
}

// ── CTA de vidrio entintado a lo ancho (equivale a .glassProminent inline) ─
function GlassCTA({ th, icon, children, onClick, disabled, height = 48, tint = "wine", style }) {
  return (
    <Glass th={th} as="button" tint={tint} press={!disabled} radius={16}
      onClick={disabled ? undefined : onClick}
      style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
        height, width: "100%", opacity: disabled ? 0.5 : 1, ...style }}>
      {icon && <Icon name={icon} size={17} color={th.onAccent} strokeWidth={2.1} style={{ position: "relative" }} />}
      <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 700,
        fontSize: 14.5, color: th.onAccent, whiteSpace: "nowrap" }}>{children}</span>
    </Glass>
  );
}

// ── Menú contextual (popover de vidrio anclado a la derecha) ─────────────
function MenuPopover({ th, open, onClose, items, top = 96 }) {
  if (!open) return null;
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 120 }} onClick={onClose}>
      <Glass th={th} radius={20} className="lg-pop" style={{ position: "absolute", top, right: 16,
        minWidth: 240, padding: "4px 0", overflow: "hidden" }}>
        {items.map((it, i) => (
          <button key={i} onClick={e => { e.stopPropagation(); onClose(); it.onClick && it.onClick(); }}
            style={{ display: "flex", alignItems: "center", gap: 12, width: "100%", textAlign: "left",
              padding: "12.5px 16px", position: "relative",
              borderTop: i ? `1px solid ${th.divider}` : "none",
              color: it.danger ? th.redLive : th.text1 }}>
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5 }}>{it.label}</span>
            <Icon name={it.icon} size={18} color={it.danger ? th.redLive : th.accentText} strokeWidth={2} />
          </button>
        ))}
      </Glass>
    </div>
  );
}

// ── Diálogo centrado (alerta iOS con campo de texto opcional) ────────────
function Dialog({ th, open, title, message, value, onChange, placeholder, actions }) {
  if (!open) return null;
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 130, display: "flex", alignItems: "center",
      justifyContent: "center", padding: 32, background: "rgba(0,0,0,0.35)" }} className="pl-fade">
      <Glass th={th} radius={24} className="lg-pop" style={{ width: "100%", maxWidth: 300, padding: "20px 0 0", textAlign: "center" }}>
        <div style={{ padding: "0 20px", position: "relative" }}>
          <div style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 16, color: th.text1 }}>{title}</div>
          {message && <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5,
            color: th.text3, marginTop: 6, lineHeight: 1.4 }}>{message}</div>}
          {onChange && (
            <Glass th={th} clear radius={12} style={{ margin: "14px 0 4px", padding: "1px 2px" }}>
              <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
                style={{ width: "100%", border: "none", outline: "none", background: "transparent",
                  padding: "10px 12px", textAlign: "center", fontFamily: "var(--font-display)",
                  fontWeight: 600, fontSize: 15, color: th.text1, position: "relative" }} />
            </Glass>
          )}
        </div>
        <div style={{ display: "flex", marginTop: 16, borderTop: `1px solid ${th.divider}`, position: "relative" }}>
          {actions.map((a, i) => (
            <button key={i} onClick={a.onClick} style={{ flex: 1, padding: "13px 6px",
              borderLeft: i ? `1px solid ${th.divider}` : "none",
              fontFamily: "var(--font-display)", fontWeight: a.bold ? 800 : 600, fontSize: 15,
              color: a.danger ? th.redLive : th.accentText }}>{a.label}</button>
          ))}
        </div>
      </Glass>
    </div>
  );
}

// ── Share sheet simulada (hoja iOS de compartir) ─────────────────────────
function ShareSheet({ th, open, onClose, title, items }) {
  if (!open) return null;
  const rows = [
    { icon: "airdrop", label: "AirDrop" },
    { icon: "msg", label: "Mensajes" },
    { icon: "mail", label: "Correo" },
    { icon: "folder", label: "Guardar en Archivos" },
    { icon: "copy", label: "Copiar" },
  ];
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 125, display: "flex", flexDirection: "column",
      justifyContent: "flex-end" }}>
      <div onClick={onClose} style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.35)" }} className="pl-fade" />
      <Glass th={th} radius={28} className="lg-sheet-up" style={{ position: "relative", margin: 10,
        padding: "10px 18px 22px", maxHeight: "72%", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "center", paddingBottom: 8, position: "relative" }}>
          <div style={{ width: 38, height: 5, borderRadius: 999, background: th.divider }} />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 12, paddingBottom: 14, position: "relative" }}>
          <Glass th={th} tint="wine" radius={12} blur={8} style={{ width: 40, height: 40, display: "flex",
            alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <Icon name="docText" size={20} color={th.onAccent} style={{ position: "relative" }} />
          </Glass>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14, color: th.text1,
              whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{title}</div>
            {items && <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>{items}</div>}
          </div>
          <button onClick={onClose} style={{ padding: 4 }}>
            <Icon name="close" size={18} color={th.text3} strokeWidth={2.2} />
          </button>
        </div>
        <div style={{ position: "relative", borderTop: `1px solid ${th.divider}` }}>
          {rows.map((r, i) => (
            <button key={i} onClick={onClose} style={{ display: "flex", alignItems: "center", gap: 14,
              width: "100%", textAlign: "left", padding: "13px 2px",
              borderTop: i ? `1px solid ${th.divider}` : "none" }}>
              <Icon name={r.icon} size={21} color={th.accentText} strokeWidth={1.8} />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5, color: th.text1 }}>{r.label}</span>
            </button>
          ))}
        </div>
      </Glass>
    </div>
  );
}

// ── Onda de audio con arrastre (equivale a WaveformView) ────────────────
function WaveformSeek({ th, samples, progress, onSeek, height = 40 }) {
  const ref = React.useRef(null);
  const seek = e => {
    const r = ref.current.getBoundingClientRect();
    const x = (e.touches ? e.touches[0].clientX : e.clientX) - r.left;
    onSeek(Math.min(1, Math.max(0, x / r.width)));
  };
  return (
    <div ref={ref} onClick={seek} style={{ display: "flex", alignItems: "center", gap: 1.5,
      height, cursor: "pointer", touchAction: "none" }}>
      {samples.map((s, i) => {
        const played = i / samples.length <= progress;
        return <div key={i} style={{ flex: 1, height: `${Math.max(6, s * 100)}%`, borderRadius: 999,
          background: played ? (th.statusDark ? th.accentText : th.accent) : th.divider,
          minWidth: 1.5 }} />;
      })}
    </div>
  );
}

// ── Filas de estado de IA (descarga única / cargando) ────────────────────
function LoadingRow({ th, children }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <Spinner th={th} size={15} />
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5, color: th.text3 }}>{children}</span>
    </div>
  );
}

function ThinProgress({ th, value }) {
  return (
    <div style={{ height: 5, borderRadius: 999, background: th.divider, overflow: "hidden" }}>
      <div style={{ height: "100%", width: `${Math.round(value * 100)}%`, borderRadius: 999,
        background: th.statusDark ? th.accentText : th.accent, transition: "width 0.3s" }} />
    </div>
  );
}

function AIDownloadRow({ th, progress }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 7 }}>
      <LoadingRow th={th}>Descargando IA (solo la 1ª vez)…</LoadingRow>
      <ThinProgress th={th} value={progress} />
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, color: th.text3, lineHeight: 1.4 }}>
        {Math.round(progress * 100)}% — el modelo es grande, puede tardar unos minutos. Después funciona sin internet.
      </span>
    </div>
  );
}

// ── Reproductor de video (equivale al VideoPlayer nativo de AVKit) ───────
function VideoPlayer3({ th, player, setPlayer, dur = 148 }) {
  const frac = Math.min(1, player.time / dur);
  const barRef = React.useRef(null);
  const toggle = () => setPlayer(p => ({ ...p, playing: !p.playing }));
  const seek = e => {
    e.stopPropagation();
    const r = barRef.current.getBoundingClientRect();
    const f = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
    setPlayer(p => ({ ...p, time: f * dur }));
  };
  return (
    <div onClick={toggle} style={{ position: "relative", borderRadius: 18, overflow: "hidden",
      background: "#000", height: 212, cursor: "pointer", boxShadow: th.glassShadow }}>
      <img src="assets/video-frame.jpg" alt="Video de la entrevista"
        style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover",
          opacity: player.playing ? 1 : 0.8, transition: "opacity 0.25s" }} />

      {/* botón central (se oculta al reproducir, como AVKit) */}
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center",
        opacity: player.playing ? 0 : 1, transition: "opacity 0.25s", pointerEvents: "none" }}>
        <div className="glass" style={{ width: 58, height: 58, borderRadius: 999,
          "--gbg": "linear-gradient(150deg, rgba(30,12,20,0.55), rgba(10,4,8,0.45))",
          "--gedge": "linear-gradient(155deg, rgba(255,255,255,0.55), rgba(255,255,255,0.10) 40%, rgba(255,255,255,0.30))",
          "--gshadow": "0 8px 24px rgba(0,0,0,0.45)",
          display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Icon name="play" size={26} color="#fff" style={{ position: "relative", marginLeft: 3 }} />
        </div>
      </div>

      {/* controles inferiores */}
      {player.playing ? (
        <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 3,
          background: "rgba(255,255,255,0.25)" }}>
          <div style={{ height: "100%", width: `${frac * 100}%`, background: "#fff" }} />
        </div>
      ) : (
        <div onClick={e => e.stopPropagation()} style={{ position: "absolute", left: 0, right: 0, bottom: 0,
          padding: "30px 14px 11px", background: "linear-gradient(transparent, rgba(0,0,0,0.74))",
          display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 11.5, color: "#fff" }}>{fmtTime(player.time)}</span>
          <div ref={barRef} onClick={seek} style={{ flex: 1, height: 18, display: "flex", alignItems: "center", cursor: "pointer" }}>
            <div style={{ flex: 1, height: 4, borderRadius: 999, background: "rgba(255,255,255,0.32)", position: "relative" }}>
              <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${frac * 100}%`,
                background: "#fff", borderRadius: 999 }} />
              <div style={{ position: "absolute", left: `calc(${frac * 100}% - 6px)`, top: "50%",
                transform: "translateY(-50%)", width: 12, height: 12, borderRadius: 999, background: "#fff",
                boxShadow: "0 1px 4px rgba(0,0,0,0.4)" }} />
            </div>
          </div>
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 11.5, color: "rgba(255,255,255,0.75)" }}>{fmtTime(dur)}</span>
          <Icon name="expand" size={17} color="#fff" strokeWidth={2.1} />
        </div>
      )}
    </div>
  );
}

Object.assign(window, {
  Badge, GlassCTA, MenuPopover, Dialog, ShareSheet, WaveformSeek,
  LoadingRow, ThinProgress, AIDownloadRow, VideoPlayer3,
});
