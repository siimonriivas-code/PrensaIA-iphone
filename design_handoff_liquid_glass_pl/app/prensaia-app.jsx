// PrensaIA — main app shell: navigation state machine, simulations, Tweaks.

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "headlineStyle": "serif"
}/*EDITMODE-END*/;

const LIVE_SCRIPT = "Garantizamos agua a más de cuarenta mil familias del oriente de Colima con una inversión histórica de cinco punto tres millones de pesos.";

function App({ t, setTweak, th }) {
  const [screen, setScreen] = React.useState("home");
  const [sheet, setSheet] = React.useState(null);
  const [tab, setTab] = React.useState("transcript");
  const [diariza, setDiariza] = React.useState(true);
  const [speakers, setSpeakers] = React.useState(0);
  const [player, setPlayer] = React.useState({ playing: false, time: 9, rate: 1 });

  // progress sim
  const [prog, setProg] = React.useState({ step: 0, frac: 0, title: "", subtitle: "", pct: null });
  // recording / live
  const [elapsed, setElapsed] = React.useState(0);
  const [live, setLive] = React.useState({ confirmed: "", hypothesis: "", done: false });

  const scrollRef = React.useRef(null);
  const resetScroll = () => { if (scrollRef.current) scrollRef.current.scrollTop = 0; };

  // ── player tick ──
  React.useEffect(() => {
    if (!player.playing) return;
    const id = setInterval(() => setPlayer(p => {
      const nt = p.time + 0.25 * p.rate;
      if (nt >= 148) return { ...p, time: 148, playing: false };
      return { ...p, time: nt };
    }), 250);
    return () => clearInterval(id);
  }, [player.playing, player.rate]);

  // ── recording elapsed ──
  React.useEffect(() => {
    if (screen !== "recording") return;
    const id = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(id);
  }, [screen]);

  // ── live streaming sim ──
  React.useEffect(() => {
    if (screen !== "live") return;
    setLive({ confirmed: "", hypothesis: "", done: false });
    const words = LIVE_SCRIPT.split(" ");
    let i = 0;
    const id = setInterval(() => {
      i++;
      if (i > words.length) { clearInterval(id); return; }
      const confirmed = words.slice(0, Math.max(0, i - 2)).join(" ");
      const hypothesis = words.slice(Math.max(0, i - 2), i).join(" ");
      setLive({ confirmed: confirmed ? confirmed + (confirmed ? " " : "") : "", hypothesis, done: false });
    }, 320);
    return () => clearInterval(id);
  }, [screen]);

  // ── progress → results sim ──
  function runProgress() {
    setScreen("progress"); resetScroll();
    const stages = [
      { step: 0, frac: null, pct: null, title: "Preparando el modelo…", subtitle: "Cargando Whisper en el dispositivo.", at: 0 },
      { step: 1, frac: 0.35, pct: 35, title: "Transcribiendo…", subtitle: "Convirtiendo el audio a texto, en español.", at: 1100 },
      { step: 1, frac: 0.78, pct: 78, title: "Transcribiendo…", subtitle: "Convirtiendo el audio a texto, en español.", at: 2200 },
      { step: 1, frac: 1, pct: 100, title: "Identificando oradores…", subtitle: "Detectando quién habla en cada intervención.", at: 3200 },
      { step: 2, frac: null, pct: null, title: "Analizando con IA…", subtitle: "Resumen, temas, frases y titulares.", at: 4100 },
    ];
    stages.forEach(s => setTimeout(() => setProg(s), s.at));
    setTimeout(() => { setScreen("results"); setTab("transcript"); setPlayer({ playing: false, time: 9, rate: 1 }); resetScroll(); }, 5400);
  }

  function startRecording() { setElapsed(0); setScreen("recording"); resetScroll(); }
  function startLive() { setScreen("live"); resetScroll(); }

  const headlineFont = t.headlineStyle === "serif" ? "var(--font-date)" : "var(--font-display)";

  return (
    <div style={{ position: "relative", height: "100%", overflow: "hidden", background: th.page,
      "--headline-font": headlineFont }}>
      <div ref={scrollRef} style={{ height: "100%", overflowY: "auto" }}>
      {/* top toolbar */}
      <div style={{ position: "sticky", top: 0, zIndex: 40, display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "54px 16px 10px", background: th.page }}>
        <ToolbarButton th={th} icon="book" onClick={() => setSheet("dictionary")} />
        <ToolbarButton th={th} icon="history" onClick={() => setSheet("history")} />
      </div>

      <div style={{ padding: "0 16px 40px", display: "flex", flexDirection: "column", gap: 18 }}>
        <Header th={th} />

        {screen === "home" && (
          <HomeCard th={th} onUpload={runProgress} onRecord={startRecording} onLive={startLive}
            diariza={diariza} setDiariza={setDiariza} speakers={speakers} setSpeakers={setSpeakers} />
        )}
        {screen === "recording" && (
          <RecordingCard th={th} elapsed={elapsed} onStop={runProgress} onCancel={() => setScreen("home")} />
        )}
        {screen === "live" && (
          <LiveCard th={th} confirmed={live.confirmed} hypothesis={live.hypothesis} done={live.done}
            onStop={() => setLive(l => ({ ...l, done: true, confirmed: LIVE_SCRIPT, hypothesis: "" }))}
            onClear={() => { setLive({ confirmed: "", hypothesis: "", done: false }); setScreen("home"); }} />
        )}
        {screen === "progress" && (
          <ProgressCard th={th} step={prog.step} frac={prog.frac} title={prog.title} subtitle={prog.subtitle} pct={prog.pct} />
        )}

        {screen === "results" && (
          <ResultsCard th={th} tab={tab} setTab={setTab} player={player} setPlayer={setPlayer}
            title={<span style={{ fontFamily: headlineFont, fontStyle: t.headlineStyle === "serif" ? "italic" : "normal" }}>
              Indira Vizcaíno entrega la rehabilitación del pozo profundo “Cuajiote”
            </span>} />
        )}

        {screen !== "home" && screen !== "progress" && (
          <button onClick={() => { setScreen("home"); setPlayer(p => ({ ...p, playing: false })); }} style={{
            border: "none", background: "transparent", cursor: "pointer", alignSelf: "center", padding: 8,
            fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 13.5, color: th.text3 }}>
            ← Volver al inicio
          </button>
        )}
      </div>
      </div>

      {sheet === "history" && (
        <HistorySheet th={th} onClose={() => setSheet(null)} theme={t.theme} setTheme={v => setTweak("theme", v)}
          onOpenItem={() => { setSheet(null); setScreen("results"); setTab("analysis"); resetScroll(); }} />
      )}
      {sheet === "dictionary" && <DictionarySheet th={th} onClose={() => setSheet(null)} />}

      <TweaksPanel>
        <TweakSection label="Tema" />
        <TweakRadio label="Apariencia" value={t.theme}
          options={[{ value: "light", label: "Claro" }, { value: "dark", label: "Oscuro" }]}
          onChange={v => setTweak("theme", v)} />
        <TweakSection label="Editorial" />
        <TweakRadio label="Titulares" value={t.headlineStyle}
          options={[{ value: "serif", label: "Serif" }, { value: "sans", label: "Montserrat" }]}
          onChange={v => setTweak("headlineStyle", v)} />
      </TweaksPanel>
    </div>
  );
}

function ToolbarButton({ th, icon, onClick }) {
  return (
    <button onClick={onClick} style={{ width: 42, height: 42, borderRadius: 999, border: "none", cursor: "pointer",
      background: th.card, boxShadow: th.shadow, display: "flex", alignItems: "center", justifyContent: "center" }}>
      <Icon name={icon} size={21} color={th.accentText} strokeWidth={2} />
    </button>
  );
}

function Root() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const th = PL_THEMES[t.theme] || PL_THEMES.light;
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh", padding: 24, boxSizing: "border-box" }}>
      <IOSDevice dark={t.theme === "dark"}>
        <App t={t} setTweak={setTweak} th={th} />
      </IOSDevice>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<Root />);
