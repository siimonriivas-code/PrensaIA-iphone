//
//  TranscriptionService.swift
//  PrensaIA
//
//  Servicio central: transcripción, oradores, análisis, cortes y seguimiento en vivo.
//

import SwiftUI
import AVFoundation
import CoreMedia
import WhisperKit
import SpeakerKit
import FoundationModels

// MARK: - Servicio: transcripción + análisis (en el dispositivo)

@MainActor
@Observable
final class TranscriptionService {

    enum Phase: Equatable {
        case idle
        case preparingModel
        case processingAudio
        case transcribing(Double)
        case diarizing
        case finished
        case failed(String)
    }

    enum AnalysisState: Equatable {
        case idle
        case running
        case done
        case failed(String)
    }

    var phase: Phase = .idle
    var transcript: String = ""
    var segments: [TimedSegment] = []
    var analysis: AnalysisResult?
    var analysisState: AnalysisState = .idle
    var qaAnswer: String?
    var qaState: AnalysisState = .idle
    var cleanedTurns: [CleanTurn]?
    var cleanState: AnalysisState = .idle
    var cleanProgress: Double = 0
    var blocks: [BloqueTema]?
    var blocksState: AnalysisState = .idle
    var blocksProgress: Double = 0
    var manualBlocks: [BloqueTema] = []   // temas marcados a mano por el usuario
    var currentFileName: String = ""
    var playbackURL: URL?
    var isVideo: Bool = false
    var currentSavedID: UUID?
    var diarizationEnabled: Bool = false
    private(set) var whisperReady = false   // motor Preciso precalentado y listo
    private(set) var whisperDownloadProgress: Double = 0   // 0<..<1 solo mientras descarga la 1ª vez
    var expectedSpeakers: Int = 0
    var speakerNames: [Int: String] = [:]
    var corrections: [Correccion] = []

    // Transcripción en vivo
    var isLive = false
    var liveStarting = false
    var liveDone = false
    var liveConfirmed = ""
    var liveHypothesis = ""
    // Amortiguador: el callback llega token por token (muchas veces/seg). Guardamos
    // el texto crudo aquí y refrescamos la pantalla como máx. 5 veces/seg, para no
    // saturar el hilo principal (esa saturación hacía que el texto solo apareciera al Detener).
    private var livePendingConfirmed = ""
    private var livePendingCurrent = ""
    private var liveFlushScheduled = false

    private var whisperKit: WhisperKit?
    private var speakerKit: SpeakerKit?
    private var liveTranscriber: AudioStreamTranscriber?
    private var liveTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var progressTimer: Timer?
    private var transcribeStart: Date?
    private var estimatedSeconds: Double = 1
    private let supportedAudio: Set<String> = ["wav", "mp3", "m4a", "flac"]

    // MARK: Estado para la UI

    var isBusy: Bool {
        switch phase {
        case .preparingModel, .processingAudio, .transcribing, .diarizing: return true
        default: return false
        }
    }

    var showsResults: Bool {
        if case .finished = phase { return !transcript.isEmpty }
        return false
    }

    var currentStep: Int {
        switch phase {
        case .preparingModel, .processingAudio: return 0
        case .transcribing, .diarizing: return 1
        case .finished: return 2
        default: return 0
        }
    }

    var showStageSpinner: Bool {
        switch phase {
        case .preparingModel, .processingAudio, .diarizing: return true
        default: return false
        }
    }

    var stageTitle: String {
        switch phase {
        case .preparingModel: return "Preparando el modelo"
        case .processingAudio: return "Procesando el audio"
        case .transcribing: return "Transcribiendo"
        case .diarizing: return "Identificando oradores"
        default: return ""
        }
    }

    var stageSubtitle: String {
        switch phase {
        case .preparingModel: return "Solo la primera vez. Un momento…"
        case .processingAudio: return "Preparando el audio para transcribir…"
        case .transcribing: return "Reconociendo el habla en español…"
        case .diarizing: return "Detectando quién habla. La 1ª vez descarga un modelo…"
        default: return ""
        }
    }

    var stagePercentText: String? {
        if case .transcribing(let frac) = phase {
            return "\(Int(frac * 100))%"
        }
        return nil
    }

    // MARK: Carga del modelo (segura para llamarse varias veces)

    func prepareModelIfNeeded() async {
        if whisperKit != nil { whisperReady = true; return }
        // Whisper se precalienta al abrir la app: así "en vivo" y las
        // transcripciones arrancan al instante (como siempre). Si el motor
        // Rápido estuviera cargado, se libera (ley de memoria: nunca dos).
        FastTranscriber.shared.unload()
        if let loadTask {
            await loadTask.value
            whisperReady = (whisperKit != nil)
            return
        }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            let modelName = "large-v3-v20240930_turbo_632MB"
            let key = "prensaia_whisper_folder"
            // 0. ¿El modelo viene incluido dentro de la app? -> 100% sin internet.
            if let bundled = Bundle.main.url(
                forResource: "openai_whisper-large-v3-v20240930_turbo_632MB",
                withExtension: nil)?.path,
               FileManager.default.fileExists(atPath: bundled) {
                self.whisperKit = try? await WhisperKit(WhisperKitConfig(
                    model: modelName,
                    modelFolder: bundled,
                    prewarm: true,
                    load: true
                ))
            }
            // Si ya se descargó antes, cargar desde el disco (sin necesidad de internet).
            if self.whisperKit == nil,
               let saved = UserDefaults.standard.string(forKey: key),
               FileManager.default.fileExists(atPath: saved) {
                self.whisperKit = try? await WhisperKit(WhisperKitConfig(
                    model: modelName,
                    modelFolder: saved,
                    prewarm: true,
                    load: true
                ))
            }
            // Si no hay copia local (primera vez, o tras reinstalar), descargar
            // el modelo CON PROGRESO visible y luego cargarlo desde la carpeta
            // (guardando la ruta para no volver a bajarlo).
            if self.whisperKit == nil {
                let folderURL = try? await WhisperKit.download(
                    variant: modelName,
                    progressCallback: { [weak self] progress in
                        Task { @MainActor [weak self] in
                            self?.whisperDownloadProgress = progress.fractionCompleted
                        }
                    }
                )
                if let folderURL {
                    UserDefaults.standard.set(folderURL.path, forKey: key)
                    self.whisperKit = try? await WhisperKit(WhisperKitConfig(
                        model: modelName,
                        modelFolder: folderURL.path,
                        prewarm: true,
                        load: true
                    ))
                }
                self.whisperDownloadProgress = 0   // termina: se apaga el indicador
            }
        }
        loadTask = task
        await task.value
        loadTask = nil
        whisperReady = (whisperKit != nil)
    }

    func clearDownloadedModel() {
        let key = "prensaia_whisper_folder"
        if let saved = UserDefaults.standard.string(forKey: key) {
            try? FileManager.default.removeItem(atPath: saved)
        }
        UserDefaults.standard.removeObject(forKey: key)
        whisperKit = nil
        whisperReady = false
    }

    // MARK: Transcripción en vivo (tiempo real)

    func startLive() async {
        guard !isLive, !liveStarting else { return }
        liveStarting = true
        liveDone = false
        liveConfirmed = ""
        liveHypothesis = ""
        livePendingConfirmed = ""
        livePendingCurrent = ""
        liveFlushScheduled = false
        await prepareModelIfNeeded()
        guard let whisperKit, let tokenizer = whisperKit.tokenizer else {
            liveStarting = false
            return
        }
        var options = DecodingOptions(task: .transcribe, language: "es")
        options.usePrefillPrompt = true
        let transcriber = AudioStreamTranscriber(
            audioEncoder: whisperKit.audioEncoder,
            featureExtractor: whisperKit.featureExtractor,
            segmentSeeker: whisperKit.segmentSeeker,
            textDecoder: whisperKit.textDecoder,
            tokenizer: tokenizer,
            audioProcessor: whisperKit.audioProcessor,
            decodingOptions: options
        ) { [weak self] _, newState in
            let confirmed = newState.confirmedSegments
                .map { $0.text.trimmingCharacters(in: .whitespaces) }
                .joined(separator: " ")
            let pending = newState.unconfirmedSegments
                .map { $0.text.trimmingCharacters(in: .whitespaces) }
                .joined(separator: " ")
            let current = pending.isEmpty ? newState.currentText : pending
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Solo GUARDAMOS el texto crudo (barato) y pedimos un refresco amortiguado.
                self.livePendingConfirmed = confirmed
                self.livePendingCurrent = current
                self.scheduleLiveFlush()
            }
        }
        liveTranscriber = transcriber
        isLive = true
        liveStarting = false
        liveTask = Task { [weak self] in
            do {
                try await transcriber.startStreamTranscription()
            } catch {
                await MainActor.run {
                    self?.isLive = false
                }
            }
        }
    }

    // Refresco amortiguado del texto en vivo: convierte el texto crudo (con la
    // limpieza y las correcciones, que son costosas) a lo sumo 5 veces por segundo.
    private func scheduleLiveFlush() {
        guard !liveFlushScheduled else { return }
        liveFlushScheduled = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)   // 0.2 s
            guard let self else { return }
            self.liveFlushScheduled = false
            self.flushLiveText()
        }
    }

    private func flushLiveText() {
        liveConfirmed = correctText(cleanText(livePendingConfirmed))
        let h = cleanText(livePendingCurrent)
        liveHypothesis = (h == "Waiting for speech...") ? "" : correctText(h)
    }

    func stopLive() async {
        await liveTranscriber?.stopStreamTranscription()
        liveTask = nil
        liveTranscriber = nil
        isLive = false
        flushLiveText()   // vuelca cualquier texto pendiente del amortiguador
        // Pasa lo "en proceso" a confirmado para no perderlo, y deja el texto en pantalla.
        if !liveHypothesis.isEmpty {
            liveConfirmed = liveFullText
            liveHypothesis = ""
        }
        liveDone = !liveConfirmed.isEmpty
    }

    func clearLive() {
        liveDone = false
        liveConfirmed = ""
        liveHypothesis = ""
        livePendingConfirmed = ""
        livePendingCurrent = ""
    }

    var liveFullText: String {
        [liveConfirmed, liveHypothesis]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: Seguimiento casi en vivo de una captura (Facebook Live, Fase 2)
    //
    // Mientras la extensión sigue grabando el WAV en el App Group, aquí se van
    // transcribiendo SOLO los tramos nuevos (~cada 15-20 s) y el texto se acumula.
    // Es una lectura rápida; la transcripción final completa sigue siendo la buena.

    var followActive = false
    var followText = ""
    var followHint = ""
    private var followTask: Task<Void, Never>?
    private var followOffset: UInt64 = 44   // brinca la cabecera WAV

    func startFollowing(captureURL: URL) {
        guard !followActive else { return }
        followActive = true
        followText = ""
        followHint = "Preparando el modelo…"
        followOffset = 44
        followTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.prepareModelIfNeeded()
            guard self.whisperKit != nil else {
                self.followHint = "No se pudo preparar el modelo. Revisa tu internet la primera vez."
                self.followActive = false
                return
            }
            self.followHint = "Escuchando… el texto aparece en tramos de ~20 segundos."
            while !Task.isCancelled && self.followActive {
                await self.followStep(captureURL: captureURL)
                try? await Task.sleep(nanoseconds: 6_000_000_000)
            }
        }
    }

    func stopFollowing() {
        followActive = false
        followTask?.cancel()
        followTask = nil
    }

    func clearFollow() {
        stopFollowing()
        followText = ""
        followHint = ""
    }

    private func followStep(captureURL: URL) async {
        guard let whisperKit, !isBusy else { return }   // no pelear con una transcripción completa
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: captureURL.path),
              let size = (attrs[.size] as? NSNumber)?.uint64Value else { return }

        let bytesPerSecond: UInt64 = 32_000               // WAV 16 kHz · mono · 16 bits
        let pending = size > followOffset ? size - followOffset : 0
        guard pending >= bytesPerSecond * 15 else { return }          // junta ≥15 s nuevos
        let chunkBytes = min(pending, bytesPerSecond * 180)           // máx. 3 min por tramo

        guard let handle = try? FileHandle(forReadingFrom: captureURL) else { return }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: followOffset)) != nil,
              let data = try? handle.read(upToCount: Int(chunkBytes)),
              !data.isEmpty else { return }

        followOffset += UInt64(data.count)

        // Tramo en silencio: sáltalo (si no, Whisper inventa texto).
        var peak: Int16 = 0
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            for v in raw.bindMemory(to: Int16.self) {
                let a = v == Int16.min ? Int16.max : abs(v)
                if a > peak { peak = a }
            }
        }
        guard peak > 200 else { return }

        // Tramo → WAV temporal → Whisper.
        let chunkURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("liveChunk-\(UUID().uuidString).wav")
        var wav = Self.pcmWavHeader(dataLength: data.count)
        wav.append(data)
        try? wav.write(to: chunkURL)
        defer { try? FileManager.default.removeItem(at: chunkURL) }

        let options = DecodingOptions(task: .transcribe, language: "es")
        guard let results = try? await whisperKit.transcribe(
            audioPath: chunkURL.path(percentEncoded: false),
            decodeOptions: options) else { return }
        let text = correctText(cleanText(results.map { $0.text }.joined(separator: " ")))
        guard !text.isEmpty else { return }
        followText += (followText.isEmpty ? "" : " ") + text
    }

    // Cabecera WAV (PCM 16 kHz mono 16 bits) para los tramos temporales.
    private static func pcmWavHeader(dataLength: Int) -> Data {
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bits: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bits / 8)
        let blockAlign = channels * (bits / 8)
        let dataLen = UInt32(truncatingIfNeeded: dataLength)

        var header = Data()
        func str(_ s: String) { header.append(contentsOf: Array(s.utf8)) }
        func u32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { header.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { header.append(contentsOf: $0) } }

        str("RIFF"); u32(UInt32(36) + dataLen); str("WAVE")
        str("fmt "); u32(16); u16(1); u16(channels)
        u32(sampleRate); u32(byteRate); u16(blockAlign); u16(bits)
        str("data"); u32(dataLen)
        return header
    }

    // MARK: Proceso principal

    func process(mediaURL: URL) async {
        // Evita pisar una transcripción que ya está en curso.
        guard !isBusy else { return }

        currentFileName = mediaURL.lastPathComponent
        transcript = ""
        segments = []
        analysis = nil
        currentSavedID = nil
        speakerNames = [:]
        analysisTask?.cancel()
        analysisState = .idle
        qaAnswer = nil
        qaState = .idle
        cleanedTurns = nil
        cleanState = .idle
        blocks = nil
        blocksState = .idle
        manualBlocks = []
        // Solo borra el archivo anterior si es temporal. Si viene del historial
        // (carpeta permanente), NO se toca: borrarlo destruiría la grabación guardada.
        if let old = playbackURL,
           old.path.hasPrefix(FileManager.default.temporaryDirectory.path) {
            try? FileManager.default.removeItem(at: old)
        }
        playbackURL = nil
        isVideo = false

        // Motor elegido por el usuario (Historial → Motor de transcripción).
        let useFastEngine = UserDefaults.standard.string(forKey: "prensaia_engine") == "fast"
        if useFastEngine {
            // Ley de memoria: descargar Whisper antes de cargar Parakeet.
            whisperKit = nil
            whisperReady = false
            if !FastTranscriber.shared.isReady { phase = .preparingModel }
            let ok = await FastTranscriber.shared.ensureLoaded()
            guard ok else {
                phase = .failed("No se pudo preparar el motor Rápido. La primera vez necesita internet para descargar su modelo (~600 MB). Mientras tanto, puedes volver al motor Preciso en Historial → Motor de transcripción.")
                return
            }
        } else {
            FastTranscriber.shared.unload()
            if whisperKit == nil { phase = .preparingModel }
            await prepareModelIfNeeded()
            guard whisperKit != nil else {
                phase = .failed("No se pudo preparar el modelo. Conéctate a internet la primera vez e inténtalo de nuevo.")
                return
            }
        }

        do {
            phase = .processingAudio
            let localURL = try copyToSandbox(mediaURL)
            // El original (recording / Photos) era temporal: ya tenemos copia, libéralo.
            if mediaURL.path.hasPrefix(FileManager.default.temporaryDirectory.path) {
                try? FileManager.default.removeItem(at: mediaURL)
            }
            let mediaIsVideo = await hasVideoTrack(localURL)
            let audioURL = try await audioForTranscription(from: localURL)
            let audioDuration = await durationSeconds(of: audioURL)

            // Audio prácticamente mudo: avisar en vez de transcribir (Whisper
            // "alucina" texto falso con silencio). Con voz real esta revisión es
            // casi instantánea: se detiene al primer sonido encontrado.
            let audible = await WaveformLoader.hasAudibleContent(url: audioURL)
            if !audible {
                try? FileManager.default.removeItem(at: localURL)
                if audioURL != localURL { try? FileManager.default.removeItem(at: audioURL) }
                phase = .failed("""
                El audio está en silencio, así que no hay nada que transcribir. \
                Si venía de una captura de pantalla, la app de origen pudo bloquear su audio: \
                prueba reproducir el video desde Safari (facebook.com) y captura de nuevo.
                """)
                return
            }

            phase = .transcribing(0)
            startProgressTimer(audioDuration: audioDuration, fast: useFastEngine)

            if useFastEngine {
                // Motor RÁPIDO (Parakeet en el Neural Engine).
                let fast = try await FastTranscriber.shared.transcribe(url: audioURL)
                stopProgressTimer()
                segments = fast.segments
                    .map { TimedSegment(start: $0.start, end: $0.end, text: cleanText($0.text)) }
                    .filter { !$0.text.isEmpty }
                let fullText = cleanText(fast.text)
                transcript = fullText.isEmpty ? "No se detectó voz en el archivo." : fullText
            } else {
                // Motor PRECISO (Whisper), el de siempre.
                guard let whisperKit else { throw NSError(domain: "PrensaIA", code: 3) }
                let options = DecodingOptions(task: .transcribe, language: "es")
                let results = try await whisperKit.transcribe(
                    audioPath: audioURL.path(percentEncoded: false),
                    decodeOptions: options
                )
                stopProgressTimer()
                segments = results
                    .flatMap { $0.segments }
                    .map { TimedSegment(start: Double($0.start),
                                        end: Double($0.end),
                                        text: cleanText($0.text)) }
                    .filter { !$0.text.isEmpty }
                let fullText = cleanText(results.map { $0.text }.joined(separator: " "))
                transcript = fullText.isEmpty ? "No se detectó voz en el archivo." : fullText
            }

            applyCorrections()

            if diarizationEnabled && !segments.isEmpty {
                phase = .diarizing
                await applyDiarization(audioPath: audioURL)
            }

            // Conserva el archivo ORIGINAL para reproducir (video) y para cortar clips.
            // El audio extraído (temporal) solo se usaba para transcribir/diarizar.
            playbackURL = localURL
            isVideo = mediaIsVideo
            if audioURL != localURL { try? FileManager.default.removeItem(at: audioURL) }

            phase = .finished
            analysisTask = Task { @MainActor [weak self] in
                await self?.runAnalysis()
            }
        } catch {
            stopProgressTimer()
            phase = .failed("No se pudo transcribir. Detalle: \(error.localizedDescription)")
        }
    }

    // ¿El archivo tiene pista de video? Decide reproductor de video vs. onda de audio.
    private func hasVideoTrack(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        if let tracks = try? await asset.loadTracks(withMediaType: .video) {
            return !tracks.isEmpty
        }
        return false
    }

    // MARK: Diarización (identificar oradores)

    private func applyDiarization(audioPath: URL) async {
        do {
            if speakerKit == nil {
                // ¿Los modelos de oradores vienen incluidos en la app? -> sin internet.
                if let bundled = Bundle.main.url(forResource: "speakerkit-models", withExtension: nil)?.path,
                   FileManager.default.fileExists(atPath: bundled),
                   let sk = try? await SpeakerKit(PyannoteConfig(modelFolder: bundled)) {
                    speakerKit = sk
                } else {
                    // Respaldo: descargar (modelos chiquitos, ~33 MB).
                    speakerKit = try await SpeakerKit()
                }
            }
            guard let speakerKit else { return }
            let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: audioPath.path(percentEncoded: false))
            let options = PyannoteDiarizationOptions(numberOfSpeakers: expectedSpeakers > 0 ? expectedSpeakers : nil)
            let result = try await speakerKit.diarize(audioArray: audioArray, options: options)
            guard result.speakerCount > 0 else { return }
            assignSpeakers(from: result)
        } catch {
            // Si falla (p. ej. sin internet la primera vez), se deja la transcripción sin oradores.
        }
    }

    private func assignSpeakers(from result: DiarizationResult) {
        // Para cada parte del texto, se asigna el orador que más coincide en tiempo.
        for i in segments.indices {
            let segStart = Float(segments[i].start)
            let segEnd = Float(segments[i].end)
            var overlapBySpeaker: [Int: Float] = [:]
            for d in result.segments {
                guard let sid = d.speaker.speakerId else { continue }
                let overlap = max(0, min(segEnd, d.endTime) - max(segStart, d.startTime))
                if overlap > 0 { overlapBySpeaker[sid, default: 0] += overlap }
            }
            if let best = overlapBySpeaker.max(by: { $0.value < $1.value })?.key {
                segments[i].speakerId = best
            }
        }
    }

    // MARK: Análisis (segundo plano)

    private func runAnalysis() async {
        guard !transcript.isEmpty, transcript != "No se detectó voz en el archivo." else {
            analysisState = .failed("No hay suficiente contenido para analizar.")
            return
        }

        analysisState = .running
        let input = String(transcript.prefix(8000))

        // 1. IA nueva (Qwen 3): pedimos JSON y lo interpretamos.
        await LocalAI.shared.ensureLoaded()
        if Task.isCancelled { return }
        if LocalAI.shared.isReady {
            let system = """
            Eres analista de noticias para un periodista en México. Respondes SIEMPRE en español, \
            fiel al contenido y sin inventar datos. Devuelves SOLO un objeto JSON válido, \
            sin texto adicional, sin explicaciones y sin markdown.
            """
            let userMsg = """
            Analiza esta transcripción para uso periodístico y responde SOLO con un objeto JSON \
            con exactamente estas llaves:
            {"resumen":"2 o 3 frases","temas":["tema corto", "..."],"frasesDestacadas":["cita TEXTUAL de UNA sola oración del audio", "..."],"titulares":["titular periodístico", "..."]}

            Transcripción:
            \(input)
            """
            if let raw = await LocalAI.shared.respond(system: system, user: userMsg, maxTokens: 1100),
               let parsed = parseAnalysisJSON(raw) {
                if Task.isCancelled { return }
                let verified = verbatimQuotes(parsed.frasesDestacadas, in: transcript)
                analysis = AnalysisResult(resumen: parsed.resumen, temas: parsed.temas,
                                          frasesDestacadas: verified, titulares: parsed.titulares)
                analysisState = .done
                return
            }
        }

        // 2. Respaldo: IA de Apple (salida estructurada).
        guard case .available = SystemLanguageModel.default.availability else {
            analysisState = .failed("No se pudo preparar la IA. La primera vez necesita internet para descargar el modelo.")
            return
        }
        do {
            let session = LanguageModelSession(instructions: """
            Eres un asistente para periodistas en México. Analizas transcripciones de entrevistas, \
            conferencias y eventos. Respondes SIEMPRE en español, de forma fiel al contenido y sin inventar datos. \
            Las frases destacadas deben ser citas CORTAS (una sola oración) y textuales del audio, nunca párrafos largos.
            """)
            let response = try await session.respond(
                to: "Analiza esta transcripción para uso periodístico:\n\n\(input)",
                generating: NewsAnalysis.self
            )
            if Task.isCancelled { return }
            let c = response.content
            let verifiedQuotes = verbatimQuotes(c.frasesDestacadas, in: transcript)
            analysis = AnalysisResult(resumen: c.resumen, temas: c.temas,
                                      frasesDestacadas: verifiedQuotes, titulares: c.titulares)
            analysisState = .done
        } catch {
            if Task.isCancelled { return }
            analysisState = .failed("No se pudo generar el análisis en el dispositivo (puede ser un audio muy largo). Lo mejoraremos por partes más adelante.")
        }
    }

    // Interpreta el JSON que devuelve Qwen (tolerante a texto/markdown alrededor).
    private struct AnalysisJSON: Decodable {
        let resumen: String
        let temas: [String]
        let frasesDestacadas: [String]
        let titulares: [String]
    }

    private func parseAnalysisJSON(_ raw: String) -> (resumen: String, temas: [String], frasesDestacadas: [String], titulares: [String])? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"), start < end else { return nil }
        let jsonStr = String(raw[start...end])
        guard let data = jsonStr.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(AnalysisJSON.self, from: data) else { return nil }
        guard !decoded.resumen.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return (decoded.resumen, decoded.temas, decoded.frasesDestacadas, decoded.titulares)
    }

    // Conserva solo las frases que aparecen TEXTUALES en la transcripción (protege de citas inventadas).
    private func verbatimQuotes(_ quotes: [String], in source: String) -> [String] {
        let normalize: (String) -> String = { s in
            s.lowercased()
                .folding(options: .diacriticInsensitive, locale: nil)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        let normSource = normalize(source)
        return quotes.filter { q in
            let nq = normalize(q)
            return !nq.isEmpty && normSource.contains(nq)
        }
    }

    // MARK: Cortes por tema (bloques con tiempo de inicio/fin)

    func suggestBlocks() async {
        guard !segments.isEmpty else {
            blocksState = .failed("No hay transcripción para dividir en bloques.")
            return
        }
        blocksState = .running
        blocksProgress = 0
        blocks = nil

        // Liberar los modelos de transcripción (Whisper y SpeakerKit): aquí ya no se usan,
        // y así le dejamos memoria libre a la IA para procesar videos largos sin saturar.
        // Se vuelven a cargar solos la próxima vez que transcribas.
        whisperKit = nil
        whisperReady = false
        speakerKit = nil
        FastTranscriber.shared.unload()

        await LocalAI.shared.ensureLoaded()
        if Task.isCancelled { return }
        guard LocalAI.shared.isReady else {
            blocksState = .failed("No se pudo preparar la IA. La primera vez necesita internet para descargar el modelo.")
            return
        }

        // Agrupar los segmentos en tramos de ~5500 caracteres. Así los videos largos
        // se procesan POR PARTES: cada parte es ligera (no satura la memoria) y entre
        // todas cubren el video completo.
        var chunks: [[TimedSegment]] = []
        var current: [TimedSegment] = []
        var chars = 0
        for seg in segments {
            let t = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { continue }
            current.append(seg)
            chars += t.count + 12
            if chars >= 5500 {
                chunks.append(current); current = []; chars = 0
            }
        }
        if !current.isEmpty { chunks.append(current) }
        if chunks.isEmpty {
            blocksState = .failed("No hay suficiente contenido para sugerir cortes.")
            return
        }

        // Procesar cada tramo, uno a la vez, y juntar los bloques.
        var allBlocks: [BloqueTema] = []
        for (i, chunk) in chunks.enumerated() {
            if Task.isCancelled { return }
            if let part = await blocksForSegments(chunk) {
                allBlocks.append(contentsOf: part)
            }
            LocalAI.shared.clearCache()   // libera memoria temporal entre partes
            blocksProgress = Double(i + 1) / Double(chunks.count)
        }

        allBlocks.sort { $0.inicio < $1.inicio }
        blocks = allBlocks
        blocksState = allBlocks.isEmpty
            ? .failed("No se pudieron identificar bloques. Intenta de nuevo.")
            : .done
    }

    // Pide a la IA los bloques temáticos de UN tramo de segmentos.
    private func blocksForSegments(_ segs: [TimedSegment]) async -> [BloqueTema]? {
        var lines: [String] = []
        for seg in segs {
            let t = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            lines.append("[\(mmss(seg.start))] \(t)")
        }
        let timed = lines.joined(separator: "\n")
        guard !timed.isEmpty else { return nil }

        let system = """
        Eres un asistente para un periodista que hace cortes de video. Divides la transcripción \
        en bloques por tema. Respondes SIEMPRE en español y SOLO con un objeto JSON válido, \
        sin texto adicional, sin explicaciones y sin markdown.
        """
        let userMsg = """
        Esta es una parte de la transcripción con marcas de tiempo. Agrúpala en bloques por TEMA: \
        cada bloque es un tramo continuo sobre un mismo asunto, pensado para cortar un clip de video. \
        Usa SOLO marcas de tiempo que aparezcan en el texto, en el mismo formato. Crea de 1 a 4 bloques.
        Para cada bloque da: "tema" (título corto), "inicio" (marca donde empieza), "fin" (marca donde \
        termina) y "resumen" (una frase de qué trata).
        Responde SOLO con JSON:
        {"bloques":[{"tema":"...","inicio":"...","fin":"...","resumen":"..."}]}

        Transcripción:
        \(timed)
        """

        guard let raw = await LocalAI.shared.respond(system: system, user: userMsg, maxTokens: 900) else {
            return nil
        }
        return parseBlocksJSON(raw)
    }

    private struct BlocksJSON: Decodable {
        struct B: Decodable {
            let tema: String
            let inicio: String
            let fin: String
            let resumen: String?
        }
        let bloques: [B]
    }

    private func parseBlocksJSON(_ raw: String) -> [BloqueTema]? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"), start < end else { return nil }
        let jsonStr = String(raw[start...end])
        guard let data = jsonStr.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BlocksJSON.self, from: data) else { return nil }
        let dur = segments.last?.end ?? Double.greatestFiniteMagnitude
        var out: [BloqueTema] = []
        for b in decoded.bloques {
            guard let ini = parseTime(b.inicio) else { continue }
            let fin = parseTime(b.fin) ?? ini
            let clampedIni = max(0, min(ini, dur))
            let clampedFin = max(clampedIni, min(fin, dur))
            let tema = b.tema.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tema.isEmpty else { continue }
            out.append(BloqueTema(
                tema: tema,
                inicio: clampedIni,
                fin: clampedFin,
                resumen: (b.resumen ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        return out
    }

    // Convierte "m:ss", "mm:ss", "h:mm:ss" o segundos sueltos a segundos.
    private func parseTime(_ s: String) -> Double? {
        let clean = s.trimmingCharacters(in: .whitespaces)
        let parts = clean.split(separator: ":").map { Double($0) }
        if parts.contains(where: { $0 == nil }) {
            return Double(clean)
        }
        let nums = parts.compactMap { $0 }
        switch nums.count {
        case 1: return nums[0]
        case 2: return nums[0] * 60 + nums[1]
        case 3: return nums[0] * 3600 + nums[1] * 60 + nums[2]
        default: return nil
        }
    }

    private func mmss(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }

    func ask(_ question: String) async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        guard !transcript.isEmpty, transcript != "No se detectó voz en el archivo." else {
            qaState = .failed("No hay transcripción para consultar.")
            return
        }
        qaState = .running
        qaAnswer = nil
        let input = String(transcript.prefix(8000))

        let system = """
        Respondes preguntas de un periodista SOLO con base en la transcripción que se te da. \
        Responde en español, de forma breve y precisa. Si la respuesta no está en la transcripción, \
        dilo claramente. No inventes datos ni cites lo que no aparece en el texto.
        """
        let userMsg = "Transcripción:\n\n\(input)\n\nPregunta: \(q)"

        // 1. IA nueva (Qwen 3). Se prepara la 1ª vez (descarga con internet); luego es local.
        await LocalAI.shared.ensureLoaded()
        if Task.isCancelled { return }
        if let answer = await LocalAI.shared.respond(system: system, user: userMsg, maxTokens: 700) {
            if Task.isCancelled { return }
            qaAnswer = answer
            qaState = .done
            return
        }

        // 2. Respaldo: IA de Apple.
        guard case .available = SystemLanguageModel.default.availability else {
            qaState = .failed("No se pudo preparar la IA. La primera vez necesita internet para descargar el modelo.")
            return
        }
        do {
            let session = LanguageModelSession(instructions: system)
            let response = try await session.respond(to: userMsg)
            if Task.isCancelled { return }
            qaAnswer = response.content
            qaState = .done
        } catch {
            if Task.isCancelled { return }
            qaState = .failed("No se pudo responder (puede ser un audio muy largo).")
        }
    }

    func cleanTranscript() async {
        guard !transcript.isEmpty, transcript != "No se detectó voz en el archivo." else {
            cleanState = .failed("No hay texto para limpiar.")
            return
        }

        // Agrupar el texto en turnos por orador (a partir de los segmentos).
        var turns: [(Int?, String)] = []
        for seg in segments {
            let t = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            if let last = turns.last, last.0 == seg.speakerId {
                turns[turns.count - 1].1 += " " + t
            } else {
                turns.append((seg.speakerId, t))
            }
        }
        if turns.isEmpty { turns = [(nil, transcript)] }

        cleanState = .running
        cleanProgress = 0
        cleanedTurns = nil

        let instructions = """
        Eres un editor de transcripciones para un periodista. Recibes el texto crudo de una parte de \
        una grabación y devuelves ESE MISMO texto, pero limpio: corriges puntuación, mayúsculas y acentos, \
        quitas muletillas (eh, este, o sea), repeticiones y falsos inicios, y lo separas en oraciones claras. \
        NO cambies las palabras ni el significado, NO agregues ni inventes nada, NO resumas, NO traduzcas. \
        Responde SOLO con el texto limpio, en español.
        """

        // Preparar la IA nueva (Qwen). Si no se puede, usaremos la de Apple.
        await LocalAI.shared.ensureLoaded()
        let useQwen = LocalAI.shared.isReady
        let appleAvailable: Bool = {
            if case .available = SystemLanguageModel.default.availability { return true }
            return false
        }()

        guard useQwen || appleAvailable else {
            cleanState = .failed("No se pudo preparar la IA. La primera vez necesita internet para descargar el modelo.")
            return
        }

        var out: [CleanTurn] = []
        for (idx, turn) in turns.enumerated() {
            if Task.isCancelled { cleanState = .idle; return }

            var cleaned: String? = nil
            if useQwen {
                cleaned = await LocalAI.shared.respond(system: instructions, user: turn.1, maxTokens: 1200)
            }
            if cleaned == nil, appleAvailable {
                let session = LanguageModelSession(instructions: instructions)
                cleaned = try? await session.respond(to: turn.1).content
            }

            out.append(CleanTurn(
                speakerId: turn.0,
                text: (cleaned ?? turn.1).trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            cleanProgress = Double(idx + 1) / Double(turns.count)
        }
        cleanedTurns = out
        cleanState = .done
    }

    func reportPickError() {
        phase = .failed("No se pudo cargar el video de la galería. Intenta de nuevo o usa Archivos.")
    }

    // MARK: Editar y exportar

    func rebuildTranscriptFromSegments() {
        let joined = segments.map { $0.text }.joined(separator: " ")
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        if !joined.isEmpty { transcript = joined }
    }

    // MARK: Progreso estimado de la transcripción

    private func startProgressTimer(audioDuration: Double, fast: Bool = false) {
        transcribeStart = Date()
        estimatedSeconds = max(2.0, audioDuration * (fast ? 0.03 : 0.2))
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.tickProgress()
            }
        }
    }

    private func tickProgress() {
        guard let start = transcribeStart else { return }
        let elapsed = Date().timeIntervalSince(start)
        let frac = min(0.92, elapsed / estimatedSeconds)
        if case .transcribing = phase {
            phase = .transcribing(frac)
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        transcribeStart = nil
    }

    // MARK: Utilidades

    private func durationSeconds(of url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        if let d = try? await asset.load(.duration) {
            let secs = CMTimeGetSeconds(d)
            return secs.isFinite && secs > 0 ? secs : 0
        }
        return 0
    }

    private func cleanText(_ s: String) -> String {
        let noTokens = s.replacingOccurrences(of: "<[|][^|]*[|]>", with: "", options: .regularExpression)
        return noTokens.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private func applyCorrections() {
        guard !corrections.isEmpty else { return }
        for i in segments.indices {
            segments[i].text = correctText(segments[i].text)
        }
        transcript = correctText(transcript)
    }

    func correctText(_ text: String) -> String {
        guard !corrections.isEmpty else { return text }
        var t = text
        for c in corrections where !c.wrong.trimmingCharacters(in: .whitespaces).isEmpty {
            // \b...\b evita reemplazar dentro de otra palabra (ej. "ana" en "mañana").
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: c.wrong) + "\\b"
            // Escapa $ y \ en el reemplazo para que no se interpreten como plantilla regex.
            let repl = c.right
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "$", with: "\\$")
            t = t.replacingOccurrences(of: pattern, with: repl,
                                       options: [.regularExpression, .caseInsensitive])
        }
        return t
    }

    private func copyToSandbox(_ url: URL) throws -> URL {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    private func audioForTranscription(from url: URL) async throws -> URL {
        if supportedAudio.contains(url.pathExtension.lowercased()) {
            return url
        }
        let asset = AVURLAsset(url: url)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "PrensaIA", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No se pudo preparar la extracción de audio."])
        }
        try await exporter.export(to: outputURL, as: .m4a)
        return outputURL
    }
}
