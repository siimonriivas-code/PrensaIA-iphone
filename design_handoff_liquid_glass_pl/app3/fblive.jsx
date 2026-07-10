// PrensaIA v3 — flujo Facebook Live: captura por broadcast + lectura casi en vivo.

function FBLiveScreen3({ th, app }) {
  const fb = app.fblive;
  const ok = th.statusDark ? "#7FBFA5" : "#3A6B5A";
  const followRef = React.useRef(null);
  React.useEffect(() => {
    if (followRef.current) followRef.current.scrollTop = followRef.current.scrollHeight;
  }, [fb.followText]);

  return (
    <div data-screen-label="Facebook Live" style={{ position: "absolute", inset: 0 }}>
      {/* nav */}
      <div style={{ position: "absolute", top: 54, left: 16, right: 16, zIndex: 60,
        display: "flex", justifyContent: "space-between", alignItems: "center", pointerEvents: "none" }}>
        <div style={{ pointerEvents: "auto" }}><CircleButton th={th} icon="chevronLeft" onClick={app.backHome} /></div>
        <Glass th={th} clear radius={999} style={{ padding: "8px 16px", pointerEvents: "none" }}>
          <span style={{ position: "relative", fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 13.5, color: th.text1 }}>
            Facebook Live
          </span>
        </Glass>
        <div style={{ width: 44 }} />
      </div>

      <div className="lg-scroll" style={{ position: "absolute", inset: 0, overflowY: "auto", padding: "110px 18px 130px",
        display: "flex", flexDirection: "column", gap: 14 }}>

        {/* estado de captura */}
        <Glass th={th} radius={22} style={{ padding: "15px 17px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, position: "relative" }}>
            {fb.capturing ? (
              <>
                <span className="pl-pulse" style={{ width: 11, height: 11, borderRadius: 999, background: th.redLive }} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 15.5, color: th.text1 }}>Capturando…</span>
                <span style={{ flex: 1 }} />
                <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 14, color: th.accentText }}>{fb.sizeMB.toFixed(1)} MB</span>
              </>
            ) : fb.sizeMB > 0 ? (
              <>
                <Icon name="checkFill" size={20} color={ok} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 15.5, color: th.text1 }}>Captura lista</span>
                <span style={{ flex: 1 }} />
                <span style={{ fontFamily: "var(--font-mono)", fontWeight: 700, fontSize: 14, color: th.accentText }}>{fb.sizeMB.toFixed(1)} MB</span>
              </>
            ) : (
              <>
                <Icon name="waveform" size={20} color={th.text3} strokeWidth={2} />
                <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 15.5, color: th.text3 }}>Sin captura todavía</span>
              </>
            )}
          </div>
        </Glass>

        {/* cómo funciona */}
        <Glass th={th} radius={22} style={{ padding: "16px 17px", display: "flex", flexDirection: "column", gap: 10 }}>
          <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 15, color: th.text1, position: "relative" }}>Cómo funciona</span>
          {[
            "Conecta tus AirPods/audífonos (o baja el volumen). Así nadie en tu oficina escucha.",
            "Toca el botón de captura de abajo y elige \u201cPrensaLiveCapture\u201d → Iniciar transmisión.",
            "Abre Facebook y reproduce el live. La app va guardando el audio en segundo plano.",
            "Cuando quieras (a media transmisión o al final), vuelve aquí y toca \u201cTranscribir lo capturado\u201d.",
          ].map((t, i) => (
            <div key={i} style={{ display: "flex", gap: 9, position: "relative" }}>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 13, color: th.accentText, flexShrink: 0 }}>{i + 1}.</span>
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 13, lineHeight: 1.45, color: th.text3 }}>{t}</span>
            </div>
          ))}
        </Glass>

        {/* botón de broadcast */}
        <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "2px 4px" }}>
          <Glass th={th} as="button" tint={fb.capturing ? "red" : "wine"} press radius={18}
            onClick={app.toggleCapture}
            style={{ width: 56, height: 56, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            <Icon name="radio" size={26} color={th.onAccent} strokeWidth={2} style={{ position: "relative" }} />
          </Glass>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 14, color: th.text1 }}>Iniciar / detener captura</div>
            <div style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 12, lineHeight: 1.4, color: th.text3, marginTop: 1 }}>
              Toca el ícono. La barra roja de arriba indica que está capturando.
            </div>
          </div>
        </div>

        {/* lectura casi en vivo */}
        {(fb.capturing || fb.followActive || fb.followText) && (
          <Glass th={th} radius={22} style={{ padding: "16px 17px", display: "flex", flexDirection: "column", gap: 11 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, position: "relative" }}>
              <Icon name="viewfinder" size={16} color={th.accentText} strokeWidth={2} />
              <span style={{ flex: 1, fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 14, color: th.accentText }}>Leer casi en vivo</span>
              {fb.followActive ? (
                <button onClick={app.stopFollowing} style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: th.text3 }}>Pausar</button>
              ) : fb.capturing ? (
                <button onClick={app.startFollowing} style={{ display: "flex", alignItems: "center", gap: 5 }}>
                  <Icon name="play" size={13} color={th.accentText} />
                  <span style={{ fontFamily: "var(--font-display)", fontWeight: 800, fontSize: 12.5, color: th.accentText }}>Activar</span>
                </button>
              ) : null}
            </div>

            {fb.followText && (
              <div ref={followRef} className="lg-scroll" style={{ maxHeight: 210, overflowY: "auto", position: "relative" }}>
                <p style={{ margin: 0, fontFamily: "var(--font-date)", fontStyle: "italic", fontSize: 16.5,
                  lineHeight: 1.58, color: th.text1 }}>{fb.followText}</p>
              </div>
            )}
            {fb.followActive && (
              <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11.5, color: th.text3, position: "relative" }}>
                {fb.followText ? "Escuchando… el texto aparece en tramos de ~20 segundos." : "Preparando el modelo…"}
              </span>
            )}
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, lineHeight: 1.4, color: th.text3, position: "relative" }}>
              Es una lectura rápida por tramos. Al final, “Transcribir lo capturado” te da la versión completa y precisa.
            </span>
          </Glass>
        )}

        <GlassCTA th={th} icon="check" height={54} disabled={fb.sizeMB === 0}
          onClick={app.transcribeCapture}>Transcribir lo capturado</GlassCTA>

        {fb.sizeMB > 0 && !fb.capturing && (
          <button onClick={app.clearCapture} style={{ display: "flex", alignItems: "center", gap: 7, justifyContent: "center", padding: 6 }}>
            <Icon name="trash" size={15} color={th.redLive} strokeWidth={2} />
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 13.5, color: th.redLive }}>
              Borrar captura y empezar de cero
            </span>
          </button>
        )}

        <span style={{ fontFamily: "var(--font-display)", fontWeight: 500, fontSize: 11, lineHeight: 1.45, color: th.text3, padding: "0 8px" }}>
          Nota: algunos videos protegidos (con copia bloqueada) no se pueden capturar. Si la transcripción sale en silencio, prueba reproducir el live desde Safari (facebook.com) en vez de la app de Facebook.
        </span>
      </div>
    </div>
  );
}

Object.assign(window, { FBLiveScreen3 });
