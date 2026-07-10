// PrensaIA v2 — Historial y Diccionario (tabs).

function HistorialScreen({ th, onOpenItem, theme, setTheme }) {
  const [q, setQ] = React.useState("");
  const items = DEMO_HISTORY.filter(it => it.title.toLowerCase().includes(q.toLowerCase()));
  return (
    <div data-screen-label="Historial" style={{ display: "flex", flexDirection: "column", gap: 20, padding: "0 18px" }}>
      <h1 style={{ margin: "4px 4px 0", fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 28,
        letterSpacing: "-0.02em", color: th.text1 }}>Historial</h1>

      {/* search */}
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
            <button key={i} onClick={onOpenItem} style={{ display: "flex", alignItems: "center", gap: 12,
              width: "100%", textAlign: "left", padding: "14px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative" }}>
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
              <Icon name="chevron" size={16} color={th.text3} strokeWidth={2.2} />
            </button>
          ))}
          {!items.length && (
            <div style={{ padding: "18px 0", fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5, color: th.text3 }}>
              Sin resultados para “{q}”.
            </div>
          )}
        </Glass>
      </div>

      <div>
        <SectionLabel th={th}>Almacenamiento</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: "0 16px" }}>
          {[
            { icon: "waveform", label: "Audio guardado", trailing: "148.2 MB" },
            { icon: "trash", label: "Borrar audios guardados", danger: true },
            { icon: "download", label: "Borrar modelo de IA (~700 MB)", danger: true },
          ].map((r, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "13.5px 0",
              borderTop: i ? `1px solid ${th.divider}` : "none", position: "relative" }}>
              <Icon name={r.icon} size={19} color={r.danger ? th.redLive : th.accentText} strokeWidth={2} />
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5,
                color: r.danger ? th.redLive : th.text1 }}>{r.label}</span>
              {r.trailing && <span style={{ fontFamily: "var(--font-mono)", fontSize: 12.5, color: th.text3 }}>{r.trailing}</span>}
            </div>
          ))}
        </Glass>
      </div>

      <div>
        <SectionLabel th={th}>Apariencia</SectionLabel>
        <Segmented th={th} value={theme} onChange={setTheme}
          options={[{ value: "light", label: "Claro" }, { value: "dark", label: "Oscuro" }]} />
      </div>
    </div>
  );
}

function DiccionarioScreen({ th }) {
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
          Corrige nombres propios que la transcripción escribe mal — políticos, lugares, dependencias. Se aplica en automático.
        </p>
      </div>

      <div>
        <SectionLabel th={th}>Agregar corrección</SectionLabel>
        <Glass th={th} radius={24} style={{ padding: 16, display: "flex", flexDirection: "column", gap: 10 }}>
          <Field value={wrong} onChange={setWrong} placeholder="Como sale (ej. Bizcaino)" />
          <Field value={right} onChange={setRight} placeholder="Correcto (ej. Vizcaíno)" />
          <GlassButton th={th} tint={ok ? "wine" : undefined} icon="plus" height={48}
            onClick={add} style={{ opacity: ok ? 1 : 0.55 }}>Agregar al diccionario</GlassButton>
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
              <Icon name="close" size={14} color={th.text3} strokeWidth={2.2} />
            </div>
          ))}
        </Glass>
      </div>
    </div>
  );
}

Object.assign(window, { HistorialScreen, DiccionarioScreen });
