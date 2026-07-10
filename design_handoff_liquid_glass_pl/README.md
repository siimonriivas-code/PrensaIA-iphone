# Handoff: Rediseño PrensaIA — Identidad PL + Liquid Glass (iOS 26)

## Overview
Rediseño completo de **PrensaIA** (app iOS de transcripción y análisis periodístico, 100% on-device) con:
1. La identidad de marca **PL** (vino/granate, cápsulas doradas, monograma sun-burst, serif editorial para citas/fechas).
2. El lenguaje **Liquid Glass de iOS 26** usando las APIs nativas de SwiftUI.
3. Una **reestructura de navegación**: de "una sola pantalla con hojas modales" a **TabView de 3 pestañas** (Inicio / Historial / Diccionario) + pantalla de Resultados a pantalla completa.

El repo objetivo es `siimonriivas-code/PrensaIA-iphone` (SwiftUI, iOS 26). Este documento mapea cada pantalla del diseño a los archivos Swift existentes.

## About the Design Files
Los archivos de este paquete son **referencias de diseño creadas en HTML** (prototipos interactivos). **No son código para copiar** — la tarea es **recrear este diseño en SwiftUI** usando los patrones que el proyecto ya tiene (extensiones de `ContentView`, `DesignSystem.swift`, `.glassEffect`, etc.).

⚠️ **Importante sobre el vidrio:** el HTML *simula* el material Liquid Glass con gradientes (limitación del navegador). En SwiftUI **NO simules nada**: usa las APIs nativas (`.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)` / `.glassProminent`), que ya se usan en el código actual. Este diseño define *dónde* va el vidrio, *qué tinte* lleva y *qué jerarquía* tiene.

Para ver los prototipos: abre `PrensaIA App Completa.html` en un navegador (necesita los folders `app/`, `app2/`, `app3/`, `assets/` y los `.jsx` junto a él). Es la referencia definitiva. `PrensaIA.html` (v1) y `PrensaIA Liquid Glass.html` (v2) son iteraciones anteriores, incluidas solo como contexto.

## Fidelity
**High-fidelity.** Colores, tipografía, espaciados, radios, copys y estados son finales. Recrear con precisión, adaptando a componentes nativos donde exista equivalente directo (mejor un control nativo bien tintado que una imitación).

---

## Design Tokens

### Color — definir en Assets.xcassets como colores adaptativos (Any / Dark)

| Nombre sugerido | Claro | Oscuro | Uso |
|---|---|---|---|
| `BaseBackground` | `#F2EBE4` | `#150409` | Fondo de toda la app |
| `BrandPrimary` | `#611029` | `#B02A5B` | Tinte de botones prominentes, thumb del segmentado, toggle ON |
| `BrandText` | `#611029` | `#E79BB7` | Íconos/links/acentos sobre fondo |
| `TextPrimary` | `#20090F` | `#F8F4F1` | Titulares y texto principal |
| `TextSecondary` | `#4A3038` | `rgba(248,244,241,0.78)` | Texto de párrafos |
| `TextTertiary` | `#84666E` | `rgba(248,244,241,0.52)` | Captions, hints, placeholders |
| `AccentGoldFill` | `#CBA04A` | `#CBA04A` | **Cápsulas** (IA LOCAL, EN VIVO usa vino), badge IA, bullets, reglas |
| `OnGold` | `#4F0A21` | `#2A0610` | Texto dentro de cápsulas doradas |
| `GoldText` | `#8E6D25` | `#D9B565` | Eyebrows/labels dorados sobre fondo |
| `BrandSoft` | `rgba(97,16,41,0.09)` | `rgba(226,123,161,0.14)` | Fondos suaves (fila activa, track de anillos) |
| `Divider` | `rgba(32,9,15,0.08)` | `rgba(255,255,255,0.10)` | Separadores hairline |
| `LiveRed` | `#C4376E` | `#E2638F` | Punto REC, acciones destructivas, botón Detener (tinte) |
| `SuccessGreen` | `#3A6B5A` | `#7FBFA5` | Checks de éxito |

Reemplaza el `Color.brand` índigo actual de `DesignSystem.swift` por `BrandPrimary`/`BrandText` adaptativos. **Todo lo que hoy usa `.brand` debe migrar.**

### Fondo ambiental (firma visual)
El fondo NO es plano: `BaseBackground` + 3 radiales muy suaves detrás de todo el contenido (los blobs le dan vida al vidrio):
- Claro: oro `rgba(203,160,74,0.34)` arriba-izquierda (42%×30% en 12%,4%); magenta `rgba(176,42,91,0.20)` arriba-derecha; vino `rgba(97,16,41,0.28)` abajo-centro (72%×46% en 50%,110%).
- Oscuro: magenta `rgba(176,42,91,0.42)` arriba-izquierda; oro `rgba(203,160,74,0.15)` arriba-derecha; vino `rgba(120,22,52,0.58)` abajo.

En SwiftUI: `ZStack` con `RadialGradient`s fijos (ignoresSafeArea) detrás del `TabView`. Sin animación.

### Colores de orador (rotación por `speakerId % 7`)
- Claro: `#611029, #8E6D25, #B02A5B, #3A6B5A, #3D5A80, #8A5A2B, #6B4B7A`
- Oscuro: `#E79BB7, #D9B565, #E2638F, #7FBFA5, #8FB4DC, #D2A06B, #B99BC8`

### Tipografía
El diseño usa sustitutos de marca PL: **Montserrat** (display) y **Playfair Display Italic** (serif editorial). Dos opciones:
1. **Recomendada:** empaquetar ambas (Google Fonts, licencia libre) vía `Info.plist`. Display: Montserrat 500/600/700/800/900. Serif: Playfair Display Italic 600/700/800.
2. Alternativa sin fuentes: SF Pro (system) para display + **New York italic** (`.fontDesign(.serif)`) para el rol serif.

Roles (tamaños en pt, del prototipo):
- H1 pestañas: 28–32, weight 900, tracking −0.02em
- Titular de resultados: 24, weight 800, **serif italic** (Playfair) — línea 1.22
- Título de tarjeta/fila: 14–15.5, weight 700–800
- Cuerpo: 14.5, weight 500, línea 1.4–1.52
- Caption/hint: 11–12.5, weight 500, color `TextTertiary`
- Section label: 11.5, weight 700, MAYÚSCULAS, tracking +0.09em
- Eyebrow dorado: 11, weight 800, MAYÚSCULAS, tracking +0.13em, con ícono 14pt
- Citas/fechas/estenográfica: serif italic 16.5, línea 1.56
- Tiempos/cifras: `.monospacedDigit()`, weight 600–700
- Cronómetro de grabación: 58, weight 700, mono, tabular

### Radios / espaciado / sombra
- Tarjetas de vidrio: 22–26 · Botones grandes: 16–18 (alto 48–58) · Píldoras/segmentado/tab bar/chips: cápsula total · Diálogos: 24 · Video: 18
- Margen lateral de pantalla: 18 · gap entre tarjetas: 14–20 · padding interno de tarjeta: 16–20
- Sombra (solo si el glassEffect no la da ya): claro `0 12 32 rgba(79,10,33,0.14)`, oscuro `0 16 44 rgba(0,0,0,0.55)`

### Reglas de marca
- **Cápsulas sólidas** (no vidrio): la firma PL. Doradas (`AccentGoldFill` + texto `OnGold` 800): "IA LOCAL", badge "IA". Vino (`#611029` + blanco): "EN VIVO", badge "MÍO".
- **Nunca emoji.** Íconos: SF Symbols (el prototipo usa strokes estilo Lucide; usa el SF Symbol equivalente: `waveform`, `mic`, `dot.radiowaves.left.and.right`, `scissors`, `sparkles`, `text.quote`, `newspaper`, `tag`, `clock`, `book`, `photo.on.rectangle`, etc.)
- Serif italic = contenido editorial (citas, estenográfica, fechas, titular de resultados). Sans = UI.

---

## Estructura de navegación (cambio principal)

**Antes:** `ContentView` monolítico + botones toolbar → `.sheet` (Historial, Diccionario, En vivo).
**Ahora:**
```
TabView (nativo iOS 26, se minimiza al hacer scroll)
├─ Tab "Inicio"      → HomeView (nuevo)
├─ Tab "Historial"   → HistoryView (de sheet a pestaña)
└─ Tab "Diccionario" → DictionaryView (de sheet a pestaña)
Push a pantalla completa (no sheet): Resultados, Facebook Live
Overlays inmersivos: Grabando, En vivo (mic), Progreso
Onboarding: fullScreenCover primera vez (ya existe OnboardingView.swift — restilizar)
```
SwiftUI: `TabView` + `.tabBarMinimizeBehavior(.onScrollDown)`. Mini reproductor en Resultados: **`.tabViewBottomAccessory`** si la jerarquía lo permite; si no, cápsula `.glassEffect` flotante 88pt sobre el borde inferior.

---

## Screens / Views

### 1. Inicio (`ContentView.swift` → extraer a `HomeView`)
Orden vertical (scroll, padding 18):
1. **Fila nav:** logo PL en círculo de vidrio 46pt (izq) · fecha serif italic 14.5 `TextTertiary` (der).
2. **Héroe:** "PrensaIA" 32/900 + cápsula dorada "IA LOCAL" al lado; subtítulo "Transcribe, escucha y analiza — sin internet." 14.5/500 `TextTertiary`.
3. **Chip semáforo del motor** (centrado, vidrio clear, cápsula): estado de `TranscriptionService` — "Listo para transcribir" (check verde) / "Preparando el motor…" (pulso oro) / "Descargando motor Rápido n%" / "Motor Rápido listo". Fuente 12/600.
4. **CTA principal:** "Subir audio o video" — `.glassProminent` tinte `BrandPrimary`, alto 58, radio 18, ícono `square.and.arrow.up` invertido (flecha arriba), texto 15.5/700 blanco.
5. **Mosaico 3 tiles** (grid 3 cols, gap 12, alto 84, vidrio regular, radio 22): Grabar (`mic`), En vivo (`waveform.badge.mic`), Galería (`photo.on.rectangle`). Ícono 24 `BrandText` + label 13/700.
6. **Tarjeta Facebook Live** (vidrio, radio 22): ícono `dot.radiowaves.left.and.right` + "Transcribir Facebook Live" 14.5/700 + subtítulo + chevron. → push FBLiveView.
7. **Sección ORADORES** (label 11.5 caps): tarjeta con toggle "Identificar oradores" (+ descripción 12.5) y, si ON, fila "Número de oradores" con chip stepper cápsula ("Automático" o número, chevrons arriba/abajo). Divider hairline entre filas.
8. **Sección RECIENTES:** tarjeta con las 2 últimas transcripciones de `HistoryStore` (título 1 línea ellipsis 14/700, fecha 12 `TextTertiary`, chevron) → abre resultados.
9. **Nota privacidad** centrada: check dorado 14 + "Se procesa en tu iPhone, en español y sin internet." 12.5.

### 2. Grabando (overlay inmersivo — `ContentView` graba hoy)
Centrado: punto rojo pulsante + "Grabando" 16/800 → cronómetro 58 mono → tarjeta de vidrio con **onda animada** (26 barras, 4.5pt ancho, alturas aleatorias, animación scaleY 1.05s escalonada; cada 5ª barra dorada, resto `BrandText`) → CTA "Detener y transcribir" `.glassProminent` vino con ícono stop → "Cancelar" texto `LiveRed` 15/600.

### 3. En vivo — micrófono (`ContentView+LiveSheet.swift`: de sheet a overlay)
- Header: punto rojo pulsante + cápsula vino "EN VIVO" (o "PREPARANDO…" mientras carga el modelo; al terminar check verde + "Transcripción lista" 17/800).
- Tarjeta de vidrio radio 26 con el texto (serif italic 18/1.62): confirmado en `TextPrimary`, **hipótesis en `TextTertiary`**, caret "▍" parpadeante. Auto-scroll al fondo. Alto ~240 scrollable.
- Corriendo: "Detener" `.glassProminent` tinte `LiveRed` + botón circular copiar 54. Terminado: "Analizar con IA" vino (sparkles) + fila "Copiar texto" / "Listo".
- Hint 12: "El texto gris es provisional; se confirma al escuchar mejor."

### 4. Facebook Live (`ContentView.swift` hoja actual → `FBLiveView` push)
- Nav: circular back (izq), cápsula de vidrio con título "Facebook Live" (centro).
- Tarjeta estado: "Capturando…" + MB creciendo mono / "Captura lista" check verde / "Sin captura todavía".
- Tarjeta "Cómo funciona": 4 pasos numerados (número 13/800 `BrandText`, texto 13/500 `TextTertiary`).
- Fila broadcast: botón cuadrado 56 radio 18 `.glassProminent` (vino; **rojo cuando captura**) con `dot.radiowaves.left.and.right` + explicación. (Envuelve el `RPSystemBroadcastPickerView` existente.)
- Tarjeta **"Leer casi en vivo"** (visible si captura/hay texto): header con ícono viewfinder + botón Activar/Pausar; texto serif italic 16.5 por tramos (~20 s), auto-scroll, max 210; hints 11–11.5.
- CTA "Transcribir lo capturado" (deshabilitado sin captura, opacity 0.5) → flujo de progreso.
- Link destructivo "Borrar captura y empezar de cero" (trash 15, `LiveRed` 13.5/600).
- Nota legal 11 sobre videos protegidos (copy del prototipo).

### 5. Progreso (`TranscriptionService.phase` ya emite las etapas)
- **Anillo 128pt** (stroke 9): indeterminado = arco 25% rotando 1.1s con logo PL al centro; transcribiendo = progreso real con % mono 24 al centro.
- Stepper 3 pasos "Preparar / Transcribir / Analizar" (barras 5pt: activas `BrandPrimary`, resto `Divider`).
- Tarjeta de etapa: spinner + título 16/800 + % + barra fina + subtítulo 12.5 — textos exactos del servicio: "Preparando el modelo (solo la primera vez)…", "Procesando el audio…", "Transcribiendo… n%", "Identificando oradores… (la 1ª vez descarga un modelo)", "Analizando con IA…".
- Footer: "Puedes bloquear la pantalla; seguimos trabajando."

### 6. Resultados (`ContentView+Cards.swift` resultCard → vista push a pantalla completa)
- **Chrome flotante** sobre el scroll (top 54): circular back izq; share + ⋯ der (`GlassEffectContainer` de circulares 44). Menú ⋯: Editar transcripción / Copiar esta pestaña / Exportar a PDF (usa `ContentView+Export.swift`).
- **Bloque título** (scrollea): eyebrow dorado "COBERTURA · fecha" → **titular serif italic 24/800** → meta 12.5 con reloj: "02:28 · 3 oradores · video? · motor Preciso|Rápido".
- **Segmentado de vidrio sticky** (pinned al hacer scroll): track clear cápsula + **thumb vino deslizante** (0.32s spring), 4 opciones 12.5/700: Por minuto / Estenográfica / Análisis / Cortes.
- **Modo edición** (reemplaza el chrome): botón "Listo" vino arriba-izq; cada segmento = timestamp mono + TextEditor en vidrio clear radio 14. (= `isEditing` actual.)
- **Mini reproductor flotante** (cápsula de vidrio, bottom 88, ancho −48): play/pause circular vino 42 · barra de progreso 4pt + "mm:ss / mm:ss" mono 11.5 · botón velocidad "1x→1.5x→2x" mono 12.5. Persiste en las 4 pestañas.

#### 6a. Por minuto (`ContentView+Transcript.swift`)
- **playerArea:** si `service.isVideo` → **`VideoPlayer` nativo** alto 212, radio 18, fondo negro (controles AVKit nativos; el prototipo los simula: botón central de vidrio oscuro 58, barra inferior con tiempos mono blancos + thumb 12 + expand). Si audio → tarjeta de vidrio con **onda seekable** (160 muestras de `WaveformLoader`, barras: reproducidas `BrandPrimary`/`BrandText`, resto `Divider`, alto 44, tap/drag para seek).
- Barra de marcado: hint 12.5 izq / botón "Marcar tema" (scissors, 12.5/800 `BrandText`). En modo marcado: ícono hand.tap + texto por estado ("Toca el inicio del tema" → "Ahora toca el final" → "Ponle nombre y guarda") + "Listo".
- Panel nombrar tema (vidrio radio 20): "Tema de mm:ss a mm:ss" 13.5/800 → TextField vidrio clear → CTA "Guardar tema" vino 48 → hint 11.
- Lista de frases dentro de UNA tarjeta de vidrio radio 26: chip de orador al cambiar hablante (punto 9 + nombre 12.5/800 en su color + lápiz 12 → diálogo renombrar); cada fila = riel 3pt color de orador (izq) + timestamp mono 12 (40pt) + texto 14.5/1.42. Activa: fondo `BrandSoft` radio 14, texto `BrandPrimary` (claro) / `TextPrimary` (oscuro). En rango manual: fondo vino 16%.

#### 6b. Estenográfica (`ContentView+Estenografica.swift`)
- Sin limpiar: botón "Limpiar con IA" (sparkles 16 + 14/800 `BrandText`). Corriendo: tarjeta con "Limpiando con IA… n%" + barra fina. Listo: **segmentado chico Limpia/Original** (190pt) + warning "Revisa antes de publicar" (11) + circular copiar 40.
- Turnos agrupados por orador en tarjeta de vidrio: chip de orador (nombre CAPS 11.5/800 color + lápiz) + párrafo **serif italic 16.5/1.56** `TextPrimary`.

#### 6c. Análisis (`ContentView+AnalysisCortes.swift`)
- 4 tarjetas de vidrio radio 24 con eyebrow dorado: **RESUMEN** (14.5/500/1.52) · **TEMAS PRINCIPALES** (bullets punto dorado 5pt) · **FRASES TEXTUALES · VERIFICADAS** (regla dorada 3pt izq + cita serif italic 15.5 entre comillas) · **TITULARES SUGERIDOS** (filas 14.5/700 + ícono copiar, divididas hairline).
- Warning 11.5 + tarjeta **"PREGÚNTALE A ESTA ENTREVISTA"**: input cápsula de vidrio clear + botón enviar circular vino 42 (55% opacity si vacío); estados: hint → "Pensando…" spinner → respuesta en vidrio clear radio 16 (14/1.5).

#### 6d. Cortes (`ContentView+AnalysisCortes.swift`)
- Secciones con headers dorados: **MIS TEMAS (n)** (badge vino "MÍO") y **SUGERIDOS POR LA IA (n)** (badge dorado "IA").
- Estado inicial IA: tarjeta explicación + CTA "Sugerir cortes por tema" (scissors). Corriendo: "Buscando cortes… n%" + barra. Listo: tarjetas + link "Volver a sugerir" (refresh 13).
- Tarjeta de bloque: círculo de selección fuera (22, `checkmark.circle.fill` vino al marcar) + tarjeta de vidrio (borde vino 1.5 si seleccionada): tema 14.5/800 + badge + play 20 · rango mono 11.5 **dorado** · resumen 13/500. Tap = previsualizar solo ese rango (para al llegar al fin).
- Barra inferior: "Seleccionar todo / Quitar todo" + contador → CTA "Exportar n corte(s)" (deshabilitada en 0) → menú: "Exportar como videos|audios separados" / "Unir en un solo video|audio" (palabra según `service.isVideo`) → progreso "Exportando cortes… n%" → share sheet nativa.

### 7. Historial (`ContentView+Sheets.swift` → pestaña)
- H1 "Historial" + "Editar" (modo borrar: `minus.circle.fill` rojo por fila).
- Búsqueda: cápsula de vidrio clear con lupa + placeholder "Buscar en transcripciones".
- TRANSCRIPCIONES: tarjeta con filas (título 14.5/700, fecha **serif italic** 12.5, chip "Con análisis" sparkles dorado 11/700, chevron). Vacío: copy amable.
- ALMACENAMIENTO: "Audio y video guardados · n MB" (mono) + 2 filas destructivas rojas + nota 11.
- MOTOR DE TRANSCRIPCIÓN: segmentado **Preciso / Rápido** + párrafo explicativo 11.5 (copys exactos del prototipo) + estado de descarga (link "Descargar motor Rápido ahora (~600 MB)" / barra n% / seal verde "descargado y listo").
- APARIENCIA: segmentado **Sistema / Claro / Oscuro** (persistir en `@AppStorage`; hoy ya existe la preferencia) + link "Ver la bienvenida de nuevo" (sparkles).

### 8. Diccionario (`ContentView+Sheets.swift` → pestaña)
H1 + párrafo intro 13.5. AGREGAR CORRECCIÓN: 2 TextFields vidrio clear ("Como sale (ej. Bizcaino)" / "Correcto (ej. Vizcaíno)") + CTA "Agregar al diccionario" (plus, deshabilitado si algún campo vacío). MIS CORRECCIONES (n): filas "malo tachado `TextTertiary` → flecha dorada → correcto 14.5/700 + ✕ borrar".

### 9. Onboarding (`OnboardingView.swift` — restilizar)
Fondo ambiental. "Saltar" arriba-der. 4 páginas: círculo `.glassProminent` vino 104 con SF Symbol 46 blanco (`waveform`, `dot.radiowaves.left.and.right`, `scissors`, `sparkles`) → título **serif italic 27/800** → párrafo 14.5/1.55 (max 300pt). Dots 8pt (activo vino). CTA "Siguiente" / "Comenzar" vino 56. Copys exactos en `app3/data.jsx` → `ONBOARDING_PAGES`.

### 10. Diálogos y share
- Renombrar orador: alerta de vidrio centrada (max 300, radio 24): título 16/800 + mensaje 12.5 + TextField centrado + fila Cancelar / **Guardar** (dividida hairline). En SwiftUI basta `.alert` con TextField.
- Compartir: `ShareLink`/`UIActivityViewController` nativos (el prototipo la simula).

---

## Interactions & Behavior
- **Press:** scale 0.96, 0.16s ease (nativo con `.glassEffect(.interactive())` / `.buttonStyle(.glass)`).
- **Push:** deslizamiento 0.3s `cubic-bezier(0.32,0.72,0,1)` — usa la transición nativa de NavigationStack.
- **Segmentado:** thumb desliza 0.32s (matchedGeometryEffect).
- **Tab bar:** se minimiza al scrollear hacia abajo (`.tabBarMinimizeBehavior(.onScrollDown)`); en Resultados va compacta.
- Punto REC y cápsula EN VIVO: pulso opacity 1→0.35 1.1s. Caret en vivo: parpadeo 1s step. Onda de grabación: scaleY 1.05s escalonado por barra.
- Anillo indeterminado: rotación 1.1s linear. Barras de progreso: width 0.3s.
- **Respetar `accessibilityReduceMotion`** (el prototipo desactiva todo con prefers-reduced-motion).
- Tap en frase = seek + play desde ahí. Tap en corte = reproducir solo ese rango. Onda/línea de video: seek por tap/drag.

## State Management
Ya existe todo en el repo (`TranscriptionService`, `PlayerController`, `HistoryStore`, etc.) — **no cambia la lógica, solo la presentación**. Estados de UI nuevos: pestaña activa del TabView; `flow` (grabando/en vivo/progreso/resultados/fblive) como NavigationStack path u overlays; modo edición; modo marcado manual (inicio→fin→nombre); selección de cortes (Set); estados idle/running/done para limpieza IA, preguntas, sugerencia de cortes y exportación.

## Assets
- `assets/logo-pl.png` — monograma PL original (vino). Úsalo en claro.
- `assets/logo-pl-gold.png` — versión oro generada, para modo oscuro.
- `assets/logo-pl-white.png` — versión blanca (por si se necesita sobre vino).
- `assets/pl-tokens.css` — tokens fuente de la marca (referencia).
- `assets/video-frame.jpg` — **solo demo** del prototipo (fotograma del reproductor). NO incluir en la app.
- Fuentes: descargar Montserrat + Playfair Display de Google Fonts si se opta por empaquetarlas.

## Files
- `PrensaIA App Completa.html` — **prototipo definitivo** (v3, todas las funciones auditadas del repo).
- `app3/` — pantallas v3: `home.jsx`, `results.jsx`, `tabs-text.jsx` (Por minuto + Estenográfica), `tabs-ai.jsx` (Análisis + Cortes), `fblive.jsx`, `library.jsx` (Historial/Diccionario/Onboarding), `ui-extra.jsx` (menús, diálogos, share, onda, video player), `app.jsx` (estados/flujos), `data.jsx` (copys).
- `app2/lg-ui.jsx` — primitivas visuales: temas claro/oscuro completos, vidrio, botones, segmentado, tab bar, toggle, cápsulas. **Aquí están todos los valores exactos.**
- `app/prensaia-data.jsx` — datos demo (transcripción, análisis, cortes, historial).
- `PrensaIA.html` + `app/` (v1), `PrensaIA Liquid Glass.html` + `app2/` (v2) — iteraciones anteriores, solo contexto.
- `ios-frame.jsx`, `tweaks-panel.jsx` — soporte del prototipo (marco iPhone y panel de tweaks). Ignorar para la implementación.

## Sugerencia de plan de implementación (para Claude Code)
1. Tokens: colores adaptativos en Assets.xcassets + fuentes + reemplazo global de `Color.brand`.
2. Fondo ambiental + TabView 3 pestañas + mover Historial/Diccionario de sheets a pestañas.
3. HomeView nueva (héroe, chip de motor, CTA, mosaico, FB Live, oradores, recientes).
4. Resultados: push full-screen, chrome flotante, segmentado sticky, mini reproductor.
5. Las 4 pestañas de resultados + video/onda.
6. Overlays: Grabando, En vivo, Progreso (anillo), FB Live.
7. Onboarding + diálogos + pulido (pulsos, reduce motion).
Compilar y probar en claro y oscuro tras cada paso.
