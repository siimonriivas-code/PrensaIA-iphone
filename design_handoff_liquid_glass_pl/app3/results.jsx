// PrensaIA v3 — Resultados: cabecera con compartir/menú, modo edición,
// reproductor de onda, control segmentado y mini reproductor flotante.

const RESULT_TABS3 = [
  { value: "transcript", label: "Por minuto" },
  { value: "esteno", label: "Estenográfica" },
  { value: "analysis", label: "Análisis" },
  { value: "cortes", label: "Cortes" },
];

function ResultsScreen3({ th, app }) {
  const { resultsTab: tab, setResultsTab: setTab, player, setPlayer, headlineFont } = app;
  const [menuOpen, setMenuOpen] = React.useState(false);

  return (
    <div data-screen-label="Resultados" style={{ position: "absolute", inset: 0 }}>
      {/* botones flotantes */}
      <div style={{ position: "absolute", top: 54, left: 16, right: 16, zIndex: 60,
        display: "flex", justifyContent: "space-between", pointerEvents: "none" }}>
        <div style={{ pointerEvents: "auto" }}>
          {app.isEditing
            ? <Glass th={th} as="button" tint="wine" press radius={999} onClick={app.finishEditing}
                style={{ padding: "12px 20px" }}>
                <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 800,
                  fontSize: 14, color: th.onAccent }}>Listo</span>
              </Glass>
            : <CircleButton th={th} icon="chevronLeft" onClick={app.backHome} />}
        </div>
        {!app.isEditing && (
          <div style={{ display: "flex", gap: 10, pointerEvents: "auto" }}>
            <CircleButton th={th} icon="share" onClick={() => app.openShare("Cobertura — " + app.title, "Texto de la pestaña " + RESULT_TABS3.find(t => t.value === tab).label)} />
            <CircleButton th={th} icon="ellipsis" onClick={() => setMenuOpen(true)} />
          </div>
        )}
      </div>

      <MenuPopover th={th} open={menuOpen} onClose={() => setMenuOpen(false)} top={104}
        items={[
          { label: "Editar transcripción", icon: "pencil", onClick: app.startEditing },
          { label: "Copiar esta pestaña", icon: "copy" },
          { label: "Exportar a PDF", icon: "docText", onClick: () => app.openShare(app.title + ".pdf", "Documento PDF · 3 páginas") },
        ]} />

      <div className="lg-scroll" style={{ position: "absolute", inset: 0, overflowY: "auto",
        padding: "108px 18px 180px" }}>
        {/* título */}
        <div style={{ padding: "0 4px 16px" }}>
          <Eyebrow th={th} icon="news">Cobertura · Hoy, 9:41</Eyebrow>
          <h2 style={{ margin: "8px 0 0", fontFamily: headlineFont, fontStyle: headlineFont.includes("date") ? "italic" : "normal",
            fontWeight: 800, fontSize: 24, lineHeight: 1.22, letterSpacing: "-0.01em", color: th.text1 }}>
            {app.title}
          </h2>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 10 }}>
            <Icon name="clock" size={14} color={th.text3} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12.5, color: th.text3 }}>
              02:28 · 3 oradores{app.isVideo ? " · video" : ""} · motor {app.engine === "fast" ? "Rápido" : "Preciso"}
            </span>
          </div>
        </div>

        {app.isEditing ? (
          <EditView3 th={th} app={app} />
        ) : (
          <>
            {/* segmentado sticky */}
            <div style={{ position: "sticky", top: 0, zIndex: 50, padding: "6px 0 14px" }}>
              <Segmented th={th} value={tab} onChange={setTab} options={RESULT_TABS3} />
            </div>
            {tab === "transcript" && <Transcript3 th={th} app={app} />}
            {tab === "esteno" && <Esteno3 th={th} app={app} />}
            {tab === "analysis" && <Analysis3 th={th} app={app} />}
            {tab === "cortes" && <Cortes3 th={th} app={app} />}
          </>
        )}
      </div>

      {!app.isEditing && <MiniPlayer3 th={th} player={player} setPlayer={setPlayer} />}
    </div>
  );
}

// ── Modo edición (segmentos editables) ──────────────────────────────────
function EditView3({ th, app }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, padding: "0 6px" }}>
        Corrige el texto si hace falta. Los tiempos y el audio se conservan.
      </span>
      <Glass th={th} radius={26} style={{ padding: 16, display: "flex", flexDirection: "column", gap: 14 }}>
        {app.segments.map((seg, i) => (
          <div key={i} style={{ display: "flex", flexDirection: "column", gap: 6, position: "relative" }}>
            <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 12, color: th.accentText }}>{fmtTime(seg.start)}</span>
            <Glass th={th} clear radius={14} style={{ padding: "2px 3px" }}>
              <textarea value={seg.text} rows={2}
                onChange={e => app.editSegment(i, e.target.value)}
                style={{ width: "100%", border: "none", outline: "none", background: "transparent", resize: "none",
                  padding: "9px 11px", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14,
                  lineHeight: 1.4, color: th.text1, position: "relative", display: "block" }} />
            </Glass>
          </div>
        ))}
      </Glass>
    </div>
  );
}

// ── Mini reproductor flotante ───────────────────────────────────────────
function MiniPlayer3({ th, player, setPlayer }) {
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

Object.assign(window, { ResultsScreen3, MiniPlayer3, RESULT_TABS3 });
