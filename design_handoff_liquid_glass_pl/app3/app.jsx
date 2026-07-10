// PrensaIA v3 — shell: estado global, simulaciones de todas las funciones reales, Tweaks.

const TWEAKS3 = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "glass": "regular",
  "headlineStyle": "serif"
}/*EDITMODE-END*/;

const LIVE_SCRIPT3 = "Garantizamos agua a más de cuarenta mil familias del oriente de Colima con una inversión histórica de cinco punto tres millones de pesos.";
const APP_TITLE3 = "Indira Vizcaíno entrega la rehabilitación del pozo profundo \u201cCuajiote\u201d";
const DUR3 = 148;

function useAppState(t, setTweak) {
  const [tab, setTab] = React.useState("inicio");
  const [flow, setFlow] = React.useState(null); // null | recording | live | fblive | progress | results
  const [resultsTab, setResultsTab] = React.useState("transcript");
  const [player, setPlayer] = React.useState({ playing: false, time: 9, rate: 1, until: null });
  const [diariza, setDiariza] = React.useState(true);
  const [speakers, setSpeakers] = React.useState(0);
  const [isVideo, setIsVideo] = React.useState(false);

  // motor
  const [engine, setEngineRaw] = React.useState("whisper");
  const [engineState, setEngineState] = React.useState({ whisperReady: false, fastDownloaded: false, fastDownloading: false, fastProgress: 0 });

  // progreso
  const [prog, setProg] = React.useState({ phase: "preparingModel", frac: 0 });

  // grabación / en vivo
  const [elapsed, setElapsed] = React.useState(0);
  const [live, setLive] = React.useState({ starting: false, confirmed: "", hypothesis: "", done: false });

  // Facebook Live
  const [fblive, setFblive] = React.useState({ capturing: false, sizeMB: 0, followActive: false, followText: "", chunkIdx: 0 });

  // resultados
  const [segments, setSegments] = React.useState(DEMO_SEGMENTS.map(s => ({ ...s })));
  const [names, setNames] = React.useState({ ...SPEAKER_NAMES });
  const [isEditing, setIsEditing] = React.useState(false);
  const [clean, setClean] = React.useState({ state: "idle", progress: 0, show: false });
  const [qa, setQa] = React.useState({ state: "idle", answer: "" });
  const [blocks, setBlocks] = React.useState({ state: "idle", progress: 0, list: null });
  const [manualBlocks, setManualBlocks] = React.useState([]);
  const [manual, setManual] = React.useState({ mode: false, start: null, end: null, name: "" });
  const [selection, setSelection] = React.useState(new Set());
  const [clipExport, setClipExport] = React.useState({ running: false, progress: 0 });
  const [exportMenu, setExportMenu] = React.useState(false);

  // overlays
  const [share, setShare] = React.useState(null); // {title, subtitle}
  const [rename, setRename] = React.useState(null); // {id, value}
  const [history, setHistory] = React.useState(DEMO_HISTORY);
  const [onboarding, setOnboarding] = React.useState(() => {
    try { return !localStorage.getItem("pl3_onboard_seen"); } catch (e) { return true; }
  });

  const timers = React.useRef([]);
  const addT = (fn, at) => timers.current.push(setTimeout(fn, at));
  const clearT = () => { timers.current.forEach(clearTimeout); timers.current = []; };

  // whisper se precarga al abrir
  React.useEffect(() => { const id = setTimeout(() => setEngineState(s => ({ ...s, whisperReady: true })), 1600); return () => clearTimeout(id); }, []);

  // tick del reproductor
  React.useEffect(() => {
    if (!player.playing || flow !== "results") return;
    const id = setInterval(() => setPlayer(p => {
      const nt = p.time + 0.25 * p.rate;
      if (p.until != null && nt >= p.until) return { ...p, time: p.until, playing: false, until: null };
      if (nt >= DUR3) return { ...p, time: DUR3, playing: false, until: null };
      return { ...p, time: nt };
    }), 250);
    return () => clearInterval(id);
  }, [player.playing, player.rate, flow]);

  // cronómetro de grabación
  React.useEffect(() => {
    if (flow !== "recording") return;
    setElapsed(0);
    const id = setInterval(() => setElapsed(e => e + 1), 1000);
    return () => clearInterval(id);
  }, [flow]);

  // dictado en vivo
  React.useEffect(() => {
    if (flow !== "live") return;
    setLive({ starting: true, confirmed: "", hypothesis: "", done: false });
    const words = LIVE_SCRIPT3.split(" ");
    let i = 0;
    let stream = null;
    const boot = setTimeout(() => {
      setLive(l => ({ ...l, starting: false }));
      stream = setInterval(() => {
        i++;
        if (i > words.length) { clearInterval(stream); return; }
        setLive(l => l.done ? l : {
          starting: false,
          confirmed: words.slice(0, Math.max(0, i - 2)).join(" "),
          hypothesis: words.slice(Math.max(0, i - 2), i).join(" "),
          done: false,
        });
      }, 300);
    }, 1300);
    return () => { clearTimeout(boot); if (stream) clearInterval(stream); };
  }, [flow]);

  // captura FB Live: crece el tamaño + lectura casi en vivo por tramos
  React.useEffect(() => {
    if (!fblive.capturing) return;
    const id = setInterval(() => setFblive(f => {
      const next = { ...f, sizeMB: f.sizeMB + 0.4 };
      if (f.followActive && f.chunkIdx < FOLLOW_CHUNKS.length) {
        // cada ~5 ticks llega un tramo
        if (Math.round(next.sizeMB * 10) % 20 === 0) {
          next.followText = (f.followText ? f.followText + " " : "") + FOLLOW_CHUNKS[f.chunkIdx];
          next.chunkIdx = f.chunkIdx + 1;
        }
      }
      return next;
    }), 500);
    return () => clearInterval(id);
  }, [fblive.capturing, fblive.followActive]);

  function runProgress() {
    clearT();
    setFlow("progress");
    const firstRun = !runProgress._ran; runProgress._ran = true;
    let at = 0;
    const seq = [];
    if (engine === "whisper" && firstRun) { seq.push([at, { phase: "preparingModel", frac: 0 }]); at += 1000; }
    seq.push([at, { phase: "processingAudio", frac: 0 }]); at += 900;
    [0.12, 0.34, 0.58, 0.81, 0.97].forEach(f => { seq.push([at, { phase: "transcribing", frac: f }]); at += engine === "fast" ? 320 : 640; });
    if (diariza) { seq.push([at, { phase: "diarizing", frac: 1 }]); at += 1200; }
    seq.push([at, { phase: "analyzing", frac: 1 }]); at += 1300;
    seq.forEach(([when, s]) => addT(() => setProg(s), when));
    addT(() => {
      setResultsTab("transcript");
      setPlayer({ playing: false, time: 9, rate: 1, until: null });
      setFlow("results");
    }, at);
  }

  const app = {
    // estado base
    tab, setTab, flow, setFlow, resultsTab, setResultsTab, player, setPlayer,
    diariza, setDiariza, speakers, setSpeakers,
    engine, engineState, prog, elapsed, live, fblive,
    segments, isEditing, clean, qa, blocks, manualBlocks, manual, selection,
    clipExport, exportMenu, setExportMenu, share, rename, history, onboarding,
    isVideo, setIsVideo,
    title: APP_TITLE3,

    // navegación
    backHome: () => { setFlow(null); setPlayer(p => ({ ...p, playing: false })); },
    goTab: id => { setFlow(null); setTab(id); setPlayer(p => ({ ...p, playing: false })); },
    openRecent: () => { setResultsTab("transcript"); setFlow("results"); },
    openFromHistory: () => { setResultsTab("analysis"); setFlow("results"); },

    // flujos
    startUpload: () => { setIsVideo(false); runProgress(); },
    startGallery: () => { setIsVideo(true); runProgress(); },
    startRecording: () => setFlow("recording"),
    stopRecording: () => { setIsVideo(false); runProgress(); },
    startLive: () => setFlow("live"),
    stopLive: () => setLive(l => ({ ...l, done: true, confirmed: LIVE_SCRIPT3, hypothesis: "" })),
    startFBLive: () => setFlow("fblive"),

    // motor
    setEngine: v => {
      setEngineRaw(v);
      if (v === "fast" && !engineState.fastDownloaded && !engineState.fastDownloading) app.predownloadFast();
    },
    predownloadFast: () => {
      setEngineState(s => ({ ...s, fastDownloading: true, fastProgress: 0 }));
      let p = 0;
      const id = setInterval(() => {
        p += 0.06 + Math.random() * 0.05;
        if (p >= 1) { clearInterval(id); setEngineState(s => ({ ...s, fastDownloading: false, fastDownloaded: true, fastProgress: 1 })); }
        else setEngineState(s => ({ ...s, fastProgress: p }));
      }, 240);
    },

    // FB Live
    toggleCapture: () => setFblive(f => f.capturing
      ? { ...f, capturing: false, followActive: false }
      : { ...f, capturing: true, sizeMB: f.sizeMB || 0.4 }),
    startFollowing: () => setFblive(f => ({ ...f, followActive: true })),
    stopFollowing: () => setFblive(f => ({ ...f, followActive: false })),
    clearCapture: () => setFblive({ capturing: false, sizeMB: 0, followActive: false, followText: "", chunkIdx: 0 }),
    transcribeCapture: () => { setFblive(f => ({ ...f, capturing: false, followActive: false })); setIsVideo(false); runProgress(); },

    // edición
    startEditing: () => setIsEditing(true),
    finishEditing: () => setIsEditing(false),
    editSegment: (i, text) => setSegments(segs => segs.map((s, j) => j === i ? { ...s, text } : s)),

    // oradores
    speakerName: id => names[id] || `Orador ${id + 1}`,
    openRename: id => setRename({ id, value: names[id] || "" }),
    setRenameValue: v => setRename(r => ({ ...r, value: v })),
    closeRename: () => setRename(null),
    saveRename: () => { setNames(n => ({ ...n, [rename.id]: rename.value.trim() || n[rename.id] })); setRename(null); },

    // limpieza IA
    runClean: () => {
      setClean({ state: "running", progress: 0, show: false });
      let p = 0;
      const id = setInterval(() => {
        p += 0.09 + Math.random() * 0.07;
        if (p >= 1) { clearInterval(id); setClean({ state: "done", progress: 1, show: true }); }
        else setClean(c => ({ ...c, progress: p }));
      }, 200);
    },
    setCleanShow: v => setClean(c => ({ ...c, show: v })),

    // preguntas
    askQuestion: () => {
      setQa({ state: "running", answer: "" });
      setTimeout(() => setQa({ state: "done", answer: QA_ANSWER }), 1900);
    },

    // cortes IA
    suggestBlocks: () => {
      setBlocks({ state: "running", progress: 0, list: null });
      let p = 0;
      const id = setInterval(() => {
        p += 0.08 + Math.random() * 0.06;
        if (p >= 1) {
          clearInterval(id);
          setBlocks({ state: "done", progress: 1, list: DEMO_CORTES.map((c, i) => ({ ...c, id: "ia" + i })) });
        } else setBlocks(b => ({ ...b, progress: p }));
      }, 230);
    },

    // marcado manual
    startManual: () => setManual({ mode: true, start: null, end: null, name: "" }),
    cancelManual: () => setManual({ mode: false, start: null, end: null, name: "" }),
    setManualName: v => setManual(m => ({ ...m, name: v })),
    manualTap: seg => setManual(m => {
      if (m.start == null) return { ...m, start: seg.start };
      if (m.end == null) {
        const a = Math.min(m.start, seg.start), b = Math.max(m.start + 1, seg.end);
        return { ...m, start: a, end: b };
      }
      return { ...m, start: seg.start, end: null, name: m.name };
    }),
    segInManualRange: seg => manual.mode && manual.start != null &&
      (manual.end != null ? (seg.start >= manual.start && seg.start < manual.end) : seg.start === manual.start),
    saveManualTopic: () => {
      if (manual.start == null || manual.end == null) return;
      const tema = manual.name.trim() || "Mi tema";
      setManualBlocks(b => [...b, { id: "m" + Date.now(), tema, inicio: manual.start, fin: manual.end }]);
      setManual({ mode: true, start: null, end: null, name: "" });
    },

    // selección + exportación de cortes
    toggleSelection: id => setSelection(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; }),
    selectAll: all => setSelection(s => s.size === all.length ? new Set() : new Set(all.map(b => b.id))),
    playRange: (a, b) => setPlayer(p => ({ ...p, time: a, until: b, playing: true })),
    exportClips: join => {
      setClipExport({ running: true, progress: 0 });
      let p = 0;
      const id = setInterval(() => {
        p += 0.07 + Math.random() * 0.06;
        if (p >= 1) {
          clearInterval(id);
          setClipExport({ running: false, progress: 0 });
          const n = selection.size;
          const word = isVideo ? "video" : "audio";
          setShare({ title: join ? `Cortes unidos — 1 ${word}` : `${n} corte${n === 1 ? "" : "s"} de ${word}`,
            subtitle: isVideo ? "Video H.264 · listo para publicar" : "Audio M4A · listo para publicar" });
          setSelection(new Set());
        } else setClipExport(c => ({ ...c, progress: p }));
      }, 220);
    },

    // compartir / historial / onboarding
    openShare: (title, subtitle) => setShare({ title, subtitle }),
    closeShare: () => setShare(null),
    deleteHistory: it => setHistory(h => h.filter(x => x !== it)),
    replayOnboarding: () => setOnboarding(true),
    closeOnboarding: () => { setOnboarding(false); try { localStorage.setItem("pl3_onboard_seen", "1"); } catch (e) {} },

    // apariencia
    themeChoice: t.theme,
    setTheme: v => setTweak("theme", v),
    headlineFont: t.headlineStyle === "serif" ? "var(--font-date)" : "var(--font-display)",
  };
  return app;
}

function App3({ t, setTweak, th }) {
  const app = useAppState(t, setTweak);
  const [compact, setCompact] = React.useState(false);
  const lastY = React.useRef(0);

  function onScroll(e) {
    const y = e.target.scrollTop;
    const dy = y - lastY.current;
    lastY.current = y;
    if (y > 70 && dy > 4 && !compact) setCompact(true);
    else if ((dy < -6 || y < 40) && compact) setCompact(false);
  }

  const immersive = app.flow === "recording" || app.flow === "live" || app.flow === "progress";
  const showTabBar = app.flow === null || app.flow === "results";

  return (
    <div style={{ position: "relative", height: "100%", overflow: "hidden", background: th.base }}>
      <Ambient th={th} />

      {app.flow === null && (
        <div key={app.tab} className="lg-scroll lg-pop" onScroll={onScroll}
          style={{ position: "absolute", inset: 0, overflowY: "auto", padding: "64px 0 130px" }}>
          {app.tab === "inicio" && (
            <HomeScreen3 th={th} engine={app.engine} engineState={app.engineState}
              onUpload={app.startUpload} onRecord={app.startRecording} onLive={app.startLive}
              onGallery={app.startGallery} onFBLive={app.startFBLive}
              diariza={app.diariza} setDiariza={app.setDiariza}
              speakers={app.speakers} setSpeakers={app.setSpeakers}
              onOpenRecent={app.openRecent} />
          )}
          {app.tab === "historial" && <HistorialScreen3 th={th} app={app} />}
          {app.tab === "diccionario" && <DiccionarioScreen3 th={th} />}
        </div>
      )}

      {immersive && (
        <div className="lg-push" style={{ position: "absolute", inset: 0, zIndex: 80, paddingTop: 64 }}>
          {app.flow === "recording" && (
            <RecordingScreen3 th={th} elapsed={app.elapsed} onStop={app.stopRecording} onCancel={app.backHome} />
          )}
          {app.flow === "live" && (
            <LiveMicScreen3 th={th} starting={app.live.starting} confirmed={app.live.confirmed}
              hypothesis={app.live.hypothesis} done={app.live.done}
              onStop={app.stopLive} onAnalyze={app.startUpload} onDone={app.backHome} />
          )}
          {app.flow === "progress" && (
            <ProgressScreen3 th={th} phase={app.prog.phase} frac={app.prog.frac} diariza={app.diariza} />
          )}
        </div>
      )}

      {app.flow === "fblive" && (
        <div className="lg-push" style={{ position: "absolute", inset: 0, zIndex: 80 }}>
          <FBLiveScreen3 th={th} app={app} />
        </div>
      )}

      {app.flow === "results" && (
        <div className="lg-push" style={{ position: "absolute", inset: 0, zIndex: 60 }}>
          <ResultsScreen3 th={th} app={app} />
        </div>
      )}

      {showTabBar && (
        <TabBar th={th} tab={app.tab} compact={app.flow === "results" ? true : compact} onTab={app.goTab} />
      )}

      {/* overlays */}
      <ShareSheet th={th} open={!!app.share} onClose={app.closeShare}
        title={app.share ? app.share.title : ""} items={app.share ? app.share.subtitle : ""} />
      <Dialog th={th} open={!!app.rename} title="Nombre del orador"
        message="Se aplicará en toda la transcripción."
        value={app.rename ? app.rename.value : ""} onChange={app.setRenameValue}
        placeholder="Ej. Indira Vizcaíno"
        actions={[
          { label: "Cancelar", onClick: app.closeRename },
          { label: "Guardar", bold: true, onClick: app.saveRename },
        ]} />
      {app.onboarding && <Onboarding3 th={th} onClose={app.closeOnboarding} />}

      <TweaksPanel>
        <TweakSection label="Tema" />
        <TweakRadio label="Apariencia" value={t.theme}
          options={[{ value: "system", label: "Sistema" }, { value: "light", label: "Claro" }, { value: "dark", label: "Oscuro" }]}
          onChange={v => setTweak("theme", v)} />
        <TweakRadio label="Vidrio" value={t.glass}
          options={[{ value: "regular", label: "Regular" }, { value: "clear", label: "Transparente" }]}
          onChange={v => setTweak("glass", v)} />
        <TweakSection label="Editorial" />
        <TweakRadio label="Titulares" value={t.headlineStyle}
          options={[{ value: "serif", label: "Serif" }, { value: "sans", label: "Sans" }]}
          onChange={v => setTweak("headlineStyle", v)} />
        <TweakSection label="Demo" />
        <TweakRadio label="Fuente (resultados)" value={app.isVideo ? "video" : "audio"}
          options={[{ value: "audio", label: "Audio" }, { value: "video", label: "Video" }]}
          onChange={v => app.setIsVideo(v === "video")} />
      </TweaksPanel>
    </div>
  );
}

function Root3() {
  const [t, setTweak] = useTweaks(TWEAKS3);
  const sysDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  const mode = t.theme === "system" ? (sysDark ? "dark" : "light") : t.theme;
  const base = LG_THEMES[mode] || LG_THEMES.light;
  const th = t.glass === "clear" ? { ...base, glassBg: base.glassClear } : base;
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh",
      padding: 24, boxSizing: "border-box" }}>
      <IOSDevice dark={mode === "dark"}>
        <App3 t={t} setTweak={setTweak} th={th} />
      </IOSDevice>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<Root3 />);
