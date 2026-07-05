//
//  ContentView+Sheets.swift
//  PrensaIA
//
//  Hojas de diccionario e historial, edición y selector de pestañas.
//

import SwiftUI

extension ContentView {

    var diccionarioSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text("Whisper a veces escribe mal nombres propios (políticos, lugares, dependencias). Aquí le dices cómo lo escribe mal y cómo debe quedar; se corrige solo en cada transcripción.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Section("Agregar corrección") {
                    TextField("Como sale (ej. Bizcaino)", text: $nuevoMal)
                        .autocorrectionDisabled()
                    TextField("Correcto (ej. Vizcaíno)", text: $nuevoBien)
                        .autocorrectionDisabled()
                    Button {
                        diccionario.add(wrong: nuevoMal, right: nuevoBien)
                        nuevoMal = ""
                        nuevoBien = ""
                    } label: {
                        Label("Agregar al diccionario", systemImage: "plus.circle.fill")
                    }
                    .disabled(
                        nuevoMal.trimmingCharacters(in: .whitespaces).isEmpty ||
                        nuevoBien.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
                if diccionario.items.isEmpty {
                    Section {
                        Text("Aún no tienes correcciones. Agrega los nombres que más usas en tu cobertura.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } else {
                    Section("Mis correcciones (\(diccionario.items.count))") {
                        ForEach(diccionario.items) { item in
                            HStack(spacing: 8) {
                                Text(item.wrong).foregroundStyle(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.caption2).foregroundStyle(.tertiary)
                                Text(item.right).fontWeight(.medium)
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { diccionario.items[$0] }
                            for item in toDelete { diccionario.remove(item) }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackdrop() }
            .navigationTitle("Diccionario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showDiccionario = false }
                }
            }
        }
    }

    var historySheet: some View {
        NavigationStack {
            List {
                if history.items.isEmpty {
                    Section {
                        Text("Aún no tienes transcripciones guardadas. Cada transcripción que termines se guardará aquí.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } else if filteredHistory.isEmpty {
                    Section {
                        Text("Sin resultados para “\(historySearch)”.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } else {
                    Section("Transcripciones") {
                        ForEach(filteredHistory) { item in
                            Button {
                                loadItem(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    HStack(spacing: 10) {
                                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                        if item.analysis != nil {
                                            Label("Con análisis", systemImage: "sparkles")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { filteredHistory[$0] }
                            for item in toDelete { history.delete(item) }
                        }
                    }
                }

                Section("Almacenamiento") {
                    HStack {
                        Label("Audio y video guardados", systemImage: "play.rectangle.on.rectangle")
                        Spacer()
                        Text(storageString(history.audioBytes()))
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        history.clearAllAudio()
                    } label: {
                        Label("Borrar archivos guardados", systemImage: "trash")
                    }
                    Button(role: .destructive) {
                        service.clearDownloadedModel()
                    } label: {
                        Label("Borrar modelo de IA (~700 MB)", systemImage: "arrow.down.circle.dotted")
                    }
                    Text("Borrar los archivos libera espacio (los textos se conservan, pero ya no podrás reproducir ni cortar las grabaciones viejas). El modelo se vuelve a descargar con internet la próxima vez que transcribas.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Motor de transcripción") {
                    Picker("Motor", selection: $engineRaw) {
                        Text("Preciso").tag("whisper")
                        Text("Rápido").tag("fast")
                    }
                    .pickerStyle(.segmented)
                    Text(engineRaw == "fast"
                         ? "Rápido (Parakeet): transcribe en segundos usando el chip de IA del iPhone. La 1ª vez descarga un modelo (~600 MB, una sola vez). Ojo: la transcripción en vivo y “leer casi en vivo” siguen usando el motor Preciso."
                         : "Preciso (Whisper): el motor de siempre, máxima calidad de texto. Si un video largo te urge, prueba el Rápido y compara.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Apariencia") {
                    Picker("Tema", selection: $themeRaw) {
                        Text("Sistema").tag("system")
                        Text("Claro").tag("light")
                        Text("Oscuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackdrop() }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $historySearch, prompt: "Buscar en transcripciones")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !history.items.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showHistory = false }
                }
            }
        }
    }

    var filteredHistory: [SavedTranscription] {
        let q = historySearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return history.items }
        return history.items.filter {
            $0.title.lowercased().contains(q) || $0.transcript.lowercased().contains(q)
        }
    }

    func storageString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var editingView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Corrige el texto si hace falta. Los tiempos y el audio se conservan.")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(service.segments.enumerated()), id: \.element.id) { index, seg in
                VStack(alignment: .leading, spacing: 5) {
                    Text(timeLabel(seg.start))
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(.brand)
                    TextField("Texto", text: Binding(
                        get: { service.segments[index].text },
                        set: { service.segments[index].text = $0 }
                    ), axis: .vertical)
                        .font(.callout)
                        .padding(10)
                        .background(.thinMaterial,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(ResultTab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.smooth(duration: 0.25)) { tab = t }
                } label: {
                    HStack(spacing: 5) {
                        Text(t.rawValue)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if t == .analysis, service.analysisState == .running {
                            ProgressView().controlSize(.mini)
                        }
                        if t == .cortes, service.blocksState == .running {
                            ProgressView().controlSize(.mini)
                        }
                    }
                    .foregroundStyle(tab == t ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 4)
                    .background {
                        if tab == t {
                            // Píldora de cristal líquido entintado (iOS 26).
                            Color.clear
                                .glassEffect(.regular.tint(.brand).interactive(),
                                             in: Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
