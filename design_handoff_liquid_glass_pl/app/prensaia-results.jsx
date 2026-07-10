// PrensaIA — results card: header, tabs, player, and the four tab views.

const RESULT_TABS = [
  { id: "transcript", label: "Por minuto" },
  { id: "esteno", label: "Estenográfica" },
  { id: "analysis", label: "Análisis" },
  { id: "cortes", label: "Cortes" },
];

function ResultsCard({ th, tab, setTab, title, player, setPlayer }) {
  return (
    <Card th={th}>
      <div style={{ display: "flex", alignItems: "flex-start", gap: 12, marginBottom: 16 }}>
        <div style={{ flex: 1 }}>
          <Eyebrow th={th} icon="news">Cobertura</Eyebrow>
          <div style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 19, lineHeight: 1.25,
            color: th.text1, marginTop: 6, letterSpacing: "-0.01em" }}>{title}</div>
        </div>
        <div style={{ display: "flex", gap: 14, paddingTop: 4 }}>
          <Icon name="share" size={21} color={th.accentText} />
          <Icon name="ellipsis" size={21} color={th.accentText} />
        </div>
      </div>

      {/* Segmented control */}
      <div style={{ display: "flex", gap: 4, padding: 4, background: th.cardSunk, borderRadius: 999, marginBottom: 18 }}>
        {RESULT_TABS.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            flex: 1, border: "none", cursor: "pointer", padding: "9px 4px", borderRadius: 999,
            background: tab === t.id ? primaryFill(th) : "transparent",
            color: tab === t.id ? th.onAccent : th.text3,
            fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 12.5, letterSpacing: "-0.01em",
            whiteSpace: "nowrap" }}>{t.label}</button>
        ))}
      </div>

      {tab === "transcript" && <TranscriptView th={th} player={player} setPlayer={setPlayer} />}
      {tab === "esteno" && <EstenoView th={th} />}
      {tab === "analysis" && <AnalysisView th={th} player={player} setPlayer={setPlayer} />}
      {tab === "cortes" && <CortesView th={th} player={player} setPlayer={setPlayer} />}
    </Card>
  );
}

// ── Por minuto ───────────────────────────────────────────────────────────
function TranscriptView({ th, player, setPlayer }) {
  const segs = DEMO_SEGMENTS;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <PlayerBar th={th} player={player} setPlayer={setPlayer} />
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
        Toca una frase para escucharla desde ese minuto
      </span>
      <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {segs.map((seg, i) => {
          const newSpeaker = i === 0 || segs[i - 1].speakerId !== seg.speakerId;
          const active = player.time >= seg.start && player.time < seg.end;
          const sc = speakerColor(seg.speakerId);
          return (
            <React.Fragment key={i}>
              {newSpeaker && (
                <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "12px 10px 2px" }}>
                  <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 13, color: sc }}>
                    {SPEAKER_NAMES[seg.speakerId]}
                  </span>
                  <Icon name="pencil" size={12} color={th.text3} strokeWidth={2} />
                </div>
              )}
              <button onClick={() => setPlayer(p => ({ ...p, time: seg.start, playing: true }))} style={{
                display: "flex", alignItems: "flex-start", gap: 12, textAlign: "left", border: "none", cursor: "pointer",
                background: active ? th.accentSoft : "transparent", borderRadius: 12, padding: "8px 10px",
                position: "relative" }}>
                {seg.speakerId != null && (
                  <span style={{ position: "absolute", left: 0, top: 6, bottom: 6, width: 3, borderRadius: 2, background: sc }} />
                )}
                <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 12.5, width: 42, flexShrink: 0,
                  color: active ? th.accentText : th.text3, paddingTop: 2 }}>{fmtTime(seg.start)}</span>
                <span style={{ fontFamily: "var(--font-display)", fontWeight: active ? 600 : 500, fontSize: 14.5, lineHeight: 1.4,
                  color: active ? th.accentText : th.text2 }}>{seg.text}</span>
              </button>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}

function PlayerBar({ th, player, setPlayer }) {
  const dur = 148;
  const frac = Math.min(1, player.time / dur);
  const rates = [1, 1.5, 2];
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 14, background: th.cardSunk, borderRadius: 18, padding: 14 }}>
      <button onClick={() => setPlayer(p => ({ ...p, playing: !p.playing }))} style={{ border: "none", background: "transparent", cursor: "pointer", padding: 0 }}>
        <div style={{ width: 44, height: 44, borderRadius: 999, background: primaryFill(th),
          display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Icon name={player.playing ? "pause" : "play"} size={22} color={th.onAccent} />
        </div>
      </button>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <div style={{ height: 4, borderRadius: 999, background: th.divider, position: "relative" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: `${frac * 100}%`, background: primaryFill(th), borderRadius: 999 }} />
        </div>
        <span style={{ fontFamily: "var(--font-mono)", fontSize: 12, color: th.text3 }}>{fmtTime(player.time)} / {fmtTime(dur)}</span>
      </div>
      <button onClick={() => setPlayer(p => ({ ...p, rate: rates[(rates.indexOf(p.rate) + 1) % 3] }))} style={{
        border: "none", cursor: "pointer", background: th.accentSoft, color: th.accentText, borderRadius: 999,
        padding: "6px 10px", fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 12.5 }}>
        {player.rate}x
      </button>
    </div>
  );
}

// ── Estenográfica ────────────────────────────────────────────────────────
function EstenoView({ th }) {
  const [cleaned, setCleaned] = React.useState(false);
  // group consecutive segments by speaker
  const turns = [];
  DEMO_SEGMENTS.forEach(s => {
    const last = turns[turns.length - 1];
    if (last && last.speakerId === s.speakerId) last.text += " " + s.text;
    else turns.push({ speakerId: s.speakerId, text: s.text });
  });
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ display: "flex", gap: 3, padding: 3, background: th.cardSunk, borderRadius: 999 }}>
          {["Limpia", "Original"].map((l, i) => {
            const sel = (i === 0) === cleaned;
            return (
              <button key={l} onClick={() => setCleaned(i === 0)} style={{ border: "none", cursor: "pointer",
                padding: "5px 14px", borderRadius: 999, background: sel ? primaryFill(th) : "transparent",
                color: sel ? th.onAccent : th.text3, fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 12.5 }}>{l}</button>
            );
          })}
        </div>
        <span style={{ flex: 1 }} />
        {cleaned && (
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <Icon name="warn" size={13} color={th.text3} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, color: th.text3 }}>Revisa antes de publicar</span>
          </div>
        )}
      </div>
      {turns.map((t, i) => {
        const sc = speakerColor(t.speakerId);
        return (
          <div key={i} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12, letterSpacing: "0.05em", color: sc }}>
                {SPEAKER_NAMES[t.speakerId].toUpperCase()}
              </span>
            </div>
            <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 16.5, lineHeight: 1.55, color: th.text1 }}>
              {cleaned ? t.text.replace(/\u2026/g, "").replace(/\s+/g, " ") : t.text}
            </p>
          </div>
        );
      })}
    </div>
  );
}

// ── Análisis ─────────────────────────────────────────────────────────────
function AnalysisView({ th }) {
  const a = DEMO_ANALYSIS;
  const [q, setQ] = React.useState("");
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 22 }}>
      <AnalysisBlock th={th} icon="align" title="Resumen">
        <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, lineHeight: 1.5, color: th.text2 }}>{a.resumen}</p>
      </AnalysisBlock>

      <AnalysisBlock th={th} icon="tag" title="Temas principales">
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {a.temas.map((t, i) => (
            <div key={i} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
              <span style={{ width: 5, height: 5, borderRadius: 999, background: th.accent, marginTop: 8, flexShrink: 0 }} />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, lineHeight: 1.4, color: th.text2 }}>{t}</span>
            </div>
          ))}
        </div>
      </AnalysisBlock>

      <AnalysisBlock th={th} icon="quote" title="Frases textuales (verificadas)">
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {a.frasesDestacadas.map((t, i) => (
            <div key={i} style={{ display: "flex", gap: 10 }}>
              <span style={{ width: 3, borderRadius: 2, background: th.goldFill, flexShrink: 0 }} />
              <span style={{ fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 15.5, lineHeight: 1.45, color: th.text1 }}>{t}</span>
            </div>
          ))}
        </div>
      </AnalysisBlock>

      <AnalysisBlock th={th} icon="news" title="Titulares sugeridos">
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {a.titulares.map((t, i) => (
            <div key={i} style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, lineHeight: 1.3, color: th.text1 }}>{t}</div>
          ))}
        </div>
      </AnalysisBlock>

      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <Icon name="warn" size={13} color={th.text3} strokeWidth={2} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>Verifica las citas con la grabación antes de publicar.</span>
      </div>

      <div style={{ height: 1, background: th.divider }} />

      {/* Pregúntale a esta entrevista */}
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <Eyebrow th={th} icon="question" color={th.accentText}>Pregúntale a esta entrevista</Eyebrow>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 8 }}>
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="Ej. ¿Qué dijo sobre el presupuesto?" style={{
            flex: 1, border: "none", outline: "none", background: th.cardSunk, borderRadius: 12, padding: "11px 12px",
            fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14, color: th.text1 }} />
          <button style={{ border: "none", background: "transparent", cursor: "pointer", padding: 0 }}>
            <Icon name="sendUp" size={32} color={q ? th.accentText : th.text3} strokeWidth={1.8} />
          </button>
        </div>
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>
          La IA responde solo con lo que se dijo en el audio.
        </span>
      </div>
    </div>
  );
}

function AnalysisBlock({ th, icon, title, children }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      <Eyebrow th={th} icon={icon} color={th.accentText}>{title}</Eyebrow>
      {children}
    </div>
  );
}

// ── Cortes ───────────────────────────────────────────────────────────────
function CortesView({ th, setPlayer }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      {DEMO_CORTES.map((b, i) => (
        <button key={i} onClick={() => setPlayer(p => ({ ...p, time: b.inicio, playing: true }))} style={{
          textAlign: "left", border: "none", cursor: "pointer", background: th.cardSunk, borderRadius: 14, padding: 14,
          display: "flex", flexDirection: "column", gap: 6 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 15, color: th.text1 }}>{b.tema}</span>
            <Icon name="play" size={22} color={th.accentText} />
          </div>
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 12.5, color: th.accentText }}>
            {fmtTime(b.inicio)} – {fmtTime(b.fin)}
          </span>
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5, lineHeight: 1.4, color: th.text2 }}>{b.resumen}</span>
        </button>
      ))}
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 2 }}>
        <Icon name="scissors" size={13} color={th.text3} strokeWidth={2} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>Toca un bloque para saltar a ese momento del audio.</span>
      </div>
    </div>
  );
}

Object.assign(window, { ResultsCard });
