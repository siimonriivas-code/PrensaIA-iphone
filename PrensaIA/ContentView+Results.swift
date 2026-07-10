//
//  ContentView+Results.swift
//  PrensaIA
//
//  Pantalla de Resultados a pantalla completa (push): chrome flotante,
//  bloque de título editorial, segmentado de vidrio pegajoso con thumb
//  vino y mini reproductor flotante que persiste en las 4 pestañas.
//

import SwiftUI

extension ContentView {

    // MARK: Pantalla completa de resultados

    var resultsScreen: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16,
                           pinnedViews: [.sectionHeaders]) {
                    resultsTitleBlock
                        .padding(.horizontal, 18)

                    if isEditing {
                        editingView
                            .padding(.horizontal, 18)
                    } else {
                        Section {
                            Group {
                                switch tab {
                                case .transcript: transcriptView
                                case .estenografica: estenograficaView
                                case .analysis: analysisView
                                case .cortes: cortesView
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                        } header: {
                            // Segmentado pegajoso: se queda arriba al scrollear.
                            resultsSegmented
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.top, 64)   // aire para el chrome flotante
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            resultsChrome
                .padding(.horizontal, 18)
                .padding(.top, 6)
        }
        .background { AppBackdrop() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if !service.segments.isEmpty && !isEditing {
                miniPlayer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
        }
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

    // MARK: Chrome flotante (back · compartir · menú)

    var resultsChrome: some View {
        HStack {
            if isEditing {
                Button {
                    finishEditing()
                } label: {
                    Text("Listo")
                        .font(.display(14, .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.glassProminent)
                .tint(.brand)
            } else {
                Button {
                    showResults = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.brandText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Volver")

                Spacer()

                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        ShareLink(item: exportForCurrentTab()) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.brandText)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
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
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.brandText)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .accessibilityLabel("Más opciones")
                    }
                }
            }
            if isEditing { Spacer() }
        }
    }

    // MARK: Bloque de título editorial

    var resultsTitleBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            PLEyebrow("Cobertura · \(resultsDateText)", icon: "newspaper")
            Text(displayTitle)
                .font(.serifItalic(24, .heavy))
                .foregroundStyle(.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Text(resultsMetaText)
                    .font(.display(12.5, .medium))
            }
            .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var resultsDateText: String {
        let date = history.items.first(where: { $0.id == service.currentSavedID })?.date ?? Date.now
        return date.formatted(.dateTime.day().month(.wide)
            .locale(Locale(identifier: "es_MX")))
    }

    var resultsMetaText: String {
        var parts: [String] = []
        let dur = service.segments.last?.end ?? player.duration
        if dur > 0 { parts.append(timeLabel(dur)) }
        let speakers = presentSpeakerIds().count
        if speakers > 0 { parts.append(speakers == 1 ? "1 orador" : "\(speakers) oradores") }
        parts.append(service.isVideo ? "video" : "audio")
        parts.append(engineRaw == "fast" ? "motor Rápido" : "motor Preciso")
        return parts.joined(separator: " · ")
    }

    // MARK: Segmentado de vidrio (thumb vino deslizante)

    var resultsSegmented: some View {
        HStack(spacing: 0) {
            ForEach(ResultTab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.spring(duration: 0.32)) { tab = t }
                } label: {
                    HStack(spacing: 4) {
                        Text(t.rawValue)
                            .font(.display(12.5, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        if t == .analysis, service.analysisState == .running {
                            ProgressView().controlSize(.mini).tint(.white)
                        }
                        if t == .cortes, service.blocksState == .running {
                            ProgressView().controlSize(.mini).tint(.white)
                        }
                    }
                    .foregroundStyle(tab == t ? .white : .textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background {
                    if tab == t {
                        Capsule()
                            .fill(Color.brand)
                            .matchedGeometryEffect(id: "resultsThumb", in: segmentedNS)
                    }
                }
            }
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule())
    }

    // MARK: Mini reproductor flotante (persiste en las 4 pestañas)

    var miniPlayer: some View {
        HStack(spacing: 12) {
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.brand, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!player.isLoaded)
            .accessibilityLabel(player.isPlaying ? "Pausar" : "Reproducir")

            VStack(alignment: .leading, spacing: 5) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.hairline).frame(height: 4)
                        Capsule().fill(Color.brand)
                            .frame(width: max(0, geo.size.width * playbackFraction), height: 4)
                    }
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                        player.seek(toFraction: min(1, max(0, v.location.x / geo.size.width)))
                    })
                }
                .frame(height: 14)
                Text("\(timeLabel(player.currentTime)) / \(timeLabel(player.duration))")
                    .font(.display(11.5, .semibold).monospacedDigit())
                    .foregroundStyle(.textTertiary)
            }

            Button {
                player.cycleRate()
            } label: {
                Text(player.rate == 1.0 ? "1x" : (player.rate == 1.5 ? "1.5x" : "2x"))
                    .font(.display(12.5, .bold).monospacedDigit())
                    .foregroundStyle(.brandText)
                    .frame(width: 40, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(!player.isLoaded)
            .accessibilityLabel("Velocidad de reproducción")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: Capsule())
    }
}
