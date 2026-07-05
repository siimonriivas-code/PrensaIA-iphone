//
//  ContentView+Estenografica.swift
//  PrensaIA
//
//  Pestaña Estenográfica: párrafos por orador y limpieza con IA.
//

import SwiftUI

extension ContentView {

    // MARK: Estenográfica (párrafos por orador)

    @ViewBuilder
    var estenograficaView: some View {
        VStack(alignment: .leading, spacing: 16) {
            cleanBar
            if showCleaned, let cleaned = service.cleanedTurns {
                cleanedTurnsView(cleaned)
            } else {
                rawEstenografica
            }
        }
    }

    var cleanBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if service.cleanState == .running {
                if isAIDownloading {
                    aiDownloadRow
                } else {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Limpiando con IA… \(Int(service.cleanProgress * 100))%")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else if service.cleanedTurns != nil {
                HStack(spacing: 10) {
                    Picker("", selection: $showCleaned) {
                        Text("Limpia").tag(true)
                        Text("Original").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                    Spacer()
                    if showCleaned {
                        Label("Revisa antes de publicar", systemImage: "exclamationmark.triangle")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    showCleaned = true
                    Task { await service.cleanTranscript() }
                } label: {
                    Label("Limpiar con IA", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.brand)
                }
                .buttonStyle(.borderless)
                if case .failed(let msg) = service.cleanState {
                    Text(msg).font(.caption).foregroundStyle(.red)
                }
            }
        }
    }

    func cleanedTurnsView(_ cleaned: [CleanTurn]) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(cleaned) { turn in
                VStack(alignment: .leading, spacing: 9) {
                    if let sid = turn.speakerId {
                        HStack(spacing: 6) {
                            Circle().fill(speakerColor(sid)).frame(width: 9, height: 9)
                            Text(speakerName(sid).uppercased())
                                .font(.caption.weight(.bold)).tracking(0.6)
                                .foregroundStyle(speakerColor(sid))
                        }
                    }
                    Text(turn.text)
                        .font(.system(.callout, design: .serif))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    var rawEstenografica: some View {
        let turns = speakerTurns()
        if turns.isEmpty {
            Text(service.transcript)
                .font(.system(.callout, design: .serif))
                .lineSpacing(5)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(turns.enumerated()), id: \.offset) { _, turn in
                    VStack(alignment: .leading, spacing: 9) {
                        if let sid = turn.speakerId {
                            Button {
                                startRename(sid)
                            } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(speakerColor(sid)).frame(width: 9, height: 9)
                                    Text(speakerName(sid).uppercased())
                                        .font(.caption.weight(.bold)).tracking(0.6)
                                        .foregroundStyle(speakerColor(sid))
                                    Image(systemName: "pencil")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(Array(turn.paragraphs.enumerated()), id: \.offset) { _, para in
                            Text(para)
                                .font(.system(.callout, design: .serif))
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .textSelection(.enabled)
        }
    }

    // Agrupa por orador y divide cada intervención en párrafos legibles.
    func speakerTurns() -> [(speakerId: Int?, paragraphs: [String])] {
        var groups: [(speakerId: Int?, text: String)] = []
        for seg in service.segments {
            if let last = groups.last, last.speakerId == seg.speakerId {
                groups[groups.count - 1].text += " " + seg.text
            } else {
                groups.append((speakerId: seg.speakerId, text: seg.text))
            }
        }
        var result: [(speakerId: Int?, paragraphs: [String])] = []
        for g in groups {
            result.append((speakerId: g.speakerId, paragraphs: splitIntoParagraphs(g.text)))
        }
        return result
    }

    func splitIntoParagraphs(_ text: String, target: Int = 300) -> [String] {
        let clean = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard !clean.isEmpty else { return [] }
        var sentences: [String] = []
        clean.enumerateSubstrings(in: clean.startIndex..<clean.endIndex, options: .bySentences) { sub, _, _, _ in
            if let s = sub?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }
        if sentences.isEmpty { return [clean] }
        var paragraphs: [String] = []
        var current = ""
        for s in sentences {
            current += (current.isEmpty ? "" : " ") + s
            if current.count >= target {
                paragraphs.append(current)
                current = ""
            }
        }
        if !current.isEmpty { paragraphs.append(current) }
        return paragraphs
    }
}
