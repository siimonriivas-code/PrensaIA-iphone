// PrensaIA v3 — pestañas de texto: Por minuto (onda + marcar tema) y Estenográfica (limpieza IA).

// ── Por minuto ──────────────────────────────────────────────────────────
function Transcript3({ th, app }) {
  const { player, setPlayer, segments, manual } = app;
  const dur = 148;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      {/* reproductor: video nativo o barra con onda (como playerArea del código) */}
      {app.isVideo ? (
        <VideoPlayer3 th={th} player={player} setPlayer={setPlayer} />
      ) : (
      <Glass th={th} radius={22} style={{ padding: "14px 16px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, position: "relative" }}>
          <WaveformSeek th={th} samples={WAVE_SAMPLES} progress={player.time / dur} height={44}
            onSeek={f => setPlayer(p => ({ ...p, time: f * dur }))} />
        </div>
      </Glass>
      )}

      {/* barra de marcado manual */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "0 6px", minHeight: 22 }}>
        {manual.mode ? (
          <>
            <Icon name="tap" size={14} color={th.accentText} strokeWidth={2} />
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12.5, color: th.accentText }}>
              {manual.start == null ? "Toca el inicio del tema" : manual.end == null ? "Ahora toca el final" : "Ponle nombre y guarda"}
            </span>
            <button onClick={app.cancelManual} style={{ fontFamily: "var(--font-display)", fontWeight: 700,
              fontSize: 12.5, color: th.text3 }}>Listo</button>
          </>
        ) : (
          <>
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
              Toca una frase para escucharla desde ese minuto
            </span>
            <button onClick={app.startManual} style={{ display: "flex", alignItems: "center", gap: 5,
              fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: th.accentText }}>
              <Icon name="scissors" size={14} color={th.accentText} strokeWidth={2.2} />
              Marcar tema
            </button>
          </>
        )}
      </div>

      {/* panel para nombrar el tema */}
      {manual.mode && manual.start != null && manual.end != null && (
        <Glass th={th} radius={20} className="lg-pop" style={{ padding: 16, display: "flex", flexDirection: "column", gap: 10 }}>
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 13.5, color: th.accentText, position: "relative" }}>
            Tema de {fmtTime(manual.start)} a {fmtTime(manual.end)}
          </span>
          <Glass th={th} clear radius={12} style={{ padding: "1px 2px" }}>
            <input value={manual.name} onChange={e => app.setManualName(e.target.value)}
              placeholder="Nombre del tema (ej. Seguridad)"
              style={{ width: "100%", border: "none", outline: "none", background: "transparent",
                padding: "11px 13px", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14,
                color: th.text1, position: "relative" }} />
          </Glass>
          <GlassCTA th={th} icon="check" onClick={app.saveManualTopic}>Guardar tema</GlassCTA>
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, color: th.text3, position: "relative" }}>
            Aparecerá en “Cortes”, en tu sección. Puedes marcar varios seguidos.
          </span>
        </Glass>
      )}

      {/* frases */}
      <Glass th={th} radius={26} style={{ padding: "8px 12px" }}>
        {segments.map((seg, i) => {
          const newSpeaker = seg.speakerId != null && (i === 0 || segments[i - 1].speakerId !== seg.speakerId);
          const active = player.time >= seg.start && player.time < seg.end;
          const inRange = app.segInManualRange(seg);
          const sc = lgSpeaker(th, seg.speakerId || 0);
          return (
            <React.Fragment key={i}>
              {newSpeaker && (
                <button onClick={() => app.openRename(seg.speakerId)}
                  style={{ display: "flex", alignItems: "center", gap: 6, padding: "14px 8px 4px", position: "relative" }}>
                  <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: sc }}>
                    {app.speakerName(seg.speakerId)}
                  </span>
                  <Icon name="pencil" size={12} color={th.text3} strokeWidth={2} />
                </button>
              )}
              <button onClick={() => manual.mode ? app.manualTap(seg) : setPlayer(p => ({ ...p, time: seg.start, playing: true }))}
                style={{ display: "flex", alignItems: "flex-start", gap: 11, width: "100%", textAlign: "left",
                  background: inRange ? th.accentSoftStrong || "rgba(97,16,41,0.16)" : active ? th.accentSoft : "transparent",
                  borderRadius: 14, padding: "8px 8px", position: "relative", transition: "background 0.2s" }}>
                {seg.speakerId != null && (
                  <span style={{ position: "absolute", left: 0, top: 7, bottom: 7, width: 3, borderRadius: 2, background: sc, opacity: 0.9 }} />
                )}
                <span style={{ fontFamily: "var(--font-mono)", fontWeight: 600, fontSize: 12, width: 40, flexShrink: 0,
                  color: active || inRange ? th.accentText : th.text3, paddingTop: 2.5, marginLeft: 7 }}>{fmtTime(seg.start)}</span>
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
function Esteno3({ th, app }) {
  const { clean } = app;
  const turns = groupTurns(app.segments);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      {/* barra de limpieza */}
      {clean.state === "running" ? (
        <Glass th={th} radius={18} style={{ padding: 14, display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ position: "relative" }}>
            <LoadingRow th={th}>Limpiando con IA… {Math.round(clean.progress * 100)}%</LoadingRow>
          </div>
          <div style={{ position: "relative" }}><ThinProgress th={th} value={clean.progress} /></div>
        </Glass>
      ) : clean.state === "done" ? (
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <Segmented th={th} small value={clean.show ? "limpia" : "original"} style={{ width: 190 }}
            onChange={v => app.setCleanShow(v === "limpia")}
            options={[{ value: "limpia", label: "Limpia" }, { value: "original", label: "Original" }]} />
          <span style={{ flex: 1 }} />
          {clean.show && (
            <span style={{ display: "flex", alignItems: "center", gap: 5 }}>
              <Icon name="warn" size={13} color={th.text3} strokeWidth={2} />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, color: th.text3 }}>Revisa antes de publicar</span>
            </span>
          )}
        </div>
      ) : (
        <button onClick={app.runClean} style={{ display: "flex", alignItems: "center", gap: 7, padding: "2px 6px", alignSelf: "flex-start" }}>
          <Icon name="sparkles" size={16} color={th.accentText} strokeWidth={2} />
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 14, color: th.accentText }}>Limpiar con IA</span>
        </button>
      )}

      {/* turnos */}
      <Glass th={th} radius={26} style={{ padding: "20px 20px 22px", display: "flex", flexDirection: "column", gap: 18 }}>
        {turns.map((t, i) => {
          const sc = lgSpeaker(th, t.speakerId || 0);
          return (
            <div key={i} style={{ display: "flex", flexDirection: "column", gap: 7, position: "relative" }}>
              {t.speakerId != null && (
                <button onClick={() => app.openRename(t.speakerId)} style={{ display: "flex", alignItems: "center", gap: 6, alignSelf: "flex-start" }}>
                  <span style={{ width: 9, height: 9, borderRadius: 999, background: sc }} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 11.5, letterSpacing: "0.06em", color: sc }}>
                    {app.speakerName(t.speakerId).toUpperCase()}
                  </span>
                  <Icon name="pencil" size={11} color={th.text3} strokeWidth={2} />
                </button>
              )}
              <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 16.5, lineHeight: 1.56, color: th.text1 }}>
                {clean.state === "done" && clean.show ? cleanTurnText(t.text) : t.text}
              </p>
            </div>
          );
        })}
      </Glass>
    </div>
  );
}

Object.assign(window, { Transcript3, Esteno3 });
