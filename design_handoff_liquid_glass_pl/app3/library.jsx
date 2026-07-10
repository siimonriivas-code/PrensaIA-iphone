// PrensaIA v3 — Historial (motor, almacenamiento, apariencia) y Diccionario. Onboarding.

function HistorialScreen3({ th, app }) {
  const [q, setQ] = React.useState("");
  const [editing, setEditing] = React.useState(false);
  const items = app.history.filter(it => it.title.toLowerCase().includes(q.toLowerCase()));

  return (
    <div data-screen-label="Historial" style={{ display: "flex", flexDirection: "column", gap: 20, padding: "0 18px" }}>
      <div style={{ display: "flex", alignItems: "baseline" }}>
        <h1 style={{ margin: "4px 4px 0", flex: 1, fontFamily: "var(--font-display)", fontWeight: 900,
          fontSize: 28, letterSpacing: "-0.02em", color: th.text1 }}>Historial</h1>
        {app.history.length > 0 && (
          <button onClick={() => setEditing(!editing)} style={{ fontFamily: "var(--font-display)", fontWeight: 700,
            fontSize: 14.5, color: th.accentText, padding: "0 4px" }}>{editing ? "Listo" : "Editar"}</button>
        )}
      </div>

      <Glass th={th} clear radius={999} style={{ display: "flex", alignItems: "center", gap: 9, padding: "0 16px" }}>
        <Icon name="search" size={17} color={th.text3} style={{ position: "relative" }} />
        <input value={q} onChange={e => setQ(e.target.value)} placeholder="Buscar en transcripciones" style={{
          flex: 1, border: "none", outline: "none", background: "transparent", padding: "12.5px 0",
          fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, color: th.text1, position: "relative" }} />
      </Glass>

      <div>
        <SectionLabel th={th}>Transcripciones</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: "0 16px" }}>
          {items.map((it, i) => (
            <div key={it.title} style={{ display: "flex", alignItems: "center", gap: 10,
              borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative" }}>
              {editing && (
                <button onClick={() => app.deleteHistory(it)} style={{ flexShrink: 0 }}>
                  <Icon name="minusFill" size={22} color={th.redLive} />
                </button>
              )}
              <button onClick={() => !editing && app.openFromHistory()} style={{ flex: 1, minWidth: 0, display: "flex",
                alignItems: "center", gap: 12, textAlign: "left", padding: "14px 0" }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, lineHeight: 1.3, color: th.text1 }}>{it.title}</div>
                  <div style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 4 }}>
                    <span style={{ fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 12.5, color: th.text3 }}>{it.date}</span>
                    {it.analysis && (
                      <span style={{ display: "flex", alignItems: "center", gap: 4, whiteSpace: "nowrap" }}>
                        <Icon name="sparkles" size={12} color={th.gold} strokeWidth={2} />
                        <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 11, color: th.gold }}>Con análisis</span>
                      </span>
                    )}
                  </div>
                </div>
                {!editing && <Icon name="chevron" size={16} color={th.text3} strokeWidth={2.2} />}
              </button>
            </div>
          ))}
          {!app.history.length && (
            <div style={{ padding: "16px 0", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13, lineHeight: 1.45, color: th.text3 }}>
              Aún no tienes transcripciones guardadas. Cada transcripción que termines se guardará aquí.
            </div>
          )}
          {app.history.length > 0 && !items.length && (
            <div style={{ padding: "16px 0", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5, color: th.text3 }}>
              Sin resultados para “{q}”.
            </div>
          )}
        </Glass>
      </div>

      <div>
        <SectionLabel th={th}>Almacenamiento</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: "0 16px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "13.5px 0", position: "relative" }}>
            <Icon name="film" size={19} color={th.accentText} strokeWidth={2} />
            <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5, color: th.text1 }}>Audio y video guardados</span>
            <span style={{ fontFamily: "var(--font-mono)", fontSize: 12.5, color: th.text3 }}>412.6 MB</span>
          </div>
          {[
            { icon: "trash", label: "Borrar archivos guardados" },
            { icon: "download", label: "Borrar modelo de IA (~700 MB)" },
          ].map((r, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "13.5px 0",
              borderTop: `1px solid ${th.divider}`, position: "relative" }}>
              <Icon name={r.icon} size={19} color={th.redLive} strokeWidth={2} />
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5, color: th.redLive }}>{r.label}</span>
            </div>
          ))}
          <div style={{ padding: "10px 0 14px", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11,
            lineHeight: 1.45, color: th.text3, borderTop: `1px solid ${th.divider}`, position: "relative" }}>
            Borrar los archivos libera espacio (los textos se conservan, pero ya no podrás reproducir ni cortar las grabaciones viejas).
          </div>
        </Glass>
      </div>

      {/* Motor de transcripción */}
      <div>
        <SectionLabel th={th}>Motor de transcripción</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
          <Segmented th={th} value={app.engine} onChange={app.setEngine}
            options={[{ value: "whisper", label: "Preciso" }, { value: "fast", label: "Rápido" }]} />
          <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5,
            lineHeight: 1.45, color: th.text3, position: "relative" }}>
            {app.engine === "fast"
              ? "Rápido (Parakeet): transcribe en segundos usando el chip de IA del iPhone. Ojo: la transcripción en vivo y \u201cleer casi en vivo\u201d siguen usando el motor Preciso."
              : "Preciso (Whisper): el motor de siempre, máxima calidad de texto. Viene dentro de la app, listo sin descargas. Si un video largo te urge, prueba el Rápido y compara."}
          </p>
          <div style={{ position: "relative" }}>
            {app.engineState.fastDownloading ? (
              <div style={{ display: "flex", flexDirection: "column", gap: 7 }}>
                <ThinProgress th={th} value={app.engineState.fastProgress} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3 }}>
                  Descargando… {Math.round(app.engineState.fastProgress * 100)}%
                </span>
              </div>
            ) : app.engineState.fastDownloaded ? (
              <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                <Icon name="seal" size={16} color={th.statusDark ? "#7FBFA5" : "#3A6B5A"} strokeWidth={2} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 12,
                  color: th.statusDark ? "#7FBFA5" : "#3A6B5A" }}>Motor Rápido descargado y listo (funciona sin internet)</span>
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: 7 }}>
                <button onClick={app.predownloadFast} style={{ display: "flex", alignItems: "center", gap: 7, alignSelf: "flex-start" }}>
                  <Icon name="download" size={16} color={th.accentText} strokeWidth={2.2} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 13, color: th.accentText }}>
                    Descargar motor Rápido ahora (~600 MB)
                  </span>
                </button>
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, color: th.text3 }}>
                  Descárgalo con calma en WiFi para tenerlo listo cuando lo necesites.
                </span>
              </div>
            )}
          </div>
        </Glass>
      </div>

      <div>
        <SectionLabel th={th}>Apariencia</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
          <Segmented th={th} value={app.themeChoice} onChange={app.setTheme}
            options={[{ value: "system", label: "Sistema" }, { value: "light", label: "Claro" }, { value: "dark", label: "Oscuro" }]} />
          <button onClick={app.replayOnboarding} style={{ display: "flex", alignItems: "center", gap: 7, alignSelf: "flex-start", position: "relative" }}>
            <Icon name="sparkles" size={14} color={th.accentText} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 12.5, color: th.accentText }}>Ver la bienvenida de nuevo</span>
          </button>
        </Glass>
      </div>
    </div>
  );
}

function DiccionarioScreen3({ th }) {
  const [items, setItems] = React.useState(DEMO_DICCIONARIO);
  const [wrong, setWrong] = React.useState("");
  const [right, setRight] = React.useState("");
  const ok = wrong.trim() && right.trim();
  const add = () => {
    if (!ok) return;
    setItems([{ wrong: wrong.trim(), right: right.trim() }, ...items]);
    setWrong(""); setRight("");
  };
  const Field = ({ value, onChange, placeholder }) => (
    <Glass th={th} clear radius={16} style={{ padding: "1px 2px" }}>
      <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} style={{
        width: "100%", border: "none", outline: "none", background: "transparent", padding: "12px 14px",
        fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, color: th.text1, position: "relative" }} />
    </Glass>
  );
  return (
    <div data-screen-label="Diccionario" style={{ display: "flex", flexDirection: "column", gap: 20, padding: "0 18px" }}>
      <div style={{ padding: "4px 4px 0" }}>
        <h1 style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 28,
          letterSpacing: "-0.02em", color: th.text1 }}>Diccionario</h1>
        <p style={{ margin: "8px 0 0", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5,
          lineHeight: 1.45, color: th.text3 }}>
          Whisper a veces escribe mal nombres propios (políticos, lugares, dependencias). Dile cómo lo escribe mal y cómo debe quedar; se corrige solo en cada transcripción.
        </p>
      </div>
      <div>
        <SectionLabel th={th}>Agregar corrección</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: 16, display: "flex", flexDirection: "column", gap: 10 }}>
          <Field value={wrong} onChange={setWrong} placeholder="Como sale (ej. Bizcaino)" />
          <Field value={right} onChange={setRight} placeholder="Correcto (ej. Vizcaíno)" />
          <GlassCTA th={th} icon="plus" disabled={!ok} onClick={add}>Agregar al diccionario</GlassCTA>
        </Glass>
      </div>
      <div>
        <SectionLabel th={th}>Mis correcciones ({items.length})</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: "0 16px" }}>
          {items.map((it, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "13.5px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative" }}>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, color: th.text3,
                textDecoration: "line-through" }}>{it.wrong}</span>
              <Icon name="arrowRight" size={14} color={th.gold} strokeWidth={2.2} />
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, color: th.text1 }}>{it.right}</span>
              <button onClick={() => setItems(items.filter((_, j) => j !== i))}>
                <Icon name="close" size={14} color={th.text3} strokeWidth={2.2} />
              </button>
            </div>
          ))}
          {!items.length && (
            <div style={{ padding: "16px 0", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13, color: th.text3 }}>
              Aún no tienes correcciones. Agrega los nombres que más usas en tu cobertura.
            </div>
          )}
        </Glass>
      </div>
    </div>
  );
}

// ── Onboarding (solo la primera vez) ────────────────────────────────────
function Onboarding3({ th, onClose }) {
  const [page, setPage] = React.useState(0);
  const f = ONBOARDING_PAGES[page];
  const last = page === ONBOARDING_PAGES.length - 1;
  return (
    <div data-screen-label="Bienvenida" style={{ position: "absolute", inset: 0, zIndex: 140, background: th.base }}>
      <Ambient th={th} />
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", padding: "58px 26px 30px" }}>
        <button onClick={onClose} style={{ alignSelf: "flex-end", fontFamily: "var(--font-display)",
          fontWeight: 600, fontSize: 14, color: th.text3, padding: 6 }}>Saltar</button>

        <div key={page} className="lg-pop" style={{ flex: 1, display: "flex", flexDirection: "column",
          alignItems: "center", justifyContent: "center", gap: 28, textAlign: "center" }}>
          <Glass th={th} tint="wine" radius={999} style={{ width: 104, height: 104, display: "flex",
            alignItems: "center", justifyContent: "center" }}>
            <Icon name={f.icon} size={46} color={th.onAccent} strokeWidth={1.8} style={{ position: "relative" }} />
          </Glass>
          <div style={{ display: "flex", flexDirection: "column", gap: 12, alignItems: "center" }}>
            <h2 style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontWeight: 800,
              fontSize: 27, letterSpacing: "-0.01em", color: th.text1 }}>{f.title}</h2>
            <p style={{ margin: 0, fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5,
              lineHeight: 1.55, color: th.text3, maxWidth: 300 }}>{f.text}</p>
          </div>
        </div>

        <div style={{ display: "flex", justifyContent: "center", gap: 7, padding: "18px 0 22px" }}>
          {ONBOARDING_PAGES.map((_, i) => (
            <button key={i} onClick={() => setPage(i)} style={{ width: 8, height: 8, borderRadius: 999,
              background: i === page ? (th.statusDark ? th.accentText : th.accent) : th.divider,
              transition: "background 0.25s" }} />
          ))}
        </div>

        <GlassButton th={th} tint="wine" height={56} onClick={() => last ? onClose() : setPage(page + 1)}>
          {last ? "Comenzar" : "Siguiente"}
        </GlassButton>
      </div>
    </div>
  );
}

Object.assign(window, { HistorialScreen3, DiccionarioScreen3, Onboarding3 });
