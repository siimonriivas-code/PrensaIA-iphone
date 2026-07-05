//
//  Models.swift
//  PrensaIA
//
//  Modelos de datos, diccionario de correcciones y carga desde la galería.
//

import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers
import FoundationModels

// MARK: - Modelos de datos

struct TimedSegment: Identifiable {
    let id = UUID()
    let start: Double
    let end: Double
    var text: String
    var speakerId: Int? = nil
}

struct CleanTurn: Identifiable {
    let id = UUID()
    var speakerId: Int?
    var text: String
}

// Bloque temático sugerido por la IA (para cortes de video).
struct BloqueTema: Identifiable {
    let id = UUID()
    var tema: String
    var inicio: Double   // segundos
    var fin: Double      // segundos
    var resumen: String
}

// MARK: - Diccionario de nombres (correcciones del usuario)

struct Correccion: Codable, Identifiable, Equatable {
    var id = UUID()
    var wrong: String
    var right: String
}

@Observable
final class DiccionarioStore {
    var items: [Correccion] = [] {
        didSet { save() }
    }
    private let key = "prensaia_diccionario"

    init() { load() }

    func add(wrong: String, right: String) {
        let w = wrong.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = right.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty, !r.isEmpty else { return }
        items.append(Correccion(wrong: w, right: r))
    }

    func remove(_ item: Correccion) {
        items.removeAll { $0.id == item.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Correccion].self, from: data) {
            items = decoded
        }
    }
}

@Generable
struct NewsAnalysis {
    @Guide(description: "Resumen claro del contenido en 2 o 3 frases, en español.")
    let resumen: String

    @Guide(description: "Temas principales tratados. Frases cortas en español.")
    let temas: [String]

    @Guide(description: "Entre 2 y 5 frases CORTAS, de una sola oración cada una, textuales del audio, que sirvan como declaración noticiosa citable. Nunca párrafos largos ni el texto completo.")
    let frasesDestacadas: [String]

    @Guide(description: "Posibles titulares periodísticos, atractivos y fieles al contenido, en español.")
    let titulares: [String]
}

// MARK: - Carga de video desde la galería (Photos)

struct MovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "-" + received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return MovieFile(url: copy)
        }
    }
}
