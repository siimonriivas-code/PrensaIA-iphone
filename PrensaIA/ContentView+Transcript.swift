//
//  ContentView+Transcript.swift
//  PrensaIA
//
//  Pestaña Por minuto: reproductor, onda, frases y marcado de temas.
//

import SwiftUI
import AVKit

extension ContentView {

    // MARK: Transcripción (con reproductor)

    @ViewBuilder
    var transcriptView: some View {
        if service.segments.isEmpty {
            Text(service.transcript)
                .font(.display(14.5, .medium))
                .foregroundStyle(.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                playerArea
                manualBar
                if manualMode, let (s, e) = manualRange {
                    manualNamingPanel(s, e)
                }
                // Todas las frases viven en UNA tarjeta de vidrio.
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(service.segments.enumerated()), id: \.element.id) { i, seg in
                        if let sid = seg.speakerId, i == 0 || service.segments[i - 1].speakerId != sid {
                            speakerChip(sid)
                        }
                        segmentRow(seg)
                    }
                }
                .card(radius: 26, padding: 10)
            }
        }
    }

    func speakerChip(_ id: Int) -> some View {
        Button {
            startRename(id)
        } label: {
            HStack(spacing: 6) {
                Circle().fill(speakerColor(id)).frame(width: 9, height: 9)
                Text(speakerName(id))
                    .font(.display(12.5, .heavy))
                    .foregroundStyle(speakerColor(id))
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.bottom, 2)
        .padding(.horizontal, 10)
    }

    var playbackFraction: Double {
        player.duration > 0 ? min(1, player.currentTime / player.duration) : 0
    }

    // Reproductor de video (con controles nativos) o barra de audio con onda.
    @ViewBuilder
    var playerArea: some View {
        if service.isVideo, service.playbackURL != nil {
            VideoPlayer(player: player.avPlayer)
                .frame(height: 212)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .background(Color.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            playerBar
        }
    }

    var playerBar: some View {
        HStack(spacing: 14) {
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.brand)
            }
            .buttonStyle(.plain)
            .disabled(!player.isLoaded)
            .accessibilityLabel(player.isPlaying ? "Pausar" : "Reproducir")

            VStack(alignment: .leading, spacing: 6) {
                if waveform.isEmpty {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 4)
                            Capsule().fill(Color.brand)
                                .frame(width: max(0, geo.size.width * playbackFraction), height: 4)
                        }
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                            player.seek(toFraction: min(1, max(0, v.location.x / geo.size.width)))
                        })
                    }
                    .frame(height: 28)
                } else {
                    WaveformView(samples: waveform, progress: playbackFraction) { f in
                        player.seek(toFraction: f)
                    }
                    .frame(height: 38)
                    .accessibilityLabel("Onda de audio. Desliza para avanzar.")
                }

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
                    .frame(width: 38, height: 28)
                    .background(Color.brandSoft, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!player.isLoaded)
            .accessibilityLabel("Velocidad de reproducción \(player.rate == 1.0 ? "normal" : (player.rate == 1.5 ? "1.5x" : "2x"))")
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // Barra de acciones sobre la lista de frases: reproducir o entrar a "marcar tema".
    var manualBar: some View {
        HStack {
            if manualMode {
                Label(manualStart == nil ? "Toca el inicio del tema"
                      : (manualEnd == nil ? "Ahora toca el final" : "Ponle nombre y guarda"),
                      systemImage: "hand.tap")
                    .font(.display(12.5, .semibold)).foregroundStyle(.brandText)
                Spacer()
                Button("Listo") { cancelManual() }
                    .font(.display(12.5, .bold)).foregroundStyle(.textTertiary)
            } else {
                Text("Toca una frase para escucharla desde ese minuto")
                    .font(.display(12.5, .medium)).foregroundStyle(.textTertiary)
                Spacer()
                Button {
                    manualMode = true
                    manualStart = nil
                    manualEnd = nil
                } label: {
                    Label("Marcar tema", systemImage: "scissors")
                        .font(.display(12.5, .heavy))
                }
                .foregroundStyle(.brandText)
            }
        }
    }

    func manualNamingPanel(_ s: Double, _ e: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tema de \(timeLabel(s)) a \(timeLabel(e))")
                .font(.display(13.5, .heavy)).foregroundStyle(.brandText)
            TextField("Nombre del tema (ej. Seguridad)", text: $manualName)
                .font(.display(14, .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button {
                saveManualTopic()
            } label: {
                Label("Guardar tema", systemImage: "checkmark.circle.fill")
                    .font(.display(14.5, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .tint(.brand)
            Text("Aparecerá en “Cortes”, en tu sección. Puedes marcar varios seguidos.")
                .font(.display(11, .medium)).foregroundStyle(.textTertiary)
        }
        .card(radius: 20, padding: 14)
    }

    func segmentRow(_ seg: TimedSegment) -> some View {
        let active = player.currentTime >= seg.start && player.currentTime < seg.end
        let selected = segIsInManualRange(seg)
        let highlighted = active || selected
        return Button {
            if manualMode {
                handleManualTap(seg)
            } else {
                player.playFrom(seg.start)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(timeLabel(seg.start))
                    .font(.display(12, .semibold).monospacedDigit())
                    .foregroundStyle(highlighted ? .brandText : .textTertiary)
                    .frame(width: 44, alignment: .leading)
                    .padding(.top, 3)
                Text(seg.text)
                    .font(.display(14.5, highlighted ? .semibold : .medium))
                    .lineSpacing(4)
                    .foregroundStyle(highlighted ? .brandText : .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(selected ? AnyShapeStyle(Color.brand.opacity(0.16))
                        : (active ? AnyShapeStyle(Color.brandSoft) : AnyShapeStyle(Color.clear)),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .leading) {
                if let sid = seg.speakerId {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(speakerColor(sid))
                        .frame(width: 3)
                        .padding(.vertical, 6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
