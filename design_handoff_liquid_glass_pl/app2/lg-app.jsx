// PrensaIA v2 — shell: tabs, flows, scroll-aware chrome, Tweaks.

const LG_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "glass": "regular",
  "headlineStyle": "serif"
}/*EDITMODE-END*/;

const LG_LIVE_SCRIPT = "Garantizamos agua a más de cuarenta mil familias del oriente de Colima con una inversión histórica de cinco punto tres millones de pesos.";

function LGApp({ t, setTweak, th }) {
  const [tab, setTab] = React.useState("inicio");
  const [flow, setFlow] = React.useState(null); // null | recording | live | progress | results
  const [resultsTab, setResultsTab] = React.useState("transcript");
  const [diariza, setDiariza] = React.useState(true);
  const [speakers, setSpeakers] = React.useState(0);
  const [player, setPlayer] = React.useState({ playing: false, time: 9, rate: 1 });
  const [compact, setCompact] = React.useState(false);
  const [elapsed, setElapsed] = React.useState(0);
  const [live, setLive] = React.useState({ confirmed: "", hypothesis: "", done: false });
  const [prog, setProg] = React.useState({ stage: 0, pct: null });
  const lastY = React.useRef(0);
  const timers = React.useRef([]);

  // player tick
  React.useEffect(() => {
    if (!player.playing || flow !== "results") return;
    const id = setInterval(() => setPlayer(p => {
      const nt = p.time + 0.25 * p.rate;
      return nt >= 148 ? { ...p, time: 148, playing: false } : { ...p, time: nt };
    }), 250);
    return () => clearInterval(id);
  }, [player.playing, player.rate, flow]);

  // recording timer
  React.useEffect(() => {
    if (flow !== "recording") return;
    setElapsed(0);
    const id = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(id);
  }, [flow]);

  // live stream sim
  React.useEffect(() => {
    if (flow !== "live") return;
    setLive({ confirmed: "", hypothesis: "", done: false });
    const words = LG_LIVE_SCRIPT.split(" ");
    let i = 0;
    const id = setInterval(() => {
      i++;
      if (i > words.length) { clearInterval(id); return; }
      setLive(l => l.done ? l : {
        confirmed: words.slice(0, Math.max(0, i - 2)).join(" "),
        hypothesis: words.slice(Math.max(0, i - 2), i).join(" "),
        done: false,
      });
    }, 300);
    return () => clearInterval(id);
  }, [flow]);

  const clearTimers = () => { timers.current.forEach(clearTimeout); timers.current = []; };

  function runProgress() {
    clearTimers();
    setProg({ stage: 0, pct: null });
    setFlow("progress");
    const seq = [
      [700,  { stage: 1, pct: 18 }],
      [1500, { stage: 1, pct: 56 }],
      [2300, { stage: 1, pct: 92 }],
      [2900, { stage: 2, pct: null }],
      [3900, { stage: 3, pct: null }],
    ];
    seq.forEach(([at, s]) => timers.current.push(setTimeout(() => setProg(s), at)));
    timers.current.push(setTimeout(() => {
      setResultsTab("transcript");
      setPlayer({ playing: false, time: 9, rate: 1 });
      setFlow("results");
    }, 5200));
  }

  function onScroll(e) {
    const y = e.target.scrollTop;
    const dy = y - lastY.current;
    lastY.current = y;
    if (y > 70 && dy > 4 && !compact) setCompact(true);
    else if ((dy < -6 || y < 40) && compact) setCompact(false);
  }

  const headlineFont = t.headlineStyle === "serif" ? "var(--font-date)" : "var(--font-display)";
  const showTabBar = flow === null || flow === "results";
  const immersive = flow === "recording" || flow === "live" || flow === "progress";

  return (
    <div style={{ position: "relative", height: "100%", overflow: "hidden", background: th.base }}>
      <Ambient th={th} />

      {/* tab content */}
      {flow === null && (
        <div key={tab} className="lg-scroll lg-pop" onScroll={onScroll}
          style={{ position: "absolute", inset: 0, overflowY: "auto", padding: "64px 0 130px" }}>
          {tab === "inicio" && (
            <HomeScreen th={th}
              onUpload={runProgress}
              onRecord={() => setFlow("recording")}
              onLive={() => setFlow("live")}
              diariza={diariza} setDiariza={setDiariza}
              speakers={speakers} setSpeakers={setSpeakers}
              onOpenRecent={() => { setResultsTab("transcript"); setFlow("results"); }} />
          )}
          {tab === "historial" && (
            <HistorialScreen th={th} theme={t.theme} setTheme={v => setTweak("theme", v)}
              onOpenItem={() => { setResultsTab("analysis"); setFlow("results"); }} />
          )}
          {tab === "diccionario" && <DiccionarioScreen th={th} />}
        </div>
      )}

      {/* immersive flows */}
      {immersive && (
        <div className="lg-push" style={{ position: "absolute", inset: 0, zIndex: 80, paddingTop: 64 }}>
          {flow === "recording" && (
            <RecordingScreen th={th} elapsed={elapsed}
              onStop={runProgress} onCancel={() => setFlow(null)} />
          )}
          {flow === "live" && (
            <LiveScreen th={th} confirmed={live.confirmed} hypothesis={live.hypothesis} done={live.done}
              onStop={() => setLive({ confirmed: LG_LIVE_SCRIPT, hypothesis: "", done: true })}
              onAnalyze={runProgress}
              onDone={() => setFlow(null)} />
          )}
          {flow === "progress" && <ProgressScreen th={th} stage={prog.stage} pct={prog.pct} />}
        </div>
      )}

      {/* results */}
      {flow === "results" && (
        <div className="lg-push" style={{ position: "absolute", inset: 0, zIndex: 60 }}>
          <ResultsScreen th={th} tab={resultsTab} setTab={setResultsTab}
            player={player} setPlayer={setPlayer} headlineFont={headlineFont}
            onBack={() => { setFlow(null); setPlayer(p => ({ ...p, playing: false })); }} />
        </div>
      )}

      {/* floating chrome */}
      {showTabBar && (
        <TabBar th={th} tab={tab} compact={flow === "results" ? true : compact}
          onTab={id => { setFlow(null); setTab(id); setCompact(false); setPlayer(p => ({ ...p, playing: false })); }} />
      )}

      <TweaksPanel>
        <TweakSection label="Tema" />
        <TweakRadio label="Apariencia" value={t.theme}
          options={[{ value: "light", label: "Claro" }, { value: "dark", label: "Oscuro" }]}
          onChange={v => setTweak("theme", v)} />
        <TweakRadio label="Vidrio" value={t.glass}
          options={[{ value: "regular", label: "Regular" }, { value: "clear", label: "Transparente" }]}
          onChange={v => setTweak("glass", v)} />
        <TweakSection label="Editorial" />
        <TweakRadio label="Titulares" value={t.headlineStyle}
          options={[{ value: "serif", label: "Serif" }, { value: "sans", label: "Sans" }]}
          onChange={v => setTweak("headlineStyle", v)} />
      </TweaksPanel>
    </div>
  );
}

function LGRoot() {
  const [t, setTweak] = useTweaks(LG_TWEAK_DEFAULTS);
  const base = LG_THEMES[t.theme] || LG_THEMES.light;
  const th = t.glass === "clear"
    ? { ...base, glassBg: base.glassClear, blur: 15 }
    : base;
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh",
      padding: 24, boxSizing: "border-box" }}>
      <IOSDevice dark={t.theme === "dark"}>
        <LGApp t={t} setTweak={setTweak} th={th} />
      </IOSDevice>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<LGRoot />);
