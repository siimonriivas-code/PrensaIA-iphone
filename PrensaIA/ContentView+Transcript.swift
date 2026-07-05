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
                .font(.callout).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                playerArea
                manualBar
                if manualMode, let (s, e) = manualRange {
                    manualNamingPanel(s, e)
                }
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(service.segments.enumerated()), id: \.element.id) { i, seg in
                        if let sid = seg.speakerId, i == 0 || service.segments[i - 1].speakerId != sid {
                            speakerChip(sid)
                        }
                        segmentRow(seg)
                    }
                }
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
                    .font(.caption.weight(.bold))
                    .foregroundStyle(speakerColor(id))
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .background(Color.black, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Button {
                player.cycleRate()
            } label: {
                Text(player.rate == 1.0 ? "1x" : (player.rate == 1.5 ? "1.5x" : "2x"))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.brand)
                    .frame(width: 38, height: 28)
                    .background(Color.brand.opacity(0.12), in: Capsule())
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
                    .font(.caption.weight(.medium)).foregroundStyle(.brand)
                Spacer()
                Button("Listo") { cancelManual() }
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            } else {
                Text("Toca una frase para escucharla desde ese minuto")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    manualMode = true
                    manualStart = nil
                    manualEnd = nil
                } label: {
                    Label("Marcar tema", systemImage: "scissors")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.brand)
            }
        }
    }

    func manualNamingPanel(_ s: Double, _ e: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tema de \(timeLabel(s)) a \(timeLabel(e))")
                .font(.subheadline.weight(.bold)).foregroundStyle(.brand)
            TextField("Nombre del tema (ej. Seguridad)", text: $manualName)
                .textFieldStyle(.roundedBorder)
            Button {
                saveManualTopic()
            } label: {
                Label("Guardar tema", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.tint(.brand).interactive(),
                                 in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Text("Aparecerá en “Cortes”, en tu sección. Puedes marcar varios seguidos.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(highlighted ? Color.brand : .secondary)
                    .frame(width: 48, alignment: .leading)
                    .padding(.top, 3)
                Text(seg.text)
                    .font(.callout)
                    .fontWeight(highlighted ? .medium : .regular)
                    .foregroundStyle(highlighted ? Color.brand : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(selected ? Color.brand.opacity(0.18)
                        : (active ? Color.brand.opacity(0.10) : Color.clear),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
