// PrensaIA v3 — pestañas IA: Análisis (estados + preguntas) y Cortes (temas, selección, exportación).

// ── Análisis ────────────────────────────────────────────────────────────
function Analysis3({ th, app }) {
  const a = DEMO_ANALYSIS;
  const { qa } = app;
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
        <div style={{ display: "flex", flexDirection: "column" }}>
          {a.titulares.map((t, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none" }}>
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, lineHeight: 1.32, color: th.text1 }}>{t}</span>
              <Icon name="copy" size={16} color={th.text3} strokeWidth={2} />
            </div>
          ))}
        </div>
      </Block>

      <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 8px" }}>
        <Icon name="warn" size={13} color={th.text3} strokeWidth={2} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>
          Verifica las citas con la grabación antes de publicar.
        </span>
      </div>

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
            onClick={() => { if (q.trim() && qa.state !== "running") app.askQuestion(q); }}
            style={{ width: 42, height: 42, display: "flex", alignItems: "center", justifyContent: "center",
              flexShrink: 0, opacity: q.trim() && qa.state !== "running" ? 1 : 0.55 }}>
            <Icon name="sendUp" size={21} color={th.onAccent} strokeWidth={1.9} style={{ position: "relative" }} />
          </Glass>
        </div>
        <div style={{ position: "relative" }}>
          {qa.state === "running" ? (
            <LoadingRow th={th}>Pensando…</LoadingRow>
          ) : qa.state === "done" ? (
            <Glass th={th} clear radius={16} style={{ padding: 14 }}>
              <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14,
                lineHeight: 1.5, color: th.text1, position: "relative" }}>{qa.answer}</p>
            </Glass>
          ) : (
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>
              La IA responde solo con lo que se dijo en el audio.
            </span>
          )}
        </div>
      </Glass>
    </div>
  );
}

// ── Cortes ──────────────────────────────────────────────────────────────
function Cortes3({ th, app }) {
  const { blocks, selection } = app;
  const media = app.isVideo ? "video" : "audio";
  const all = [...app.manualBlocks.map(b => ({ ...b, manual: true })),
               ...(blocks.list || []).map(b => ({ ...b, manual: false }))];
  const selectedCount = all.filter(b => selection.has(b.id)).length;

  const SectionHead = ({ icon, children, count }) => (
    <div style={{ display: "flex", alignItems: "center", gap: 7, padding: "0 4px" }}>
      <Icon name={icon} size={14} color={th.gold} strokeWidth={2.2} />
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 11,
        letterSpacing: "0.13em", textTransform: "uppercase", color: th.gold }}>{children}</span>
      {count != null && <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 11, color: th.text3 }}>({count})</span>}
    </div>
  );

  const BloqueCard = ({ b }) => {
    const selected = selection.has(b.id);
    return (
      <div style={{ display: "flex", alignItems: "flex-start", gap: 10 }}>
        <button onClick={() => app.toggleSelection(b.id)} style={{ paddingTop: 14 }}>
          <Icon name={selected ? "checkFill" : "circle"} size={22}
            color={selected ? (th.statusDark ? th.accentText : th.accent) : th.text3} strokeWidth={1.8} />
        </button>
        <Glass th={th} as="button" press radius={20} onClick={() => app.playRange(b.inicio, b.fin)}
          style={{ flex: 1, textAlign: "left", padding: 14, display: "flex", flexDirection: "column", gap: 5,
            outline: selected ? `1.5px solid ${th.statusDark ? th.accentText : th.accent}` : "none", outlineOffset: -1.5 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, position: "relative" }}>
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 14.5, color: th.text1 }}>{b.tema}</span>
            <Badge th={th} kind={b.manual ? "mine" : "ia"} />
            <Icon name="play" size={20} color={th.accentText} />
          </div>
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 11.5, color: th.gold, position: "relative" }}>
            {fmtTime(b.inicio)} – {fmtTime(b.fin)}
          </span>
          {b.resumen && <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13,
            lineHeight: 1.38, color: th.text3, position: "relative" }}>{b.resumen}</span>}
        </Glass>
      </div>
    );
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      {/* Mis temas */}
      {app.manualBlocks.length > 0 && (
        <>
          <SectionHead icon="tap" count={app.manualBlocks.length}>Mis temas</SectionHead>
          {app.manualBlocks.map(b => <BloqueCard key={b.id} b={{ ...b, manual: true }} />)}
        </>
      )}

      {/* Sugeridos por la IA */}
      <SectionHead icon="sparkles" count={blocks.state === "done" ? (blocks.list || []).length : null}>Sugeridos por la IA</SectionHead>
      {blocks.state === "idle" && (
        <Glass th={th} radius={22} style={{ padding: 18, display: "flex", flexDirection: "column", gap: 12 }}>
          <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5,
            lineHeight: 1.45, color: th.text3, position: "relative" }}>
            La IA divide la entrevista en bloques por tema, con el minuto donde empieza y termina cada uno. Útil para encontrar tus cortes de video.
          </p>
          <GlassCTA th={th} icon="scissors" onClick={app.suggestBlocks}>Sugerir cortes por tema</GlassCTA>
        </Glass>
      )}
      {blocks.state === "running" && (
        <Glass th={th} radius={22} style={{ padding: 18, display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ position: "relative" }}>
            <LoadingRow th={th}>{blocks.progress > 0 ? `Buscando cortes… ${Math.round(blocks.progress * 100)}%` : "Buscando bloques por tema…"}</LoadingRow>
          </div>
          {blocks.progress > 0 && <div style={{ position: "relative" }}><ThinProgress th={th} value={blocks.progress} /></div>}
        </Glass>
      )}
      {blocks.state === "done" && (
        <>
          {(blocks.list || []).map(b => <BloqueCard key={b.id} b={{ ...b, manual: false }} />)}
          <button onClick={app.suggestBlocks} style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 6px", alignSelf: "flex-start" }}>
            <Icon name="refresh" size={13} color={th.accentText} strokeWidth={2.2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12, color: th.accentText }}>Volver a sugerir</span>
          </button>
        </>
      )}

      {/* barra de exportación */}
      {all.length > 0 && (
        app.clipExport.running ? (
          <Glass th={th} radius={22} style={{ padding: 18, display: "flex", flexDirection: "column", gap: 10 }}>
            <div style={{ position: "relative" }}><ThinProgress th={th} value={app.clipExport.progress} /></div>
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, position: "relative" }}>
              Exportando cortes… {Math.round(app.clipExport.progress * 100)}%
            </span>
          </Glass>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, padding: "0 6px" }}>
              Toca un bloque para previsualizar solo ese fragmento. Marca el círculo de los que quieras exportar como {media}.
            </span>
            <div style={{ display: "flex", alignItems: "center", padding: "0 6px" }}>
              <button onClick={() => app.selectAll(all)} style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: th.accentText }}>
                {selectedCount === all.length ? "Quitar todo" : "Seleccionar todo"}
              </button>
              <span style={{ flex: 1 }} />
              {selectedCount > 0 && (
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12, color: th.text3 }}>
                  {selectedCount} seleccionado{selectedCount === 1 ? "" : "s"}
                </span>
              )}
            </div>
            <div style={{ position: "relative" }}>
              <GlassCTA th={th} icon="scissors" disabled={selectedCount === 0}
                onClick={() => app.setExportMenu(true)}>
                {selectedCount === 0 ? "Exporta los cortes seleccionados" : `Exportar ${selectedCount} corte${selectedCount === 1 ? "" : "s"}`}
              </GlassCTA>
              {app.exportMenu && (
                <div style={{ position: "fixed", inset: 0, zIndex: 90 }} onClick={() => app.setExportMenu(false)}>
                  <Glass th={th} radius={20} className="lg-pop" style={{ position: "absolute", left: 24, right: 24,
                    bottom: 170, overflow: "hidden" }}>
                    {[
                      { label: `Exportar como ${media}s separados`, icon: "share", fn: () => app.exportClips(false) },
                      { label: `Unir en un solo ${media}`, icon: "film", fn: () => app.exportClips(true) },
                    ].map((it, i) => (
                      <button key={i} onClick={e => { e.stopPropagation(); app.setExportMenu(false); it.fn(); }}
                        style={{ display: "flex", alignItems: "center", gap: 12, width: "100%", textAlign: "left",
                          padding: "14px 18px", position: "relative", borderTop: i ? `1px solid ${th.divider}` : "none" }}>
                        <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5, color: th.text1 }}>{it.label}</span>
                        <Icon name={it.icon} size={18} color={th.accentText} strokeWidth={2} />
                      </button>
                    ))}
                  </Glass>
                </div>
              )}
            </div>
          </div>
        )
      )}

      {all.length === 0 && blocks.state === "idle" && (
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, padding: "0 6px" }}>
          ¿Quieres marcar tus propios temas? Ve a la pestaña “Por minuto” y toca “Marcar tema”.
        </span>
      )}
    </div>
  );
}

Object.assign(window, { Analysis3, Cortes3 });
