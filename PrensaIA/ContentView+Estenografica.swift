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
                        ProgressView().tint(.brandText)
                        Text("Limpiando con IA… \(Int(service.cleanProgress * 100))%")
                            .font(.display(12.5, .medium)).foregroundStyle(.textTertiary)
                    }
                }
            } else if service.cleanedTurns != nil {
                HStack(spacing: 10) {
                    Picker("", selection: $showCleaned) {
                        Text("Limpia").tag(true)
                        Text("Original").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 190)
                    Spacer()
                    if showCleaned {
                        Label("Revisa antes de publicar", systemImage: "exclamationmark.triangle")
                            .font(.display(11, .medium)).foregroundStyle(.textTertiary)
                    }
                    Button {
                        UIPasteboard.general.string = exportForCurrentTab()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.brandText)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Copiar la estenográfica")
                }
            } else {
                Button {
                    showCleaned = true
                    Task { await service.cleanTranscript() }
                } label: {
                    Label("Limpiar con IA", systemImage: "sparkles")
                        .font(.display(14, .heavy))
                        .foregroundStyle(.brandText)
                }
                .buttonStyle(.borderless)
                if case .failed(let msg) = service.cleanState {
                    Text(msg).font(.display(12, .medium)).foregroundStyle(.liveRed)
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
                                .font(.display(11.5, .heavy)).tracking(0.8)
                                .foregroundStyle(speakerColor(sid))
                        }
                    }
                    Text(turn.text)
                        .font(.serifItalic(16.5, .regular))
                        .lineSpacing(9)
                        .foregroundStyle(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .textSelection(.enabled)
        .card()
    }

    @ViewBuilder
    var rawEstenografica: some View {
        let turns = speakerTurns()
        if turns.isEmpty {
            Text(service.transcript)
                .font(.serifItalic(16.5, .regular))
                .lineSpacing(9)
                .foregroundStyle(.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
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
                                        .font(.display(11.5, .heavy)).tracking(0.8)
                                        .foregroundStyle(speakerColor(sid))
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11)).foregroundStyle(.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(Array(turn.paragraphs.enumerated()), id: \.offset) { _, para in
                            Text(para)
                                .font(.serifItalic(16.5, .regular))
                                .lineSpacing(9)
                                .foregroundStyle(.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .textSelection(.enabled)
            .card()
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
