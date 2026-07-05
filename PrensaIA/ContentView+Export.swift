//
//  ContentView+Export.swift
//  PrensaIA
//
//  Exportación de cada pestaña: texto, PDF y encabezados.
//

import SwiftUI
import UIKit

extension ContentView {

    // MARK: Exportar (según la pestaña activa)

    func exportForCurrentTab() -> String {
        switch tab {
        case .transcript: return exportByMinute()
        case .estenografica: return exportEstenografica()
        case .analysis: return exportAnalysisText()
        case .cortes: return exportCortesText()
        }
    }

    func exportCortesText() -> String {
        var out = ""
        if !service.manualBlocks.isEmpty {
            out += "MIS TEMAS\n\n"
            for (i, b) in service.manualBlocks.enumerated() {
                out += "\(i + 1). \(b.tema)  [\(timeLabel(b.inicio)) – \(timeLabel(b.fin))]\n"
                if !b.resumen.isEmpty { out += "   \(b.resumen)\n" }
                out += "\n"
            }
        }
        if let bloques = service.blocks, !bloques.isEmpty {
            out += "CORTES SUGERIDOS POR LA IA\n\n"
            for (i, b) in bloques.enumerated() {
                out += "\(i + 1). \(b.tema)  [\(timeLabel(b.inicio)) – \(timeLabel(b.fin))]\n"
                if !b.resumen.isEmpty { out += "   \(b.resumen)\n" }
                out += "\n"
            }
        }
        return out.isEmpty ? "Aún no hay cortes ni temas marcados." : out
    }

    func exportPDF() -> URL? {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        f.locale = Locale(identifier: "es_MX")
        return PDFMaker.make(
            title: titleFor(service.transcript),
            dateText: f.string(from: Date()),
            body: pdfBody()
        )
    }

    func pdfBody() -> String {
        if showCleaned, let cleaned = service.cleanedTurns {
            return cleaned.map { turn -> String in
                let head = turn.speakerId.map { speakerName($0).uppercased() + "\n" } ?? ""
                return head + turn.text
            }.joined(separator: "\n\n")
        }
        let turns = speakerTurns()
        if turns.isEmpty { return service.transcript }
        return turns.map { turn -> String in
            let head = turn.speakerId.map { speakerName($0).uppercased() + "\n" } ?? ""
            return head + turn.paragraphs.joined(separator: "\n\n")
        }.joined(separator: "\n\n")
    }

    func exportHeader() -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        f.locale = Locale(identifier: "es_MX")
        return "PrensaIA — \(titleFor(service.transcript))\n\(f.string(from: Date()))\n\n"
    }

    func exportByMinute() -> String {
        var out = exportHeader() + "TRANSCRIPCIÓN (por minuto)\n\n"
        if service.segments.isEmpty {
            out += service.transcript + "\n"
        } else {
            for s in service.segments {
                let who = s.speakerId.map { speakerName($0) + ": " } ?? ""
                out += "[\(timeLabel(s.start))] \(who)\(s.text)\n"
            }
        }
        return out
    }

    func exportEstenografica() -> String {
        var out = exportHeader() + "VERSIÓN ESTENOGRÁFICA\n\n"
        let turns = speakerTurns()
        if turns.isEmpty {
            out += service.transcript + "\n"
        } else {
            for turn in turns {
                if let sid = turn.speakerId {
                    out += speakerName(sid).uppercased() + "\n"
                }
                out += turn.paragraphs.joined(separator: "\n\n") + "\n\n"
            }
        }
        return out
    }

    func exportAnalysisText() -> String {
        var out = exportHeader() + "ANÁLISIS\n\n"
        if let a = service.analysis {
            out += "Resumen: \(a.resumen)\n"
            if !a.temas.isEmpty {
                out += "\nTemas principales:\n" + a.temas.map { "• \($0)" }.joined(separator: "\n") + "\n"
            }
            if !a.frasesDestacadas.isEmpty {
                out += "\nFrases destacadas:\n" + a.frasesDestacadas.map { "• \($0)" }.joined(separator: "\n") + "\n"
            }
            if !a.titulares.isEmpty {
                out += "\nTitulares sugeridos:\n" + a.titulares.map { "• \($0)" }.joined(separator: "\n") + "\n"
            }
        } else {
            out += "El análisis aún no está disponible.\n"
        }
        return out
    }
}
