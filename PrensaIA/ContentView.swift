//
//  ContentView.swift
//  PrensaIA
//
//  Transcripción + análisis periodístico, 100% en el dispositivo (sin internet).
//  Diseño premium con identidad editorial.
//  - Audio y video (Archivos o galería) · español · marcas de tiempo
//  - Toca una frase y el audio salta a ese minuto
//  - Progreso por etapas con porcentaje
//  - Análisis con la IA de Apple (resumen, temas, frases, titulares)
//

import SwiftUI
import PhotosUI
import CoreTransferable
import UniformTypeIdentifiers
import AVFoundation
import AVKit
import ReplayKit
import CoreMedia
import FoundationModels
import UIKit
import CoreText
import Observation
import WhisperKit
import SpeakerKit

// MARK: - Vista principal

struct ContentView: View {
    @State var service = TranscriptionService()
    @State var player = MediaPlayerController()
    @State var waveform: [Float] = []
    @State var selectedBlockIDs: Set<UUID> = []
    @State var isExportingClips = false
    @State var clipExportProgress: Double = 0
    @State var exportedClipURLs: [URL] = []
    @State var showClipShare = false
    @State var clipExportFailed = false
    @State var manualMode = false
    @State var manualStart: Double?
    @State var manualEnd: Double?
    @State var manualName = ""
    @State var showImporter = false
    @State var photoItem: PhotosPickerItem?
    @State var tab: ResultTab = .transcript
    @State var isEditing = false
    @State var history = HistoryStore()
    @State var showHistory = false
    @State var liveCapture = LiveCaptureController()
    @State var showLiveCapture = false
    @State var renamingSpeakerId: Int?
    @State var renameText = ""
    @State var recorder = AudioRecorderController()
    @State var recordDenied = false
    @State var historySearch = ""
    @State var qaQuestion = ""
    @State var showCleaned = false
    @State var pdfURL: URL?
    @State var showPDFShare = false
    @State var diccionario = DiccionarioStore()
    @State var showDiccionario = false
    @State var nuevoMal = ""
    @State var nuevoBien = ""
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var pdfExportFailed = false
    @State var recordFailed = false
    @AppStorage("prensaia_theme") var themeRaw = "system"
    @AppStorage("prensaia_engine") var engineRaw = "whisper"
    @State var fastDownloading = false
    @AppStorage("prensaia_onboarded") var hasOnboarded = false
    @State var showOnboarding = false

    enum ResultTab: String, CaseIterable {
        case transcript = "Por minuto"
        case estenografica = "Estenográfica"
        case analysis = "Análisis"
        case cortes = "Cortes"
    }

    // Colores por orador (se repiten si hay más de 7)
    let speakerPalette: [Color] = [
        Color(red: 0.357, green: 0.310, blue: 0.878),
        Color(red: 0.93, green: 0.42, blue: 0.20),
        Color(red: 0.16, green: 0.61, blue: 0.45),
        Color(red: 0.85, green: 0.26, blue: 0.50),
        Color(red: 0.18, green: 0.52, blue: 0.83),
        Color(red: 0.74, green: 0.53, blue: 0.13),
        Color(red: 0.49, green: 0.40, blue: 0.74)
    ]

    func speakerColor(_ id: Int) -> Color {
        speakerPalette[((id % speakerPalette.count) + speakerPalette.count) % speakerPalette.count]
    }

    func speakerName(_ id: Int) -> String {
        service.speakerNames[id] ?? "Orador \(id + 1)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if service.isLive || service.liveStarting || service.liveDone {
                        liveCard
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if recorder.isRecording {
                        recordingCard
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if service.isBusy {
                        progressCard
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        engineStatusChip
                        actionCard
                    }
                    if service.showsResults {
                        resultsCard
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
                .animation(.smooth(duration: 0.35), value: service.isBusy)
                .animation(.smooth(duration: 0.35), value: service.showsResults)
                .animation(.smooth(duration: 0.35), value: recorder.isRecording)
                .animation(.smooth(duration: 0.35), value: service.isLive)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)   // difumina el contenido bajo la barra (iOS 26)
            .background { AppBackdrop() }
            .navigationBarTitleDisplayMode(.inline)
            .task { await service.prepareModelIfNeeded() }
            .task { service.corrections = diccionario.items }
            .onChange(of: diccionario.items) { _, new in
                service.corrections = new
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.audiovisualContent],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    Task { await service.process(mediaURL: url) }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let movie = try? await newItem.loadTransferable(type: MovieFile.self) {
                        await service.process(mediaURL: movie.url)
                        try? FileManager.default.removeItem(at: movie.url)
                    } else {
                        service.reportPickError()
                    }
                    photoItem = nil
                }
            }
            .onChange(of: service.playbackURL) { _, url in
                cancelManual()
                if let url {
                    player.load(url: url, isVideo: service.isVideo)
                    waveform = []
                    if !service.isVideo {
                        Task {
                            let w = await WaveformLoader.load(url: url)
                            if service.playbackURL == url { waveform = w }
                        }
                    }
                } else {
                    player.stop()
                    waveform = []
                }
            }
            .onChange(of: service.phase) { _, newPhase in
                // Aviso por vibración: útil cuando no estás mirando la pantalla
                // (y no depende del sonido).
                if case .finished = newPhase {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    saveCurrentToHistory()
                } else if case .failed = newPhase {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
            .onChange(of: service.analysisState) { _, newState in
                if case .done = newState, let id = service.currentSavedID, let a = service.analysis {
                    history.updateAnalysis(id: id, analysis: a)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showDiccionario = true
                    } label: {
                        Image(systemName: "character.book.closed")
                    }
                    .accessibilityLabel("Diccionario de correcciones")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // Selector de tema: sistema / claro / oscuro, a un toque.
                    Menu {
                        Picker("Tema", selection: $themeRaw) {
                            Label("Sistema", systemImage: "circle.lefthalf.filled").tag("system")
                            Label("Claro", systemImage: "sun.max").tag("light")
                            Label("Oscuro", systemImage: "moon").tag("dark")
                        }
                    } label: {
                        Image(systemName: themeRaw == "dark" ? "moon.fill"
                              : (themeRaw == "light" ? "sun.max.fill" : "circle.lefthalf.filled"))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel("Cambiar entre modo claro y oscuro")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("Historial de transcripciones")
                }
            }
            .sheet(isPresented: $showDiccionario) {
                diccionarioSheet
            }
            .sheet(isPresented: $showHistory) {
                historySheet
            }
            .sheet(isPresented: $showLiveCapture) {
                liveCaptureSheet
            }
            .onAppear {
                if !hasOnboarded { showOnboarding = true }
            }
            .sheet(isPresented: $showOnboarding, onDismiss: { hasOnboarded = true }) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .alert("No se pudo crear el PDF", isPresented: $pdfExportFailed) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("Inténtalo de nuevo. Si sigue fallando, cierra y abre la app.")
            }
            .alert("No se pudo iniciar la grabación", isPresented: $recordFailed) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("Revisa que ninguna otra app esté usando el micrófono e inténtalo de nuevo.")
            }
            .alert("Nombre del orador", isPresented: Binding(
                get: { renamingSpeakerId != nil },
                set: { if !$0 { renamingSpeakerId = nil } }
            )) {
                TextField("Ej. Francisco", text: $renameText)
                Button("Guardar") { commitRename() }
                Button("Cancelar", role: .cancel) { renamingSpeakerId = nil }
            } message: {
                Text("Se aplicará a todas sus intervenciones en la transcripción.")
            }
        }
        .tint(.brand)
    }

    func startRename(_ id: Int) {
        renamingSpeakerId = id
        renameText = service.speakerNames[id] ?? ""
    }

    func commitRename() {
        guard let id = renamingSpeakerId else { return }
        renamingSpeakerId = nil
        let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            service.speakerNames.removeValue(forKey: id)
        } else if let target = presentSpeakerIds().first(where: {
            $0 != id && speakerName($0).compare(name, options: .caseInsensitive) == .orderedSame
        }) {
            // Ya hay un orador con ese nombre: se fusionan (arregla cuando divide a una persona en dos).
            for i in service.segments.indices where service.segments[i].speakerId == id {
                service.segments[i].speakerId = target
            }
            service.speakerNames.removeValue(forKey: id)
            service.speakerNames[target] = name
        } else {
            service.speakerNames[id] = name
        }
        saveSpeakerState()
    }

    func presentSpeakerIds() -> [Int] {
        var seen: [Int] = []
        for seg in service.segments {
            if let sid = seg.speakerId, !seen.contains(sid) { seen.append(sid) }
        }
        return seen
    }

    func saveSpeakerState() {
        guard let savedID = service.currentSavedID else { return }
        let saved = service.segments.map { SavedSegment(start: $0.start, end: $0.end, text: $0.text, speakerId: $0.speakerId) }
        history.updateContent(id: savedID, title: titleFor(service.transcript),
                              transcript: service.transcript, segments: saved)
        history.updateSpeakerNames(id: savedID, speakerNames: service.speakerNames)
    }

    // MARK: Resultados

    var displayTitle: String {
        let t = service.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || t == "No se detectó voz en el archivo." { return service.currentFileName }
        return String(t.prefix(46)) + (t.count > 46 ? "…" : "")
    }

    var resultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(displayTitle)
                    .font(.system(.headline, design: .serif))
                    .lineLimit(2)
                Spacer()
                if isEditing {
                    Button("Listo") { finishEditing() }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.brand)
                } else {
                    HStack(spacing: 16) {
                        ShareLink(item: exportForCurrentTab()) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3).foregroundStyle(.brand)
                        }
                        .accessibilityLabel("Compartir esta pestaña")
                        Menu {
                            if !service.segments.isEmpty {
                                Button { startEditing() } label: {
                                    Label("Editar transcripción", systemImage: "pencil")
                                }
                            }
                            Button {
                                UIPasteboard.general.string = exportForCurrentTab()
                            } label: {
                                Label("Copiar esta pestaña", systemImage: "doc.on.doc")
                            }
                            Button {
                                if let url = exportPDF() {
                                    pdfURL = url
                                    showPDFShare = true
                                } else {
                                    pdfExportFailed = true
                                }
                            } label: {
                                Label("Exportar a PDF", systemImage: "doc.richtext")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3).foregroundStyle(.brand)
                        }
                        .accessibilityLabel("Más opciones")
                    }
                }
            }

            if isEditing {
                editingView
            } else {
                segmentedControl
                switch tab {
                case .transcript: transcriptView
                case .estenografica: estenograficaView
                case .analysis: analysisView
                case .cortes: cortesView
                }
            }
        }
        .card()
        .animation(.smooth(duration: 0.25), value: tab)
        .animation(.smooth(duration: 0.25), value: isEditing)
        .sheet(isPresented: $showPDFShare) {
            if let pdfURL {
                ActivityView(items: [pdfURL])
            }
        }
        .sheet(isPresented: $showClipShare) {
            ActivityView(items: exportedClipURLs)
        }
        .alert("No se pudieron exportar los cortes", isPresented: $clipExportFailed) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Revisa que el archivo original siga disponible e inténtalo de nuevo.")
        }
    }

    func startEditing() {
        tab = .transcript
        isEditing = true
    }

    func finishEditing() {
        isEditing = false
        service.rebuildTranscriptFromSegments()
        if let id = service.currentSavedID {
            let saved = service.segments.map { SavedSegment(start: $0.start, end: $0.end, text: $0.text, speakerId: $0.speakerId) }
            history.updateContent(id: id, title: titleFor(service.transcript),
                                  transcript: service.transcript, segments: saved)
        }
    }

    func titleFor(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Transcripción" }
        return String(t.prefix(46)) + (t.count > 46 ? "…" : "")
    }

    func saveCurrentToHistory() {
        guard service.currentSavedID == nil else { return }
        guard !service.transcript.isEmpty,
              service.transcript != "No se detectó voz en el archivo." else { return }
        let saved = service.segments.map { SavedSegment(start: $0.start, end: $0.end, text: $0.text, speakerId: $0.speakerId) }
        let id = history.add(title: titleFor(service.transcript),
                             transcript: service.transcript,
                             segments: saved,
                             speakerNames: service.speakerNames,
                             sourceAudio: service.playbackURL,
                             isVideo: service.isVideo)
        service.currentSavedID = id
    }

    func loadItem(_ item: SavedTranscription) {
        isEditing = false
        tab = .transcript
        service.currentSavedID = item.id
        service.transcript = item.transcript
        service.segments = item.segments.map { TimedSegment(start: $0.start, end: $0.end, text: $0.text, speakerId: $0.speakerId) }
        service.speakerNames = item.speakerNames ?? [:]
        service.analysis = item.analysis
        service.analysisState = item.analysis == nil ? .idle : .done
        service.qaAnswer = nil
        service.qaState = .idle
        service.cleanedTurns = nil
        service.cleanState = .idle
        service.blocks = nil
        service.blocksState = .idle
        service.manualBlocks = (item.manualBlocks ?? []).map {
            BloqueTema(tema: $0.tema, inicio: $0.inicio, fin: $0.fin, resumen: $0.resumen)
        }
        selectedBlockIDs = []
        cancelManual()
        qaQuestion = ""
        showCleaned = false
        service.currentFileName = item.title
        service.phase = .finished
        service.isVideo = item.isVideo ?? Self.looksLikeVideo(item.audioFileName)
        service.playbackURL = history.audioURL(for: item)
        showHistory = false
    }

    // Para historial viejo sin la bandera: deduce por la extensión del archivo.
    static func looksLikeVideo(_ fileName: String?) -> Bool {
        guard let ext = fileName?.split(separator: ".").last?.lowercased() else { return false }
        return ["mov", "mp4", "m4v", "avi", "mkv"].contains(ext)
    }
}

#Preview {
    ContentView()
}
