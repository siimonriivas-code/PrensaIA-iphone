// PrensaIA — input screens: header, home, recording, live, progress.

function Header({ th }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, paddingTop: 6 }}>
      <div style={{ width: 78, height: 78, borderRadius: 22, background: th.accentSoft,
        display: "flex", alignItems: "center", justifyContent: "center" }}>
        <PLLogo th={th} size={58} />
      </div>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 27,
          letterSpacing: "-0.01em", color: th.text1 }}>PrensaIA</div>
        <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14, color: th.text3, marginTop: 2 }}>
          Transcribe, escucha y analiza
        </div>
      </div>
    </div>
  );
}

function HomeCard({ th, onUpload, onRecord, onLive, diariza, setDiariza, speakers, setSpeakers }) {
  return (
    <Card th={th}>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <PrimaryButton th={th} icon="upload" onClick={onUpload}>Subir audio o video</PrimaryButton>
        <SecondaryButton th={th} icon="mic" onClick={onRecord}>Grabar audio</SecondaryButton>
        <SecondaryButton th={th} icon="livemic" onClick={onLive}>Transcripción en vivo</SecondaryButton>
        <SecondaryButton th={th} icon="photo" onClick={onUpload}>Elegir video de la galería</SecondaryButton>

        <div style={{ height: 1, background: th.divider, margin: "4px 0" }} />

        {/* Identificar oradores */}
        <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, color: th.text1 }}>
              Identificar oradores
            </div>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, marginTop: 2, lineHeight: 1.35 }}>
              Detecta quién habla. La 1ª vez descarga un modelo.
            </div>
          </div>
          <Toggle th={th} on={diariza} onClick={() => setDiariza(!diariza)} />
        </div>

        {diariza && (
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14, color: th.text1 }}>
                Número de oradores
              </div>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, marginTop: 2 }}>
                Indícalo si lo sabes: es más preciso.
              </div>
            </div>
            <button onClick={() => setSpeakers(speakers >= 8 ? 0 : speakers + 1)} style={{
              display: "flex", alignItems: "center", gap: 5, border: "none", cursor: "pointer",
              background: th.accentSoft, color: th.accentText, padding: "8px 12px", borderRadius: 999,
              fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14 }}>
              {speakers === 0 ? "Automático" : speakers}
              <Icon name="chevUpDown" size={13} color={th.accentText} strokeWidth={2.2} />
            </button>
          </div>
        )}

        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6, marginTop: 2 }}>
          <Icon name="check" size={14} color={th.gold} strokeWidth={2} />
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3, textAlign: "center" }}>
            Se procesa en tu iPhone, en español y sin internet.
          </span>
        </div>
      </div>
    </Card>
  );
}

function Toggle({ th, on, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 51, height: 31, borderRadius: 999, border: "none", cursor: "pointer", padding: 2,
      background: on ? primaryFill(th) : (th.statusDark ? "rgba(255,255,255,0.18)" : "#E3DCD6"),
      display: "flex", justifyContent: on ? "flex-end" : "flex-start", transition: "all .2s" }}>
      <div style={{ width: 27, height: 27, borderRadius: 999, background: "#fff",
        boxShadow: "0 1px 3px rgba(0,0,0,0.25)" }} />
    </button>
  );
}

function RecordingCard({ th, elapsed, onStop, onCancel }) {
  return (
    <Card th={th}>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ width: 12, height: 12, borderRadius: 999, background: th.redLive,
            boxShadow: `0 0 0 4px ${th.accentSoft}` }} className="pl-pulse" />
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 18, color: th.text1 }}>Grabando…</span>
          <span style={{ flex: 1 }} />
          <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 20, color: th.accentText }}>{fmtTime(elapsed)}</span>
        </div>
        <PrimaryButton th={th} icon="stop" onClick={onStop}>Detener y transcribir</PrimaryButton>
        <button onClick={onCancel} style={{ border: "none", background: "transparent", cursor: "pointer",
          fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 15, color: th.redLive }}>Cancelar</button>
      </div>
    </Card>
  );
}

function LiveCard({ th, confirmed, hypothesis, done, onStop, onClear }) {
  return (
    <Card th={th}>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          {done ? (
            <>
              <Icon name="check" size={22} color="#3A6B5A" strokeWidth={2} fill="none" />
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 18, color: th.text1 }}>Transcripción lista</span>
            </>
          ) : (
            <>
              <span style={{ width: 12, height: 12, borderRadius: 999, background: th.redLive }} className="pl-pulse" />
              <Capsule th={th} variant="wine" style={{ fontSize: 12, padding: "3px 12px" }}>EN VIVO</Capsule>
              <span style={{ flex: 1 }} />
              <Icon name="waveform" size={22} color={th.accentText} strokeWidth={2} />
            </>
          )}
        </div>

        <div style={{ minHeight: 150, maxHeight: 230, overflow: "auto", background: th.cardSunk,
          borderRadius: 16, padding: 14 }}>
          <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 17.5, lineHeight: 1.6, color: th.text1 }}>
            <span>{confirmed} </span>
            <span style={{ color: th.text3 }}>{hypothesis}</span>
            {!done && <span className="pl-caret" style={{ color: th.accentText }}>▍</span>}
          </p>
        </div>

        {done ? (
          <div style={{ display: "flex", gap: 12 }}>
            <PrimaryButton th={th} icon="copy" onClick={onClear} style={{ flex: 1 }}>Copiar texto</PrimaryButton>
            <button onClick={onClear} style={{ border: "none", background: "transparent", cursor: "pointer", padding: "0 8px",
              fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, color: th.text3 }}>Listo</button>
          </div>
        ) : (
          <div style={{ display: "flex", gap: 12 }}>
            <PrimaryButton th={th} icon="stop" onClick={onStop} style={{ flex: 1 }}>Detener</PrimaryButton>
            <button style={{ border: "none", cursor: "pointer", background: th.accentSoft, borderRadius: 14,
              width: 54, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name="copy" size={20} color={th.accentText} />
            </button>
          </div>
        )}
      </div>
    </Card>
  );
}

function ProgressCard({ th, step, frac, title, subtitle, pct }) {
  const steps = ["Preparar", "Transcribir", "Analizar"];
  return (
    <Card th={th}>
      <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
        <div style={{ display: "flex", gap: 8 }}>
          {steps.map((label, i) => (
            <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", gap: 7, alignItems: "center" }}>
              <div style={{ height: 5, width: "100%", borderRadius: 999,
                background: i <= step ? primaryFill(th) : th.divider }} />
              <span style={{ fontFamily: "var(--font-display)", fontSize: 11.5,
                fontWeight: i === step ? 700 : 500,
                color: i <= step ? th.accentText : th.text3 }}>{label}</span>
            </div>
          ))}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <Spinner th={th} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 18, color: th.text1 }}>{title}</span>
            <span style={{ flex: 1 }} />
            {pct != null && <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 16, color: th.accentText }}>{pct}%</span>}
          </div>
          {frac != null && (
            <div style={{ height: 6, borderRadius: 999, background: th.divider, overflow: "hidden" }}>
              <div style={{ height: "100%", width: `${frac * 100}%`, background: primaryFill(th), borderRadius: 999, transition: "width .3s" }} />
            </div>
          )}
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12.5, color: th.text3 }}>{subtitle}</span>
        </div>
      </div>
    </Card>
  );
}

function Spinner({ th, size = 18 }) {
  return (
    <div className="pl-spin" style={{ width: size, height: size, borderRadius: 999,
      border: `2.5px solid ${th.accentSoft}`, borderTopColor: th.accentText }} />
  );
}

Object.assign(window, { Header, HomeCard, RecordingCard, LiveCard, ProgressCard, Toggle, Spinner });
