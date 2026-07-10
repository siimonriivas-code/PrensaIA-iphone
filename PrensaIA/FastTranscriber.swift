//
//  FastTranscriber.swift
//  PrensaIA
//
//  Motor de transcripción RÁPIDO: Parakeet TDT v3 (0.6B) de NVIDIA, vía FluidAudio.
//  Corre 100% en el dispositivo sobre el Neural Engine (ANE): muy veloz y casi no
//  usa memoria de GPU. Soporta español. El modelo (~600 MB) se descarga UNA vez
//  y queda en caché, igual que Qwen.
//
//  REGLA DE AISLAMIENTO: este archivo es la ÚNICA puerta de la app hacia
//  FluidAudio. Nadie más debe importar FluidAudio.
//
//  REGLA DE MEMORIA: nunca debe estar cargado a la vez que WhisperKit.
//  TranscriptionService se encarga de descargar uno antes de cargar el otro.
//

import Foundation
import AVFoundation
import FluidAudio

@MainActor
@Observable
final class FastTranscriber {
    static let shared = FastTranscriber()
    private init() {}

    enum Status: Equatable { case idle, loading, ready, failed }
    private(set) var status: Status = .idle
    private(set) var downloadProgress: Double = 0

    private var manager: AsrManager?

    var isReady: Bool { status == .ready }

    enum FastError: LocalizedError {
        case notLoaded
        var errorDescription: String? { "El motor rápido no está listo." }
    }

    /// Carga (o descarga la 1ª vez) el modelo Parakeet. Devuelve true si quedó listo.
    @discardableResult
    func ensureLoaded() async -> Bool {
        if status == .ready { return true }
        status = .loading
        do {
            // Descarga una sola vez; después carga desde caché (sin internet).
            downloadProgress = 0
            let models = try await AsrModels.downloadAndLoad(version: .v3) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress = progress.fractionCompleted
                }
            }
            downloadProgress = 1
            let m = AsrManager(config: .default)
            try await m.loadModels(models)
            manager = m
            status = .ready
            return true
        } catch {
            manager = nil
            status = .failed
            return false
        }
    }

    /// Libera el motor por completo (ley de memoria).
    func unload() {
        manager = nil
        status = .idle
    }

    // MARK: - Transcripción EN VIVO (tiempo real, Parakeet)
    //
    // Parakeet trae streaming de verdad (SlidingWindowAsrManager, estilo
    // SpeechAnalyzer de Apple): entrega texto "provisional" (volatile) en ~1-2 s
    // y lo va "confirmando" cuando junta suficiente contexto. Todo en el Neural
    // Engine. Nosotros capturamos el micrófono con AVAudioEngine y le pasamos el
    // audio; el manager devuelve actualizaciones que la app pinta en pantalla.

    private var liveManager: SlidingWindowAsrManager?
    private var liveEngine: AVAudioEngine?
    private var liveFeedTask: Task<Void, Never>?
    private var liveUpdatesTask: Task<Void, Never>?
    private var liveMicContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?

    /// Arranca el dictado en vivo con Parakeet.
    /// - Parameter onUpdate: se llama en el hilo principal por cada actualización:
    ///   `(texto, esConfirmado)`. Confirmado = pedazo estable (acumúlalo);
    ///   no confirmado = hipótesis provisional (reemplázala).
    func startLiveStream(onUpdate: @escaping @MainActor (String, Bool) -> Void) async throws {
        // Ley de memoria: soltar el motor de archivos antes de abrir el de streaming.
        manager = nil

        // Cargar Parakeet (descarga sólo la 1ª vez; luego desde caché, sin internet).
        let mgr = SlidingWindowAsrManager(config: .streaming)
        let models = try await AsrModels.downloadAndLoad(version: .v3)
        try await mgr.loadModels(models)
        try await mgr.startStreaming(source: .microphone)
        liveManager = mgr
        status = .ready

        // Consumir las actualizaciones del motor y avisarle a la app.
        liveUpdatesTask = Task { [weak self] in
            for await update in await mgr.transcriptionUpdates {
                if Task.isCancelled { break }
                onUpdate(update.text, update.isConfirmed)
            }
            _ = self
        }

        // Puente micrófono → motor: un AsyncStream serializa los buffers en orden.
        let (micStream, micCont) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        liveMicContinuation = micCont
        liveFeedTask = Task {
            for await buffer in micStream {
                await mgr.streamAudio(buffer)
            }
        }

        // Sesión de audio para grabar. Modo .measurement = audio crudo sin
        // procesamiento del sistema (mejor para reconocimiento). Sin opciones de
        // Bluetooth: usa el micrófono del iPhone (ideal para captar a la persona
        // entrevistada, no el del audífono, que es solo de escucha).
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            // El tap reutiliza el buffer: hay que copiarlo antes de encolarlo.
            if let copy = Self.copyBuffer(buffer) {
                micCont.yield(copy)
            }
        }
        engine.prepare()
        try engine.start()
        liveEngine = engine
    }

    /// Detiene el dictado en vivo y devuelve el texto final completo.
    func stopLiveStream() async -> String {
        liveEngine?.inputNode.removeTap(onBus: 0)
        liveEngine?.stop()
        liveEngine = nil

        // Cerrar la entrada de audio y ESPERAR a que los últimos buffers capturados
        // lleguen al motor, para no cortar la última palabra.
        liveMicContinuation?.finish()
        liveMicContinuation = nil
        await liveFeedTask?.value
        liveFeedTask = nil

        // finish() procesa lo pendiente y devuelve la transcripción completa.
        var finalText = ""
        if let mgr = liveManager {
            finalText = (try? await mgr.finish()) ?? ""
        }

        liveUpdatesTask?.cancel()
        liveUpdatesTask = nil
        liveManager = nil
        status = .idle

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return finalText
    }

    /// Copia profunda de un buffer de audio (el tap del micrófono lo reutiliza).
    nonisolated private static func copyBuffer(_ b: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: b.format, frameCapacity: b.frameCapacity) else {
            return nil
        }
        copy.frameLength = b.frameLength
        let channels = Int(b.format.channelCount)
        let frames = Int(b.frameLength)
        if let src = b.floatChannelData, let dst = copy.floatChannelData {
            for ch in 0..<channels { memcpy(dst[ch], src[ch], frames * MemoryLayout<Float>.size) }
        } else if let src = b.int16ChannelData, let dst = copy.int16ChannelData {
            for ch in 0..<channels { memcpy(dst[ch], src[ch], frames * MemoryLayout<Int16>.size) }
        } else if let src = b.int32ChannelData, let dst = copy.int32ChannelData {
            for ch in 0..<channels { memcpy(dst[ch], src[ch], frames * MemoryLayout<Int32>.size) }
        }
        return copy
    }

    /// ¿El cerebro del motor Rápido ya está descargado en el teléfono?
    /// (Para mostrar en Ajustes si hace falta descargarlo o ya está listo offline.)
    var isDownloaded: Bool {
        let dir = AsrModels.defaultCacheDirectory(for: .v3)
        return AsrModels.modelsExist(at: dir, version: .v3)
    }

    /// Descarga anticipada del modelo (desde Ajustes), para que el usuario lo
    /// baje con calma en WiFi y no le agarre a media urgencia. Solo descarga;
    /// no lo deja cargado en memoria (respeta la ley de memoria).
    @discardableResult
    func predownload() async -> Bool {
        if isDownloaded { return true }
        status = .loading
        downloadProgress = 0
        do {
            _ = try await AsrModels.download(version: .v3) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress = progress.fractionCompleted
                }
            }
            downloadProgress = 1
            status = .idle   // descargado pero sin cargar en memoria
            return true
        } catch {
            status = .idle
            return false
        }
    }

    /// Transcribe un archivo de audio y devuelve el texto completo más los
    /// segmentos con marcas de tiempo, listos para el pipeline de la app
    /// (pestaña "Por minuto", reproductor, oradores, cortes).
    func transcribe(url: URL) async throws -> (text: String, segments: [TimedSegment]) {
        guard let manager else { throw FastError.notLoaded }
        var state = try TdtDecoderState()
        // El hint de idioma ayuda al modelo v3 a favorecer tokens en español.
        let result = try await manager.transcribe(url, decoderState: &state, language: .spanish)
        let segments = Self.buildSegments(
            from: result.tokenTimings ?? [],
            fullText: result.text,
            duration: result.duration
        )
        return (result.text, segments)
    }

    // MARK: Agrupar tokens en frases con tiempos

    /// Parakeet entrega tiempos por TOKEN (pedacitos de palabra, estilo
    /// SentencePiece: "▁" marca inicio de palabra). Aquí se agrupan en frases
    /// de tamaño legible: se corta en pausas largas, al final de una oración,
    /// o al superar ~14 segundos, imitando los segmentos de Whisper.
    private static func buildSegments(
        from timings: [TokenTiming],
        fullText: String,
        duration: TimeInterval
    ) -> [TimedSegment] {
        guard !timings.isEmpty else {
            let t = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? [] : [TimedSegment(start: 0, end: max(duration, 1), text: t)]
        }

        var segments: [TimedSegment] = []
        var current = ""
        var segStart: TimeInterval = timings[0].startTime
        var lastEnd: TimeInterval = timings[0].startTime

        func closeSegment() {
            let text = current
                .replacingOccurrences(of: "▁", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                segments.append(TimedSegment(start: segStart, end: max(lastEnd, segStart + 0.1), text: text))
            }
            current = ""
        }

        for timing in timings {
            let gap = timing.startTime - lastEnd
            let length = timing.startTime - segStart

            // Pausa larga o segmento ya muy largo: cerrar antes de seguir.
            if !current.isEmpty && (gap > 0.8 || length > 14) {
                closeSegment()
                segStart = timing.startTime
            }
            if current.isEmpty { segStart = timing.startTime }

            current += timing.token
            lastEnd = timing.endTime

            // Fin de oración con tamaño razonable: buen punto de corte.
            if current.count > 60, let last = current.trimmingCharacters(in: .whitespaces).last,
               ".!?…".contains(last) {
                closeSegment()
                segStart = lastEnd
            }
        }
        closeSegment()
        return segments
    }
}
