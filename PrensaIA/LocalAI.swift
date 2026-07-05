//
//  LocalAI.swift
//  PrensaIA
//
//  Motor de IA local (Qwen 3 de 4B vía MLX).
//  - Si la carpeta del modelo está incluida en la app -> corre 100% sin internet.
//  - Si no, la descarga una sola vez (con internet) y queda en caché para siempre.
//  La app usa este motor desde el servicio; si por algo no estuviera listo,
//  el servicio usa la IA de Apple como respaldo (nunca se rompe).
//
//  Para dejarlo 100% sin internet: incluye en la app una carpeta llamada
//  exactamente  "Qwen3-4B-4bit"  (ver instrucciones del chat).
//

import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
import MLX

@MainActor
@Observable
final class LocalAI {
    static let shared = LocalAI()
    private init() {}

    enum Status: Equatable { case idle, loading, ready, failed }

    private(set) var status: Status = .idle
    var downloadProgress: Double = 0

    private var container: ModelContainer?
    private var loadTask: Task<Bool, Never>?

    var isReady: Bool { status == .ready }

    /// Carpeta del modelo incluida en la app (debe llamarse exactamente "Qwen3-4B-4bit").
    private func bundledModelDirectory() -> URL? {
        Bundle.main.url(forResource: "Qwen3-4B-4bit", withExtension: nil)
    }

    /// Carga el modelo si hace falta. Devuelve true si quedó listo.
    @discardableResult
    func ensureLoaded() async -> Bool {
        if status == .ready { return true }
        if let loadTask { return await loadTask.value }
        let task = Task { await self.performLoad() }
        loadTask = task
        let ok = await task.value
        if !ok { loadTask = nil }   // permite reintentar si falló
        return ok
    }

    private func performLoad() async -> Bool {
        status = .loading
        downloadProgress = 0

        // Limitar la caché de memoria de la IA a 20 MB (recomendado para iPhone).
        // Evita que la memoria se acumule y que iOS cierre la app en videos largos.
        MLX.Memory.cacheLimit = 20 * 1024 * 1024

        // 1. Modelo incluido en la app (100% sin internet).
        if let dir = bundledModelDirectory(),
           let c = try? await LLMModelFactory.shared.loadContainer(
               from: dir, using: #huggingFaceTokenizerLoader()
           ) {
            container = c
            status = .ready
            return true
        }

        // 2. Descargar (solo la 1ª vez; luego queda en caché y corre sin internet).
        do {
            let c = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.qwen3_4b_4bit
            ) { p in
                Task { @MainActor in self.downloadProgress = p.fractionCompleted }
            }
            container = c
            status = .ready
            return true
        } catch {
            status = .failed
            return false
        }
    }

    /// Genera una respuesta de texto. Devuelve nil si no hay modelo o falla
    /// (para que el servicio use el respaldo de Apple).
    func respond(system: String, user: String, maxTokens: Int = 900) async -> String? {
        guard let container else { return nil }
        let session = ChatSession(container, instructions: system)
        var params = GenerateParameters()
        params.maxTokens = maxTokens
        session.generateParameters = params
        let reply = try? await session.respond(to: user)
        guard let reply,
              !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return reply
    }

    /// Libera la memoria temporal de la IA (útil entre partes de un video largo).
    func clearCache() {
        MLX.Memory.clearCache()
    }
}
