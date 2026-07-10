// PrensaIA v2 — Inicio (restructured), Grabando, En vivo, Progreso.

function HomeScreen({ th, onUpload, onRecord, onLive, diariza, setDiariza, speakers, setSpeakers, onOpenRecent }) {
  const today = "miércoles, 9 de julio";
  return (
    <div data-screen-label="Inicio" style={{ display: "flex", flexDirection: "column", gap: 22, padding: "0 18px" }}>
      {/* nav row */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <Glass th={th} radius={999} style={{ width: 46, height: 46, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <PLLogo th={th} size={30} />
        </Glass>
        <span style={{ fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 14.5, color: th.text3 }}>{today}</span>
      </div>

      {/* hero */}
      <div style={{ display: "flex", flexDirection: "column", gap: 7, padding: "2px 4px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <h1 style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 32,
            letterSpacing: "-0.02em", color: th.text1 }}>PrensaIA</h1>
          <Capsule th={th} style={{ fontSize: 11, letterSpacing: "0.06em" }}>IA LOCAL</Capsule>
        </div>
        <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5,
          color: th.text3, lineHeight: 1.4 }}>Transcribe, escucha y analiza tus entrevistas — sin internet.</p>
      </div>

      {/* primary action */}
      <GlassButton th={th} tint="wine" icon="upload" height={58} onClick={onUpload}>Subir audio o video</GlassButton>

      {/* action tiles */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12, marginTop: -8 }}>
        {[
          { icon: "mic", label: "Grabar", fn: onRecord },
          { icon: "livemic", label: "En vivo", fn: onLive },
          { icon: "photo", label: "Galería", fn: onUpload },
        ].map(a => (
          <Glass key={a.label} th={th} as="button" press radius={22} onClick={a.fn}
            style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
              gap: 8, height: 86 }}>
            <Icon name={a.icon} size={24} color={th.accentText} strokeWidth={2} style={{ position: "relative" }} />
            <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 700,
              fontSize: 13, color: th.text2 }}>{a.label}</span>
          </Glass>
        ))}
      </div>

      {/* speakers group */}
      <div>
        <SectionLabel th={th}>Oradores</SectionLabel>
        <Glass th={th} radius={22} style={{ padding: "4px 16px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "13px 0", position: "relative" }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, color: th.text1 }}>Identificar oradores</div>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, marginTop: 2, lineHeight: 1.35 }}>
                Detecta quién habla en cada intervención.
              </div>
            </div>
            <Toggle th={th} on={diariza} onClick={() => setDiariza(!diariza)} />
          </div>
          {diariza && (
            <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 0 14px",
              borderTop: `1px solid ${th.divider}`, position: "relative" }}>
              <div style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14, color: th.text1 }}>
                Número de oradores
              </div>
              <StepperChip th={th} onClick={() => setSpeakers(speakers >= 8 ? 0 : speakers + 1)}>
                {speakers === 0 ? "Automático" : speakers}
              </StepperChip>
            </div>
          )}
        </Glass>
      </div>

      {/* recents */}
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

      {/* privacy note */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6, padding: "0 12px" }}>
        <Icon name="check" size={14} color={th.gold} strokeWidth={2} />
        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
          Todo se procesa en tu iPhone, en español.
        </span>
      </div>
    </div>
  );
}

// ── Grabando (immersive) ────────────────────────────────────────────────
function RecordingScreen({ th, elapsed, onStop, onCancel }) {
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
        <GlassButton th={th} tint="red" icon="stop" height={56} onClick={onStop}>Detener y transcribir</GlassButton>
        <button onClick={onCancel} style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 15,
          color: th.text3, padding: 8 }}>Cancelar</button>
      </div>
    </div>
  );
}

// ── En vivo ─────────────────────────────────────────────────────────────
function LiveScreen({ th, confirmed, hypothesis, done, onStop, onAnalyze, onDone }) {
  return (
    <div data-screen-label="En vivo" style={{ display: "flex", flexDirection: "column", gap: 18, padding: "14px 18px 0" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        {done ? (
          <>
            <Icon name="check" size={21} color={th.statusDark ? "#7FBFA5" : "#3A6B5A"} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 17, color: th.text1 }}>Transcripción lista</span>
          </>
        ) : (
          <>
            <span className="pl-pulse" style={{ width: 11, height: 11, borderRadius: 999, background: th.redLive }} />
            <Capsule th={th} style={{ fontSize: 11.5, letterSpacing: "0.08em" }}>EN VIVO</Capsule>
            <span style={{ flex: 1 }} />
            <Icon name="waveform" size={21} color={th.accentText} strokeWidth={2} />
          </>
        )}
      </div>

      <Glass th={th} radius={26} style={{ padding: 20, minHeight: 220 }}>
        <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 18.5,
          lineHeight: 1.62, color: th.text1, position: "relative" }}>
          <span>{confirmed} </span>
          <span style={{ color: th.text3 }}>{hypothesis}</span>
          {!done && <span className="pl-caret" style={{ color: th.accentText }}>▍</span>}
        </p>
      </Glass>

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

// ── Progreso ────────────────────────────────────────────────────────────
function ProgressScreen({ th, stage, pct }) {
  const R = 54, C = 2 * Math.PI * R;
  const frac = pct == null ? null : pct / 100;
  const stages = [
    { id: 0, label: "Preparando el modelo", hint: "Whisper se carga en el dispositivo" },
    { id: 1, label: "Transcribiendo en español", hint: "Audio a texto, minuto a minuto" },
    { id: 2, label: "Identificando oradores", hint: "Quién habla en cada intervención" },
    { id: 3, label: "Analizando con IA", hint: "Resumen, frases y titulares" },
  ];
  return (
    <div data-screen-label="Procesando" style={{ display: "flex", flexDirection: "column", alignItems: "center",
      gap: 26, padding: "34px 24px 0" }}>
      <div style={{ position: "relative", width: 128, height: 128 }}>
        <svg width="128" height="128" viewBox="0 0 128 128">
          <circle cx="64" cy="64" r={R} fill="none" stroke={th.accentSoft} strokeWidth="9" />
          {frac == null ? (
            <circle className="pl-ring-spin" cx="64" cy="64" r={R} fill="none" stroke={th.accentText}
              strokeWidth="9" strokeLinecap="round" strokeDasharray={`${C * 0.25} ${C * 0.75}`} />
          ) : (
            <circle cx="64" cy="64" r={R} fill="none" stroke={th.accentText} strokeWidth="9" strokeLinecap="round"
              strokeDasharray={C} strokeDashoffset={C * (1 - frac)}
              transform="rotate(-90 64 64)" style={{ transition: "stroke-dashoffset 0.5s" }} />
          )}
        </svg>
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {frac == null
            ? <PLLogo th={th} size={40} />
            : <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 24, color: th.text1 }}>{pct}%</span>}
        </div>
      </div>

      <Glass th={th} radius={24} style={{ width: "100%", padding: "6px 18px" }}>
        {stages.map((s, i) => {
          const state = stage > s.id ? "done" : stage === s.id ? "active" : "pending";
          return (
            <div key={s.id} style={{ display: "flex", alignItems: "center", gap: 13, padding: "13px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative",
              opacity: state === "pending" ? 0.45 : 1, transition: "opacity 0.3s" }}>
              {state === "done" && <Icon name="check" size={20} color={th.gold} strokeWidth={2.1} />}
              {state === "active" && <Spinner th={th} size={16} />}
              {state === "pending" && <span style={{ width: 20, display: "flex", justifyContent: "center" }}>
                <span style={{ width: 7, height: 7, borderRadius: 999, background: th.text3 }} /></span>}
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: "var(--font-display)", fontWeight: state === "active" ? 800 : 600,
                  fontSize: 14.5, color: th.text1 }}>{s.label}</div>
                {state === "active" && <div style={{ fontFamily: "var(--font-display)", fontWeight: 500,
                  fontSize: 12, color: th.text3, marginTop: 1 }}>{s.hint}</div>}
              </div>
            </div>
          );
        })}
      </Glass>

      <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>
        Puedes bloquear la pantalla; seguimos trabajando.
      </span>
    </div>
  );
}

Object.assign(window, { HomeScreen, RecordingScreen, LiveScreen, ProgressScreen });
