//
//  ContentView+AnalysisCortes.swift
//  PrensaIA
//
//  Pestañas Análisis y Cortes: IA, preguntas, temas manuales y exportación de clips.
//

import SwiftUI
import UIKit

extension ContentView {

    // MARK: Análisis

    @ViewBuilder
    var analysisView: some View {
        VStack(alignment: .leading, spacing: 22) {
            analysisContent
            Divider()
            qaSection
        }
    }

    @ViewBuilder
    var cortesView: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !service.manualBlocks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Mis temas", icon: "hand.point.up.left.fill", count: service.manualBlocks.count)
                    ForEach(service.manualBlocks) { b in bloqueCard(b, manual: true) }
                }
            }
            aiCortesSection
            let all = service.manualBlocks + (service.blocks ?? [])
            if !all.isEmpty, service.playbackURL != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Toca un bloque para previsualizar solo ese fragmento. Marca el círculo de los que quieras exportar como \(service.isVideo ? "video" : "audio").")
                        .font(.caption).foregroundStyle(.secondary)
                    clipExportBar(all)
                }
            } else if service.manualBlocks.isEmpty, case .idle = service.blocksState {
                Text("¿Quieres marcar tus propios temas? Ve a la pestaña “Por minuto” y toca “Marcar tema”.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    var aiCortesSection: some View {
        switch service.blocksState {
        case .idle:
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Sugeridos por la IA", icon: "sparkles")
                Text("La IA divide la entrevista en bloques por tema, con el minuto donde empieza y termina cada uno. Útil para encontrar tus cortes de video.")
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    selectedBlockIDs = []
                    Task { await service.suggestBlocks() }
                } label: {
                    Label("Sugerir cortes por tema", systemImage: "scissors")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(.brand).interactive(),
                                     in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        case .running:
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Sugeridos por la IA", icon: "sparkles")
                if isAIDownloading {
                    aiDownloadRow
                } else {
                    loadingRow(service.blocksProgress > 0
                        ? "Buscando cortes… \(Int(service.blocksProgress * 100))%"
                        : "Buscando bloques por tema…")
                }
            }
        case .failed(let msg):
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Sugeridos por la IA", icon: "sparkles")
                Text(msg).font(.callout).foregroundStyle(.secondary)
                Button("Intentar de nuevo") { Task { await service.suggestBlocks() } }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.brand)
            }
        case .done:
            if let bloques = service.blocks, !bloques.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Sugeridos por la IA", icon: "sparkles", count: bloques.count)
                    ForEach(bloques) { b in bloqueCard(b, manual: false) }
                    Button {
                        selectedBlockIDs = []
                        Task { await service.suggestBlocks() }
                    } label: {
                        Label("Volver a sugerir", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.brand)
                }
            } else {
                Text("No se identificaron bloques.").font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    func sectionHeader(_ title: String, icon: String, count: Int? = nil) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.brand)
            Text(title.uppercased())
                .font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(.brand)
            if let count { Text("(\(count))").font(.caption2.weight(.bold)).foregroundStyle(.secondary) }
            Spacer()
        }
    }

    // MARK: Temas manuales (el usuario marca inicio/fin en "Por minuto")

    var manualRange: (Double, Double)? {
        guard let s = manualStart, let e = manualEnd else { return nil }
        return (min(s, e), max(s, e))
    }

    func handleManualTap(_ seg: TimedSegment) {
        if manualStart == nil {
            manualStart = seg.start
            manualEnd = nil
        } else if manualEnd == nil {
            if seg.end >= (manualStart ?? 0) {
                manualEnd = seg.end
            } else {
                manualEnd = manualStart
                manualStart = seg.start
            }
        } else {
            manualStart = seg.start
            manualEnd = nil
        }
    }

    func segIsInManualRange(_ seg: TimedSegment) -> Bool {
        guard manualMode else { return false }
        if let (s, e) = manualRange {
            return seg.start >= s - 0.01 && seg.end <= e + 0.01
        }
        if let s = manualStart {
            return abs(seg.start - s) < 0.01
        }
        return false
    }

    func saveManualTopic() {
        guard let (s, e) = manualRange else { return }
        let name = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tema = name.isEmpty ? "Tema \(service.manualBlocks.count + 1)" : name
        service.manualBlocks.append(BloqueTema(tema: tema, inicio: s, fin: e, resumen: ""))
        persistManualBlocks()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()   // confirmación al tacto
        // Deja listo para marcar el siguiente sin salir del modo.
        manualStart = nil
        manualEnd = nil
        manualName = ""
    }

    func cancelManual() {
        manualStart = nil
        manualEnd = nil
        manualName = ""
        manualMode = false
    }

    func deleteManual(_ b: BloqueTema) {
        service.manualBlocks.removeAll { $0.id == b.id }
        selectedBlockIDs.remove(b.id)
        persistManualBlocks()
    }

    func persistManualBlocks() {
        guard let id = service.currentSavedID else { return }
        let saved = service.manualBlocks.map {
            SavedBloque(tema: $0.tema, inicio: $0.inicio, fin: $0.fin, resumen: $0.resumen)
        }
        history.updateManualBlocks(id: id, blocks: saved)
    }

    func toggleBlockSelection(_ id: UUID) {
        if selectedBlockIDs.contains(id) {
            selectedBlockIDs.remove(id)
        } else {
            selectedBlockIDs.insert(id)
        }
    }

    func bloqueCard(_ b: BloqueTema, manual: Bool) -> some View {
        let selected = selectedBlockIDs.contains(b.id)
        let card = Button {
            player.playRange(b.inicio, b.fin)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(b.tema).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(manual ? "MÍO" : "IA")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(manual ? Color.brand.opacity(0.15) : Color.orange.opacity(0.18), in: Capsule())
                        .foregroundStyle(manual ? Color.brand : Color.orange)
                    Image(systemName: "play.circle.fill").font(.title3).foregroundStyle(.brand)
                }
                Text("\(timeLabel(b.inicio)) – \(timeLabel(b.fin))")
                    .font(.caption.weight(.semibold)).foregroundStyle(.brand)
                if !b.resumen.isEmpty {
                    Text(b.resumen).font(.callout).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.brand.opacity(0.10) : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Color.brand.opacity(0.5) : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)

        return HStack(alignment: .top, spacing: 10) {
            Button {
                toggleBlockSelection(b.id)
            } label: {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.brand : Color.secondary)
                    .padding(.top, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selected ? "Quitar corte de la selección" : "Seleccionar corte para exportar")

            if manual {
                card.contextMenu {
                    Button(role: .destructive) { deleteManual(b) } label: {
                        Label("Eliminar tema", systemImage: "trash")
                    }
                }
            } else {
                card
            }
        }
    }

    // Barra inferior de la pestaña Cortes: selección masiva + exportar como clip(s).
    @ViewBuilder
    func clipExportBar(_ bloques: [BloqueTema]) -> some View {
        let selectedCount = bloques.filter { selectedBlockIDs.contains($0.id) }.count
        if isExportingClips {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: clipExportProgress)
                    .tint(.brand)
                Text("Exportando cortes… \(Int(clipExportProgress * 100))%")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else {
            VStack(spacing: 10) {
                HStack {
                    Button {
                        if selectedCount == bloques.count {
                            selectedBlockIDs = []
                        } else {
                            selectedBlockIDs = Set(bloques.map { $0.id })
                        }
                    } label: {
                        Text(selectedCount == bloques.count ? "Quitar todo" : "Seleccionar todo")
                            .font(.caption.weight(.semibold)).foregroundStyle(.brand)
                    }
                    Spacer()
                    if selectedCount > 0 {
                        Text("\(selectedCount) seleccionado\(selectedCount == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Menu {
                    Button {
                        exportClips(bloques, merge: false)
                    } label: {
                        Label(service.isVideo ? "Exportar como videos separados" : "Exportar como audios separados",
                              systemImage: "square.and.arrow.up")
                    }
                    Button {
                        exportClips(bloques, merge: true)
                    } label: {
                        Label(service.isVideo ? "Unir en un solo video" : "Unir en un solo audio",
                              systemImage: "film.stack")
                    }
                } label: {
                    Label(selectedCount == 0 ? "Exporta los cortes seleccionados" : "Exportar \(selectedCount) corte\(selectedCount == 1 ? "" : "s")",
                          systemImage: "scissors")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(selectedCount == 0 ? Color.brand.opacity(0.35) : Color.brand).interactive(),
                                     in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
                .disabled(selectedCount == 0)
            }
            .padding(.top, 6)
        }
    }

    func exportClips(_ bloques: [BloqueTema], merge: Bool) {
        let chosen = bloques.filter { selectedBlockIDs.contains($0.id) }
        guard let media = service.playbackURL, !chosen.isEmpty else { return }
        let isVideo = service.isVideo
        isExportingClips = true
        clipExportProgress = 0
        Task { @MainActor in
            let urls: [URL]
            if merge {
                if let u = await MediaClipExporter.exportMerged(media: media, blocks: chosen, isVideo: isVideo) {
                    urls = [u]
                } else {
                    urls = []
                }
                clipExportProgress = 1
            } else {
                urls = await MediaClipExporter.exportSeparate(media: media, blocks: chosen, isVideo: isVideo) { p in
                    Task { @MainActor in clipExportProgress = p }
                }
            }
            isExportingClips = false
            if urls.isEmpty {
                clipExportFailed = true
            } else {
                exportedClipURLs = urls
                showClipShare = true
            }
        }
    }

    var qaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "questionmark.bubble").font(.caption2).foregroundStyle(.brand)
                Text("PREGÚNTALE A ESTA ENTREVISTA")
                    .font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(.brand)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ej. ¿Qué dijo sobre el presupuesto?", text: $qaQuestion, axis: .vertical)
                    .font(.callout)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .lineLimit(1...4)
                Button {
                    askQuestion()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(qaTrimmedEmpty ? Color.secondary : Color.brand)
                }
                .disabled(qaTrimmedEmpty || service.qaState == .running)
            }
            switch service.qaState {
            case .running:
                if isAIDownloading { aiDownloadRow } else { loadingRow("Pensando…") }
            case .failed(let msg):
                Text(msg).font(.callout).foregroundStyle(.secondary)
            case .done:
                if let ans = service.qaAnswer {
                    Text(ans)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                }
            case .idle:
                Text("La IA responde solo con lo que se dijo en el audio.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    var qaTrimmedEmpty: Bool {
        qaQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func askQuestion() {
        let q = qaQuestion
        Task { await service.ask(q) }
    }

    @ViewBuilder
    var analysisContent: some View {
        switch service.analysisState {
        case .running:
            if isAIDownloading { aiDownloadRow } else { loadingRow("Analizando el contenido con IA…") }
        case .failed(let msg):
            Text(msg).font(.callout).foregroundStyle(.secondary)
        case .idle:
            loadingRow("Preparando análisis…")
        case .done:
            if let a = service.analysis {
                VStack(alignment: .leading, spacing: 20) {
                    analysisBlock("Resumen", icon: "text.alignleft") {
                        Text(a.resumen).font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !a.temas.isEmpty {
                        analysisBlock("Temas principales", icon: "tag") { bullets(a.temas) }
                    }
                    if !a.frasesDestacadas.isEmpty {
                        analysisBlock("Frases textuales (verificadas)", icon: "quote.opening") { quoteList(a.frasesDestacadas) }
                    }
                    if !a.titulares.isEmpty {
                        analysisBlock("Titulares sugeridos", icon: "newspaper") { headlineList(a.titulares) }
                    }
                    Text("Verifica las citas con la grabación antes de publicar.")
                        .font(.caption).foregroundStyle(.secondary).padding(.top, 2)
                }
            } else {
                Text("El análisis aparecerá aquí.").font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    func analysisBlock<C: View>(_ title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.caption2).foregroundStyle(.brand)
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.brand)
            }
            content()
        }
    }

    func bullets(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(Color.brand).frame(width: 5, height: 5).padding(.top, 7)
                    Text(item).font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func quoteList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.brand.opacity(0.45)).frame(width: 3)
                    Text(item).font(.callout).italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func headlineList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(.callout, design: .serif).weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func loadingRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(text).font(.callout).foregroundStyle(.secondary)
        }
    }

    // True cuando el modelo de IA se está descargando (solo la 1ª vez).
    var isAIDownloading: Bool {
        LocalAI.shared.status == .loading
            && LocalAI.shared.downloadProgress > 0
            && LocalAI.shared.downloadProgress < 1
    }

    // Fila con barra de progreso para la descarga única del modelo de IA.
    var aiDownloadRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ProgressView()
                Text("Descargando IA (solo la 1ª vez)…")
                    .font(.callout).foregroundStyle(.secondary)
            }
            ProgressView(value: LocalAI.shared.downloadProgress)
            Text("\(Int(LocalAI.shared.downloadProgress * 100))% — el modelo es grande, puede tardar unos minutos. Después funciona sin internet.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    func timeLabel(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
