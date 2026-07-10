// PrensaIA v2 — Resultados: floating glass nav, sticky segmented, mini player.

const LG_RESULT_TABS = [
  { value: "transcript", label: "Por minuto" },
  { value: "esteno", label: "Estenográfica" },
  { value: "analysis", label: "Análisis" },
  { value: "cortes", label: "Cortes" },
];

function ResultsScreen({ th, tab, setTab, player, setPlayer, onBack, headlineFont }) {
  return (
    <div data-screen-label="Resultados" style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column" }}>
      {/* floating nav circles */}
      <div style={{ position: "absolute", top: 54, left: 16, right: 16, zIndex: 60,
        display: "flex", justifyContent: "space-between", pointerEvents: "none" }}>
        <div style={{ pointerEvents: "auto" }}><CircleButton th={th} icon="chevronLeft" onClick={onBack} /></div>
        <div style={{ display: "flex", gap: 10, pointerEvents: "auto" }}>
          <CircleButton th={th} icon="share" />
          <CircleButton th={th} icon="ellipsis" />
        </div>
      </div>

      <div className="lg-scroll" style={{ position: "absolute", inset: 0, overflowY: "auto",
        padding: "108px 18px 180px" }}>
        {/* title block */}
        <div style={{ padding: "0 4px 16px" }}>
          <Eyebrow th={th} icon="news">Cobertura · Hoy, 9:41</Eyebrow>
          <h2 style={{ margin: "8px 0 0", fontFamily: headlineFont, fontStyle: headlineFont.includes("date") ? "italic" : "normal",
            fontWeight: 800, fontSize: 24, lineHeight: 1.22, letterSpacing: "-0.01em", color: th.text1 }}>
            Indira Vizcaíno entrega la rehabilitación del pozo profundo “Cuajiote”
          </h2>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 10 }}>
            <Icon name="clock" size={14} color={th.text3} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12.5, color: th.text3 }}>
              02:28 · 3 oradores · procesado en el iPhone
            </span>
          </div>
        </div>

        {/* sticky segmented */}
        <div style={{ position: "sticky", top: 0, zIndex: 50, padding: "6px 0 14px" }}>
          <Segmented th={th} value={tab} onChange={setTab} options={LG_RESULT_TABS} />
        </div>

        {tab === "transcript" && <LGTranscript th={th} player={player} setPlayer={setPlayer} />}
        {tab === "esteno" && <LGEsteno th={th} />}
        {tab === "analysis" && <LGAnalysis th={th} />}
        {tab === "cortes" && <LGCortes th={th} setPlayer={setPlayer} />}
      </div>

      <MiniPlayer th={th} player={player} setPlayer={setPlayer} />
    </div>
  );
}

// ── Mini player (floating glass pill above the tab bar) ─────────────────
function MiniPlayer({ th, player, setPlayer }) {
  const dur = 148;
  const frac = Math.min(1, player.time / dur);
  const rates = [1, 1.5, 2];
  return (
    <div style={{ position: "absolute", left: 0, right: 0, bottom: 88, display: "flex",
      justifyContent: "center", zIndex: 65, pointerEvents: "none" }}>
      <Glass th={th} radius={999} style={{ display: "flex", alignItems: "center", gap: 12,
        padding: "8px 14px 8px 8px", width: "calc(100% - 48px)", pointerEvents: "auto" }}>
        <Glass th={th} as="button" tint="wine" press radius={999} blur={8}
          onClick={() => setPlayer(p => ({ ...p, playing: !p.playing }))}
          style={{ width: 42, height: 42, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
          <Icon name={player.playing ? "pause" : "play"} size={20} color={th.onAccent} style={{ position: "relative" }} />
        </Glass>
        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 5, position: "relative" }}>
          <div style={{ height: 4, borderRadius: 999, background: th.accentSoft, position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${frac * 100}%`,
              background: th.statusDark ? th.accentText : th.accent, borderRadius: 999 }} />
          </div>
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 11.5, color: th.text3 }}>
            {fmtTime(player.time)} / {fmtTime(dur)}
          </span>
        </div>
        <button onClick={() => setPlayer(p => ({ ...p, rate: rates[(rates.indexOf(p.rate) + 1) % 3] }))}
          style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 12.5, color: th.accentText,
            padding: "6px 8px", position: "relative" }}>{player.rate}x</button>
      </Glass>
    </div>
  );
}

// ── Por minuto ──────────────────────────────────────────────────────────
function LGTranscript({ th, player, setPlayer }) {
  const segs = DEMO_SEGMENTS;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, padding: "0 6px" }}>
        Toca una frase para escucharla desde ese minuto.
      </span>
      <Glass th={th} radius={26} style={{ padding: "8px 12px" }}>
        {segs.map((seg, i) => {
          const newSpeaker = i === 0 || segs[i - 1].speakerId !== seg.speakerId;
          const active = player.time >= seg.start && player.time < seg.end;
          const sc = lgSpeaker(th, seg.speakerId);
          return (
            <React.Fragment key={i}>
              {newSpeaker && (
                <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "14px 8px 4px", position: "relative" }}>
                  <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: sc }}>
                    {SPEAKER_NAMES[seg.speakerId]}
                  </span>
                  <Icon name="pencil" size={12} color={th.text3} strokeWidth={2} />
                </div>
              )}
              <button onClick={() => setPlayer(p => ({ ...p, time: seg.start, playing: true }))} style={{
                display: "flex", alignItems: "flex-start", gap: 11, width: "100%", textAlign: "left",
                background: active ? th.accentSoft : "transparent", borderRadius: 14,
                padding: "8px 8px", position: "relative", transition: "background 0.2s" }}>
                <span style={{ position: "absolute", left: 0, top: 7, bottom: 7, width: 3, borderRadius: 2, background: sc, opacity: 0.9 }} />
                <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 12, width: 40, flexShrink: 0,
                  color: active ? th.accentText : th.text3, paddingTop: 2.5, marginLeft: 7 }}>{fmtTime(seg.start)}</span>
                <span style={{ fontFamily: "var(--font-display)", fontWeight: active ? 650 : 500, fontSize: 14.5,
                  lineHeight: 1.42, color: active ? (th.statusDark ? th.text1 : th.accent) : th.text2 }}>{seg.text}</span>
              </button>
            </React.Fragment>
          );
        })}
      </Glass>
    </div>
  );
}

// ── Estenográfica ───────────────────────────────────────────────────────
function LGEsteno({ th }) {
  const [mode, setMode] = React.useState("limpia");
  const turns = [];
  DEMO_SEGMENTS.forEach(s => {
    const last = turns[turns.length - 1];
    if (last && last.speakerId === s.speakerId) last.text += " " + s.text;
    else turns.push({ speakerId: s.speakerId, text: s.text });
  });
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <Segmented th={th} small value={mode} onChange={setMode} style={{ width: 190 }}
          options={[{ value: "limpia", label: "Limpia" }, { value: "original", label: "Original" }]} />
        <span style={{ flex: 1 }} />
        <CircleButton th={th} icon="copy" size={40} />
      </div>
      <Glass th={th} radius={26} style={{ padding: "20px 20px 22px", display: "flex", flexDirection: "column", gap: 18 }}>
        {turns.map((t, i) => {
          const sc = lgSpeaker(th, t.speakerId);
          return (
            <div key={i} style={{ display: "flex", flexDirection: "column", gap: 7, position: "relative" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 11.5, letterSpacing: "0.06em", color: sc }}>
                  {SPEAKER_NAMES[t.speakerId].toUpperCase()}
                </span>
              </div>
              <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 16.5, lineHeight: 1.56, color: th.text1 }}>
                {mode === "limpia" ? t.text.replace(/\u2026/g, "").replace(/\s+/g, " ") : t.text}
              </p>
            </div>
          );
        })}
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <Icon name="warn" size={13} color={th.text3} strokeWidth={2} />
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>
            Versión limpia generada por IA — revisa antes de publicar.
          </span>
        </div>
      </Glass>
    </div>
  );
}

// ── Análisis ────────────────────────────────────────────────────────────
function LGAnalysis({ th }) {
  const a = DEMO_ANALYSIS;
  const [q, setQ] = React.useState("");
  const Block = ({ icon, title, children }) => (
    <Glass th={th} radius={24} style={{ padding: 18, display: "flex", flexDirection: "column", gap: 11 }}>
      <Eyebrow th={th} icon={icon}>{title}</Eyebrow>
      <div style={{ position: "relative" }}>{children}</div>
    </Glass>
  );
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <Block icon="align" title="Resumen">
        <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, lineHeight: 1.52, color: th.text2 }}>{a.resumen}</p>
      </Block>

      <Block icon="tag" title="Temas principales">
        <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
          {a.temas.map((t, i) => (
            <div key={i} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
              <span style={{ width: 5, height: 5, borderRadius: 999, background: th.goldFill, marginTop: 8, flexShrink: 0 }} />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, lineHeight: 1.4, color: th.text2 }}>{t}</span>
            </div>
          ))}
        </div>
      </Block>

      <Block icon="quote" title="Frases textuales · verificadas">
        <div style={{ display: "flex", flexDirection: "column", gap: 13 }}>
          {a.frasesDestacadas.map((t, i) => (
            <div key={i} style={{ display: "flex", gap: 11 }}>
              <span style={{ width: 3, borderRadius: 2, background: th.goldFill, flexShrink: 0 }} />
              <span style={{ fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 15.5, lineHeight: 1.46, color: th.text1 }}>“{t}”</span>
            </div>
          ))}
        </div>
      </Block>

      <Block icon="news" title="Titulares sugeridos">
        <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
          {a.titulares.map((t, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none" }}>
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, lineHeight: 1.32, color: th.text1 }}>{t}</span>
              <Icon name="copy" size={16} color={th.text3} strokeWidth={2} />
            </div>
          ))}
        </div>
      </Block>

      {/* Pregúntale */}
      <Glass th={th} radius={24} style={{ padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
        <Eyebrow th={th} icon="question">Pregúntale a esta entrevista</Eyebrow>
        <div style={{ display: "flex", alignItems: "center", gap: 9, position: "relative" }}>
          <Glass th={th} clear radius={999} style={{ flex: 1, padding: "1px 2px" }}>
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Ej. ¿Qué dijo sobre 2027?" style={{
              width: "100%", border: "none", outline: "none", background: "transparent", padding: "11px 15px",
              fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14, color: th.text1, position: "relative" }} />
          </Glass>
          <Glass th={th} as="button" tint="wine" press radius={999} blur={8}
            style={{ width: 42, height: 42, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, opacity: q ? 1 : 0.55 }}>
            <Icon name="sendUp" size={21} color={th.onAccent} strokeWidth={1.9} style={{ position: "relative" }} />
          </Glass>
        </div>
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>
          Responde solo con lo que se dijo en el audio.
        </span>
      </Glass>
    </div>
  );
}

// ── Cortes ──────────────────────────────────────────────────────────────
function LGCortes({ th, setPlayer }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      {DEMO_CORTES.map((b, i) => (
        <Glass key={i} th={th} as="button" press radius={24} onClick={() => setPlayer(p => ({ ...p, time: b.inicio, playing: true }))}
          style={{ textAlign: "left", padding: 16, display: "flex", alignItems: "center", gap: 14 }}>
          <Glass th={th} tint="wine" radius={999} blur={8} style={{ width: 44, height: 44, flexShrink: 0,
            display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="play" size={20} color={th.onAccent} style={{ position: "relative" }} />
          </Glass>
          <div style={{ flex: 1, minWidth: 0, position: "relative" }}>
            <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 15, color: th.text1 }}>{b.tema}</span>
            </div>
            <div style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 11.5, color: th.gold, margin: "3px 0 4px" }}>
              {fmtTime(b.inicio)} – {fmtTime(b.fin)}
            </div>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13, lineHeight: 1.38, color: th.text3 }}>{b.resumen}</div>
          </div>
        </Glass>
      ))}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, textAlign: "center", padding: "2px 10px 0" }}>
        Toca un corte para saltar a ese momento del audio.
      </span>
    </div>
  );
}

Object.assign(window, { ResultsScreen, MiniPlayer, LG_RESULT_TABS });
