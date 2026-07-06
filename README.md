# PrensaIA 📰🎙️

**Transcripción y análisis periodístico, 100% en el iPhone. Sin internet, sin nube, sin costos.**

App personal de iOS para cobertura periodística: transcribe entrevistas, conferencias y videos en español, identifica quién habla, genera análisis con IA local y exporta cortes de video listos para publicar. Todo el material se procesa **dentro del dispositivo** — nada sale del teléfono.

## Principios (no negociables)

1. **100% on-device** — el material periodístico es sensible; ningún audio o texto se envía fuera.
2. **Gratis para siempre** — solo tecnologías de licencia permisiva (MIT/Apache), sin cuentas ni claves de pago.
3. **Funciona sin internet** — solo se aceptan descargas iniciales únicas de modelos.
4. **Todo en español** — interfaz, resultados y mensajes.

## Funciones

- **Transcripción** de audio/video (Archivos, galería, grabación propia) con marcas de tiempo por frase; toca una frase y el audio salta a ese momento.
- **Dos motores a elegir** (Historial → Motor): *Preciso* (Whisper large-v3 turbo) o *Rápido* (Parakeet TDT v3 en el Neural Engine).
- **Identificación de oradores** (diarización) con nombres editables.
- **Versión estenográfica** por párrafos + limpieza con IA (muletillas, puntuación).
- **Análisis con IA local**: resumen, temas, frases textuales verificadas contra el audio, titulares sugeridos y preguntas a la entrevista.
- **Temas manuales y cortes por tema** (IA), exportables como clips de video/audio separados o unidos.
- **Facebook Live**: captura el audio de una transmisión vía extensión de broadcast y léela "casi en vivo" sin altavoz — pensado para accesibilidad auditiva.
- **Historial** con audio/video guardado, exportación a PDF, diccionario de correcciones de nombres propios, tema claro/oscuro, hápticos de accesibilidad.
- **Diseño Liquid Glass nativo de iOS 26** (vidrio en controles, materiales translúcidos, fondo aurora).

## Tecnologías

| Componente | Tecnología | Licencia |
|---|---|---|
| Transcripción (Preciso) | [WhisperKit](https://github.com/argmaxinc/WhisperKit) + modelo large-v3 turbo | MIT |
| Transcripción (Rápido) | [FluidAudio](https://github.com/FluidInference/FluidAudio) + Parakeet TDT v3 0.6B (Neural Engine) | Apache 2.0 |
| Oradores | SpeakerKit (Pyannote) | MIT |
| IA de análisis | Qwen 3 4B (4-bit) vía [MLX Swift](https://github.com/ml-explore/mlx-swift), con respaldo de Apple Foundation Models | Apache 2.0 |
| Captura en vivo | ReplayKit (Broadcast Upload Extension) + App Group | — |
| Interfaz | SwiftUI, iOS 26, Liquid Glass | — |

## Estructura del código

```
PrensaIA/
├── PrensaIAApp.swift            Raíz y tema claro/oscuro
├── ContentView.swift            Estado y estructura principal
│   ├── +Cards / +Transcript / +Estenografica / +AnalysisCortes
│   ├── +LiveSheet / +Sheets / +Export        (una pantalla = un archivo)
├── TranscriptionService.swift   Cerebro: transcripción, oradores, análisis, cortes, casi-en-vivo
├── FastTranscriber.swift        Motor Rápido (única puerta a FluidAudio)
├── LocalAI.swift                Motor Qwen 3 (única puerta a MLX)
├── MediaPlayback.swift          Reproductor audio/video + onda
├── MediaClipExporter.swift      Exportación de clips
├── LiveCapture.swift            Puente con la extensión de broadcast
├── HistoryStore.swift · Models.swift · AudioRecorder.swift
├── PDFExport.swift · DesignSystem.swift · OnboardingView.swift
└── PrensaLiveCapture/           Extensión: captura audio de pantalla → WAV en App Group
```

## Compilar

1. Requisitos: **Xcode 26+**, iPhone con **iOS 26+** (probado en iPhone 17 Pro Max).
2. Abrir `PrensaIA.xcodeproj`, seleccionar tu equipo de firma en ambos targets (app y extensión) y dar Play.
3. **Nota sobre modelos**: el modelo Whisper (~630 MB) está excluido del repositorio por límites de tamaño de GitHub (ver `.gitignore`). No hace falta nada: la app **descarga y cachea los modelos automáticamente** la primera vez que se usan (Whisper, Parakeet, Qwen y oradores). Solo esa primera vez se necesita internet.

## Reglas de memoria (importantes para contribuir)

- La IA es Qwen 3 **4B** — no subir a 8B (memoria del iPhone).
- `MLX.Memory.cacheLimit = 20 MB` al cargar; `clearCache()` entre tareas pesadas.
- **Nunca dos motores de transcripción cargados a la vez** (Whisper ⇄ Parakeet se descargan mutuamente).
- Videos largos se procesan **por tramos** (chunking).

---

*Proyecto personal de Simon Rivas. Construido con Claude Code.*
