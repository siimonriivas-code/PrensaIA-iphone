//
//  HistoryStore.swift
//  PrensaIA
//
//  Historial de transcripciones guardado en el dispositivo.
//

import SwiftUI
import OSLog

// MARK: - Historial (guardado en el dispositivo)

struct AnalysisResult: Codable {
    var resumen: String
    var temas: [String]
    var frasesDestacadas: [String]
    var titulares: [String]
}

struct SavedSegment: Codable {
    var start: Double
    var end: Double
    var text: String
    var speakerId: Int?
}

struct SavedBloque: Codable {
    var tema: String
    var inicio: Double
    var fin: Double
    var resumen: String
}

struct SavedTranscription: Codable, Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var transcript: String
    var segments: [SavedSegment]
    var analysis: AnalysisResult?
    var audioFileName: String?
    var speakerNames: [Int: String]?
    var isVideo: Bool?
    var manualBlocks: [SavedBloque]? = nil
}

@MainActor
@Observable
final class HistoryStore {
    var items: [SavedTranscription] = []

    private let indexURL: URL
    private let audioDir: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        indexURL = docs.appendingPathComponent("prensaia_historial.json")
        audioDir = docs.appendingPathComponent("PrensaIAAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([SavedTranscription].self, from: data) else { return }
        items = decoded.sorted { $0.date > $1.date }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            // No interrumpe al usuario, pero deja rastro para diagnóstico.
            Logger(subsystem: "com.simonrivas.PrensaIA", category: "historial")
                .error("No se pudo guardar el historial: \(error.localizedDescription)")
        }
    }

    func audioURL(for item: SavedTranscription) -> URL? {
        guard let name = item.audioFileName else { return nil }
        let url = audioDir.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    func add(title: String, transcript: String, segments: [SavedSegment], speakerNames: [Int: String], sourceAudio: URL?, isVideo: Bool) -> UUID {
        let id = UUID()
        var audioName: String?
        if let src = sourceAudio {
            let ext = src.pathExtension.isEmpty ? "m4a" : src.pathExtension
            let dest = audioDir.appendingPathComponent("\(id.uuidString).\(ext)")
            try? FileManager.default.removeItem(at: dest)
            if (try? FileManager.default.copyItem(at: src, to: dest)) != nil {
                audioName = dest.lastPathComponent
            }
        }
        let item = SavedTranscription(id: id, title: title, date: Date(),
                                      transcript: transcript, segments: segments,
                                      analysis: nil, audioFileName: audioName,
                                      speakerNames: speakerNames.isEmpty ? nil : speakerNames,
                                      isVideo: isVideo)
        items.insert(item, at: 0)
        persist()
        return id
    }

    func updateAnalysis(id: UUID, analysis: AnalysisResult) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].analysis = analysis
        persist()
    }

    func updateContent(id: UUID, title: String, transcript: String, segments: [SavedSegment]) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].title = title
        items[i].transcript = transcript
        items[i].segments = segments
        persist()
    }

    func updateSpeakerNames(id: UUID, speakerNames: [Int: String]) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].speakerNames = speakerNames.isEmpty ? nil : speakerNames
        persist()
    }

    func updateManualBlocks(id: UUID, blocks: [SavedBloque]) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].manualBlocks = blocks.isEmpty ? nil : blocks
        persist()
    }

    func delete(_ item: SavedTranscription) {
        if let name = item.audioFileName {
            try? FileManager.default.removeItem(at: audioDir.appendingPathComponent(name))
        }
        items.removeAll { $0.id == item.id }
        persist()
    }

    // MARK: Almacenamiento

    func audioBytes() -> Int64 {
        var total: Int64 = 0
        if let files = try? FileManager.default.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for f in files {
                if let size = try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }

    func clearAllAudio() {
        if let files = try? FileManager.default.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: nil) {
            for f in files { try? FileManager.default.removeItem(at: f) }
        }
        for i in items.indices { items[i].audioFileName = nil }
        persist()
    }
}
