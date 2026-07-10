// PrensaIA — modal sheets: History and Dictionary.

function Sheet({ th, title, onClose, children, leading }) {
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 100, display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
      <div onClick={onClose} style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.35)" }} className="pl-fade" />
      <div className="pl-sheet" style={{ position: "relative", background: th.page, borderTopLeftRadius: 28, borderTopRightRadius: 28, willChange: "transform",
        height: "92%", display: "flex", flexDirection: "column", overflow: "hidden", boxShadow: "0 -10px 40px rgba(0,0,0,0.3)" }}>
        {/* grabber */}
        <div style={{ display: "flex", justifyContent: "center", paddingTop: 8 }}>
          <div style={{ width: 38, height: 5, borderRadius: 999, background: th.divider }} />
        </div>
        {/* sheet nav */}
        <div style={{ display: "flex", alignItems: "center", padding: "10px 18px 12px" }}>
          <div style={{ width: 64, display: "flex" }}>{leading}</div>
          <div style={{ flex: 1, textAlign: "center", fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 17, color: th.text1 }}>{title}</div>
          <button onClick={onClose} style={{ width: 64, textAlign: "right", border: "none", background: "transparent", cursor: "pointer",
            fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15, color: th.accentText }}>Cerrar</button>
        </div>
        <div style={{ flex: 1, overflow: "auto", padding: "4px 16px 28px" }}>{children}</div>
      </div>
    </div>
  );
}

function HistorySheet({ th, onClose, onOpenItem, theme, setTheme }) {
  const [q, setQ] = React.useState("");
  const items = DEMO_HISTORY.filter(it => it.title.toLowerCase().includes(q.toLowerCase()));
  return (
    <Sheet th={th} title="Historial" onClose={onClose}
      leading={<span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 15, color: th.accentText, cursor: "pointer" }}>Editar</span>}>
      {/* search */}
      <div style={{ display: "flex", alignItems: "center", gap: 8, background: th.card, borderRadius: 12, padding: "10px 12px", marginBottom: 16, boxShadow: th.shadow }}>
        <Icon name="search" size={17} color={th.text3} />
        <input value={q} onChange={e => setQ(e.target.value)} placeholder="Buscar en transcripciones" style={{
          flex: 1, border: "none", outline: "none", background: "transparent",
          fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 15, color: th.text1 }} />
      </div>

      <SectionLabel th={th}>Transcripciones</SectionLabel>
      <div style={{ background: th.card, borderRadius: 18, overflow: "hidden", boxShadow: th.shadow, marginBottom: 22 }}>
        {items.map((it, i) => (
          <button key={i} onClick={onOpenItem} style={{ width: "100%", textAlign: "left", border: "none", cursor: "pointer", background: "transparent",
            padding: "13px 16px", display: "flex", flexDirection: "column", gap: 4,
            borderTop: i ? `0.5px solid ${th.divider}` : "none" }}>
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, lineHeight: 1.3, color: th.text1 }}>{it.title}</span>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, color: th.text3 }}>{it.date}</span>
              {it.analysis && (
                <span style={{ display: "flex", alignItems: "center", gap: 4, whiteSpace: "nowrap" }}>
                  <Icon name="sparkles" size={12} color={th.gold} strokeWidth={2} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 11.5, color: th.gold, whiteSpace: "nowrap" }}>Con análisis</span>
                </span>
              )}
            </div>
          </button>
        ))}
      </div>

      <SectionLabel th={th}>Almacenamiento</SectionLabel>
      <div style={{ background: th.card, borderRadius: 18, overflow: "hidden", boxShadow: th.shadow, marginBottom: 22 }}>
        <Row th={th} icon="waveform" label="Audio guardado" trailing={<span style={{ color: th.text3, fontFamily: "var(--font-display)", fontSize: 14 }}>148.2 MB</span>} />
        <Row th={th} icon="trash" label="Borrar audios guardados" danger />
        <Row th={th} icon="download" label="Borrar modelo de IA (~700 MB)" danger last />
      </div>

      <SectionLabel th={th}>Apariencia</SectionLabel>
      <div style={{ background: th.card, borderRadius: 18, padding: 14, boxShadow: th.shadow }}>
        <div style={{ display: "flex", gap: 4, padding: 4, background: th.cardSunk, borderRadius: 12 }}>
          {[["light", "Claro"], ["dark", "Oscuro"]].map(([v, l]) => (
            <button key={v} onClick={() => setTheme(v)} style={{ flex: 1, border: "none", cursor: "pointer", padding: "8px 0", borderRadius: 9,
              background: theme === v ? th.card : "transparent", boxShadow: theme === v ? "0 1px 3px rgba(0,0,0,0.12)" : "none",
              fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14, color: theme === v ? th.text1 : th.text3 }}>{l}</button>
          ))}
        </div>
      </div>
    </Sheet>
  );
}

function DictionarySheet({ th, onClose }) {
  const [items, setItems] = React.useState(DEMO_DICCIONARIO);
  const [wrong, setWrong] = React.useState("");
  const [right, setRight] = React.useState("");
  const add = () => {
    if (!wrong.trim() || !right.trim()) return;
    setItems([...items, { wrong: wrong.trim(), right: right.trim() }]);
    setWrong(""); setRight("");
  };
  return (
    <Sheet th={th} title="Diccionario" onClose={onClose}>
      <p style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13.5, lineHeight: 1.45, color: th.text3, margin: "0 4px 18px" }}>
        Whisper a veces escribe mal nombres propios (políticos, lugares, dependencias). Dile cómo lo escribe mal y cómo debe quedar; se corrige solo en cada transcripción.
      </p>

      <SectionLabel th={th}>Agregar corrección</SectionLabel>
      <div style={{ background: th.card, borderRadius: 18, padding: 14, boxShadow: th.shadow, marginBottom: 22, display: "flex", flexDirection: "column", gap: 10 }}>
        <Field th={th} value={wrong} onChange={setWrong} placeholder="Como sale (ej. Bizcaino)" />
        <Field th={th} value={right} onChange={setRight} placeholder="Correcto (ej. Vizcaíno)" />
        <button onClick={add} disabled={!wrong.trim() || !right.trim()} style={{
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8, border: "none",
          cursor: wrong.trim() && right.trim() ? "pointer" : "default", padding: "12px", borderRadius: 14,
          background: wrong.trim() && right.trim() ? primaryFill(th) : th.accentSoft,
          color: wrong.trim() && right.trim() ? th.onAccent : th.text3,
          fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15 }}>
          <Icon name="plus" size={18} color={wrong.trim() && right.trim() ? th.onAccent : th.text3} strokeWidth={2.2} />
          Agregar al diccionario
        </button>
      </div>

      <SectionLabel th={th}>Mis correcciones ({items.length})</SectionLabel>
      <div style={{ background: th.card, borderRadius: 18, overflow: "hidden", boxShadow: th.shadow }}>
        {items.map((it, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "13px 16px",
            borderTop: i ? `0.5px solid ${th.divider}` : "none" }}>
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 14.5, color: th.text3, textDecoration: "line-through" }}>{it.wrong}</span>
            <Icon name="arrowRight" size={14} color={th.text3} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14.5, color: th.text1 }}>{it.right}</span>
          </div>
        ))}
      </div>
    </Sheet>
  );
}

function Field({ th, value, onChange, placeholder }) {
  return (
    <input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} style={{
      border: "none", outline: "none", background: th.cardSunk, borderRadius: 12, padding: "12px 13px",
      fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 15, color: th.text1 }} />
  );
}

function Row({ th, icon, label, trailing, danger, last }) {
  const c = danger ? th.redLive : th.text1;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "13px 16px",
      borderTop: last === undefined ? "none" : "none", borderBottom: !last ? `0.5px solid ${th.divider}` : "none" }}>
      <Icon name={icon} size={19} color={danger ? th.redLive : th.accentText} strokeWidth={2} />
      <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 14.5, color: c }}>{label}</span>
      {trailing}
    </div>
  );
}

function SectionLabel({ th, children }) {
  return (
    <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 11.5, letterSpacing: "0.08em",
      textTransform: "uppercase", color: th.text3, padding: "0 6px 8px" }}>{children}</div>
  );
}

Object.assign(window, { HistorySheet, DictionarySheet });
