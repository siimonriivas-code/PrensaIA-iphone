// PrensaIA v3 — Inicio (chip de motor + 5 acciones), Grabando, En vivo (mic), Progreso.

function HomeScreen3({ th, engine, engineState, onUpload, onRecord, onLive, onGallery, onFBLive,
  diariza, setDiariza, speakers, setSpeakers, onOpenRecent }) {
  const ok = th.statusDark ? "#7FBFA5" : "#3A6B5A";
  const chip = (() => {
    if (engine === "fast") {
      if (engineState.fastDownloading) return { icon: "download", color: th.gold, text: "Descargando motor Rápido", pct: Math.round(engineState.fastProgress * 100) };
      if (engineState.fastDownloaded) return { icon: "checkFill", color: ok, text: "Motor Rápido listo" };
      return { icon: "download", color: th.text3, text: "Motor Rápido: sin descargar" };
    }
    if (engineState.whisperReady) return { icon: "checkFill", color: ok, text: "Listo para transcribir" };
    return { icon: "circle", color: th.gold, text: "Preparando el motor…", busy: true };
  })();

  return (
    <div data-screen-label="Inicio" style={{ display: "flex", flexDirection: "column", gap: 20, padding: "0 18px" }}>
      {/* nav row */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <Glass th={th} radius={999} style={{ width: 46, height: 46, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <PLLogo th={th} size={30} />
        </Glass>
        <span style={{ fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 14.5, color: th.text3 }}>viernes, 10 de julio</span>
      </div>

      {/* hero */}
      <div style={{ display: "flex", flexDirection: "column", gap: 7, padding: "0 4px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <h1 style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 32,
            letterSpacing: "-0.02em", color: th.text1 }}>PrensaIA</h1>
          <Capsule th={th} style={{ fontSize: 11, letterSpacing: "0.06em" }}>IA LOCAL</Capsule>
        </div>
        <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5,
          color: th.text3, lineHeight: 1.4 }}>Transcribe, escucha y analiza — sin internet.</p>
      </div>

      {/* semáforo del motor */}
      <div style={{ display: "flex", justifyContent: "center", marginTop: -6 }}>
        <Glass th={th} clear radius={999} style={{ display: "flex", alignItems: "center", gap: 8, padding: "7px 15px" }}>
          <span className={chip.busy ? "pl-pulse" : ""} style={{ display: "flex", position: "relative" }}>
            <Icon name={chip.icon} size={14} color={chip.color} strokeWidth={2.2} />
          </span>
          <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12, color: th.text3 }}>
            {chip.text}
          </span>
          {chip.pct != null && <span style={{ position: "relative", fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 12, color: th.text3 }}>{chip.pct}%</span>}
        </Glass>
      </div>

      {/* acción principal */}
      <GlassButton th={th} tint="wine" icon="upload" height={58} onClick={onUpload}>Subir audio o video</GlassButton>

      {/* mosaico de acciones */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12, marginTop: -6 }}>
        {[
          { icon: "mic", label: "Grabar", fn: onRecord },
          { icon: "livemic", label: "En vivo", fn: onLive },
          { icon: "photo", label: "Galería", fn: onGallery },
        ].map(a => (
          <Glass key={a.label} th={th} as="button" press radius={22} onClick={a.fn}
            style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
              gap: 8, height: 84 }}>
            <Icon name={a.icon} size={24} color={th.accentText} strokeWidth={2} style={{ position: "relative" }} />
            <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 700,
              fontSize: 13, color: th.text2 }}>{a.label}</span>
          </Glass>
        ))}
      </div>

      {/* Facebook Live */}
      <Glass th={th} as="button" press radius={22} onClick={onFBLive}
        style={{ display: "flex", alignItems: "center", gap: 14, padding: "15px 18px", marginTop: -6, textAlign: "left" }}>
        <Icon name="radio" size={23} color={th.accentText} strokeWidth={2} style={{ position: "relative", flexShrink: 0 }} />
        <div style={{ flex: 1, position: "relative" }}>
          <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, color: th.text1 }}>Transcribir Facebook Live</div>
          <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, marginTop: 1 }}>
            Captura el audio de una transmisión y léela casi en vivo.
          </div>
        </div>
        <Icon name="chevron" size={16} color={th.text3} strokeWidth={2.2} />
      </Glass>

      {/* oradores */}
      <div>
        <SectionLabel th={th}>Oradores</SectionLabel>
        <Glass th={th} radius={22} style={{ padding: "4px 16px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "13px 0", position: "relative" }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, color: th.text1 }}>Identificar oradores</div>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, marginTop: 2, lineHeight: 1.35 }}>
                Detecta quién habla. La 1ª vez descarga un modelo.
              </div>
            </div>
            <Toggle th={th} on={diariza} onClick={() => setDiariza(!diariza)} />
          </div>
          {diariza && (
            <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 0 14px",
              borderTop: `1px solid ${th.divider}`, position: "relative" }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14, color: th.text1 }}>Número de oradores</div>
                <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, marginTop: 1 }}>Indícalo si lo sabes: es más preciso.</div>
              </div>
              <StepperChip th={th} onClick={() => setSpeakers(speakers >= 8 ? 0 : speakers === 0 ? 2 : speakers + 1)}>
                {speakers === 0 ? "Automático" : speakers}
              </StepperChip>
            </div>
          )}
        </Glass>
      </div>

      {/* recientes */}
      <div>
        <SectionLabel th={th}>Recientes</SectionLabel>
        <Glass th={th} radius={22} style={{ padding: "0 16px" }}>
          {DEMO_HISTORY.slice(0, 2).map((it, i) => (
            <button key={i} onClick={onOpenRecent} style={{
              display: "flex", alignItems: "center", gap: 12, width: "100%", textAlign: "left",
              padding: "14px 0", borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative" }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14, color: th.text1,
                  whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{it.title}</div>
                <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, marginTop: 2 }}>{it.date}</div>
              </div>
              <Icon name="chevron" size={16} color={th.text3} strokeWidth={2.2} />
            </button>
          ))}
        </Glass>
      </div>

      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6, padding: "0 12px" }}>
        <Icon name="check" size={14} color={th.gold} strokeWidth={2} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
          Se procesa en tu iPhone, en español y sin internet.
        </span>
      </div>
    </div>
  );
}

// ── Grabando ────────────────────────────────────────────────────────────
function RecordingScreen3({ th, elapsed, onStop, onCancel }) {
  const bars = React.useMemo(() => Array.from({ length: 26 }, () => 0.25 + Math.random() * 0.75), []);
  return (
    <div data-screen-label="Grabando" style={{ display: "flex", flexDirection: "column", alignItems: "center",
      gap: 28, padding: "40px 24px 0" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
        <span className="pl-pulse" style={{ width: 11, height: 11, borderRadius: 999, background: th.redLive }} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 16, letterSpacing: "0.02em", color: th.text1 }}>Grabando</span>
      </div>
      <div style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 58, letterSpacing: "-0.02em",
        color: th.text1, fontVariantNumeric: "tabular-nums" }}>{fmtTime(elapsed)}</div>
      <Glass th={th} radius={26} style={{ width: "100%", padding: "26px 22px" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 4, height: 64, position: "relative" }}>
          {bars.map((h, i) => (
            <div key={i} className="lg-wavebar" style={{ width: 4.5, height: `${h * 100}%`, borderRadius: 999,
              background: i % 5 === 2 ? th.goldFill : th.accentText,
              animationDelay: `${(i % 9) * 0.11}s`, opacity: 0.85 }} />
          ))}
        </div>
      </Glass>
      <div style={{ display: "flex", flexDirection: "column", gap: 14, width: "100%", alignItems: "center" }}>
        <GlassButton th={th} tint="wine" icon="stop" height={56} onClick={onStop}>Detener y transcribir</GlassButton>
        <button onClick={onCancel} style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 15,
          color: th.redLive, padding: 8 }}>Cancelar</button>
      </div>
    </div>
  );
}

// ── En vivo (micrófono) ─────────────────────────────────────────────────
function LiveMicScreen3({ th, starting, confirmed, hypothesis, done, onStop, onAnalyze, onDone }) {
  const boxRef = React.useRef(null);
  React.useEffect(() => {
    if (boxRef.current) boxRef.current.scrollTop = boxRef.current.scrollHeight;
  }, [confirmed, hypothesis]);
  const ok = th.statusDark ? "#7FBFA5" : "#3A6B5A";
  return (
    <div data-screen-label="En vivo" style={{ display: "flex", flexDirection: "column", gap: 16, padding: "14px 18px 0" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        {done ? (
          <>
            <Icon name="checkFill" size={21} color={ok} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 17, color: th.text1 }}>Transcripción lista</span>
          </>
        ) : (
          <>
            <span className="pl-pulse" style={{ width: 11, height: 11, borderRadius: 999, background: th.redLive }} />
            <Capsule th={th} style={{ fontSize: 11.5, letterSpacing: "0.08em" }}>{starting ? "PREPARANDO…" : "EN VIVO"}</Capsule>
            <span style={{ flex: 1 }} />
            <Icon name="waveform" size={21} color={th.accentText} strokeWidth={2} />
          </>
        )}
      </div>

      <Glass th={th} radius={26} style={{ padding: "4px 20px" }}>
        <div ref={boxRef} className="lg-scroll" style={{ height: 240, overflowY: "auto", padding: "16px 0", position: "relative" }}>
          <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 18,
            lineHeight: 1.62, color: th.text1 }}>
            <span>{confirmed} </span>
            <span style={{ color: th.text3 }}>{hypothesis}</span>
            {!done && !starting && <span className="pl-caret" style={{ color: th.accentText }}>▍</span>}
          </p>
        </div>
      </Glass>

      {starting ? (
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>
          Despertando el modelo… habla en un momento.
        </span>
      ) : !done && !confirmed && !hypothesis ? (
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>
          Empieza a hablar… el texto aparecerá aquí.
        </span>
      ) : null}

      {done ? (
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <GlassButton th={th} tint="wine" icon="sparkles" height={54} onClick={onAnalyze}>Analizar con IA</GlassButton>
          <div style={{ display: "flex", gap: 12 }}>
            <GlassButton th={th} icon="copy" height={50} style={{ flex: 1 }}>Copiar texto</GlassButton>
            <GlassButton th={th} height={50} style={{ flex: 0.6 }} onClick={onDone}>Listo</GlassButton>
          </div>
        </div>
      ) : (
        <div style={{ display: "flex", gap: 12 }}>
          <GlassButton th={th} tint="red" icon="stop" height={54} style={{ flex: 1 }} onClick={onStop}>Detener</GlassButton>
          <CircleButton th={th} icon="copy" size={54} />
        </div>
      )}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3, textAlign: "center" }}>
        El texto gris es provisional; se confirma al escuchar mejor.
      </span>
    </div>
  );
}

// ── Progreso (etapas reales del servicio) ───────────────────────────────
function ProgressScreen3({ th, phase, frac, diariza }) {
  // phase: preparingModel | processingAudio | transcribing | diarizing | analyzing
  const R = 54, C = 2 * Math.PI * R;
  const stepIndex = phase === "preparingModel" || phase === "processingAudio" ? 0
    : phase === "transcribing" || phase === "diarizing" ? 1 : 2;
  const stage = {
    preparingModel: { t: "Preparando el modelo", s: "Solo la primera vez. Un momento…" },
    processingAudio: { t: "Procesando el audio", s: "Preparando el audio para transcribir…" },
    transcribing: { t: "Transcribiendo", s: "Reconociendo el habla en español…" },
    diarizing: { t: "Identificando oradores", s: "Detectando quién habla. La 1ª vez descarga un modelo…" },
    analyzing: { t: "Analizando con IA", s: "Resumen, temas, frases y titulares…" },
  }[phase];
  const pct = phase === "transcribing" ? Math.round(frac * 100) : null;
  return (
    <div data-screen-label="Procesando" style={{ display: "flex", flexDirection: "column", alignItems: "center",
      gap: 26, padding: "30px 24px 0" }}>
      <div style={{ position: "relative", width: 128, height: 128 }}>
        <svg width="128" height="128" viewBox="0 0 128 128">
          <circle cx="64" cy="64" r={R} fill="none" stroke={th.accentSoft} strokeWidth="9" />
          {pct == null ? (
            <circle className="pl-ring-spin" cx="64" cy="64" r={R} fill="none" stroke={th.accentText}
              strokeWidth="9" strokeLinecap="round" strokeDasharray={`${C * 0.25} ${C * 0.75}`} />
          ) : (
            <circle cx="64" cy="64" r={R} fill="none" stroke={th.accentText} strokeWidth="9" strokeLinecap="round"
              strokeDasharray={C} strokeDashoffset={C * (1 - frac)}
              transform="rotate(-90 64 64)" style={{ transition: "stroke-dashoffset 0.4s" }} />
          )}
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {pct == null ? <PLLogo th={th} size={40} />
            : <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 24, color: th.text1 }}>{pct}%</span>}
        </div>
      </div>

      {/* pasos Preparar / Transcribir / Analizar */}
      <div style={{ display: "flex", gap: 8, width: "100%" }}>
        {["Preparar", "Transcribir", "Analizar"].map((label, i) => (
          <div key={label} style={{ flex: 1, display: "flex", flexDirection: "column", gap: 7, alignItems: "center" }}>
            <div style={{ height: 5, width: "100%", borderRadius: 999,
              background: i <= stepIndex ? (th.statusDark ? th.accentText : th.accent) : th.divider,
              transition: "background 0.3s" }} />
            <span style={{ fontFamily: "var(--font-display)", fontSize: 11.5,
              fontWeight: i === stepIndex ? 800 : 500,
              color: i <= stepIndex ? th.accentText : th.text3 }}>{label}</span>
          </div>
        ))}
      </div>

      <Glass th={th} radius={24} style={{ width: "100%", padding: "18px 18px 20px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, position: "relative" }}>
          <Spinner th={th} size={16} />
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 16, color: th.text1 }}>{stage.t}</span>
          <span style={{ flex: 1 }} />
          {pct != null && <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 15, color: th.accentText }}>{pct}%</span>}
        </div>
        {pct != null && <div style={{ marginTop: 12, position: "relative" }}><ThinProgress th={th} value={frac} /></div>}
        <div style={{ marginTop: 10, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5,
          color: th.text3, position: "relative" }}>{stage.s}</div>
      </Glass>

      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
        Puedes bloquear la pantalla; seguimos trabajando.
      </span>
    </div>
  );
}

Object.assign(window, { HomeScreen3, RecordingScreen3, LiveMicScreen3, ProgressScreen3 });
