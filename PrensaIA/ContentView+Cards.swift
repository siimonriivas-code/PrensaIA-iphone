//
//  ContentView+Cards.swift
//  PrensaIA
//
//  Cabecera editorial, tarjetas de acciones, grabación, en vivo y progreso.
//

import SwiftUI
import PhotosUI
import UIKit

extension ContentView {

    // MARK: Cabecera (marca)

    // Cabezal editorial: ícono con degradado (late cuando trabaja) + lema tipo periódico.
    var header: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient.brand)
                .frame(width: 64, height: 64)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                }
                .overlay {
                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative,
                                      isActive: service.isBusy || service.isLive)
                }
                .shadow(color: .brand.opacity(0.4), radius: 14, y: 7)

            VStack(spacing: 7) {
                Text("PrensaIA")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                HStack(spacing: 10) {
                    Rectangle().fill(.secondary.opacity(0.35)).frame(width: 26, height: 1)
                    Text("TRANSCRIBE · ESCUCHA · ANALIZA")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.2)
                        .foregroundStyle(.secondary)
                    Rectangle().fill(.secondary.opacity(0.35)).frame(width: 26, height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Acciones

    var actionCard: some View {
        VStack(spacing: 12) {
            Button {
                showImporter = true
            } label: {
                Label("Subir audio o video", systemImage: "square.and.arrow.up.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                Task {
                    let granted = await recorder.requestPermission()
                    if granted { recorder.start() } else { recordDenied = true }
                }
            } label: {
                Label("Grabar audio", systemImage: "mic.fill")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                Task {
                    let granted = await recorder.requestPermission()
                    if granted { await service.startLive() } else { recordDenied = true }
                }
            } label: {
                Label("Transcripción en vivo", systemImage: "waveform.badge.mic")
            }
            .buttonStyle(SecondaryButtonStyle())

            PhotosPicker(selection: $photoItem, matching: .videos) {
                Label("Elegir video de la galería", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                liveCapture.refresh()
                showLiveCapture = true
            } label: {
                Label("Transcribir Facebook Live", systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(SecondaryButtonStyle())

            if recordDenied {
                Text("Para grabar, activa el micrófono en Ajustes › PrensaIA.")
                    .font(.footnote).foregroundStyle(.red)
                    .multilineTextAlignment(.center).padding(.top, 2)
            }

            Toggle(isOn: Binding(
                get: { service.diarizationEnabled },
                set: { service.diarizationEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Identificar oradores")
                        .font(.subheadline.weight(.medium))
                    Text("Detecta quién habla. La 1ª vez descarga un modelo.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(.brand)
            .padding(.top, 4)

            if service.diarizationEnabled {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Número de oradores")
                            .font(.subheadline)
                        Text("Indícalo si lo sabes: es más preciso.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        Button("Automático") { service.expectedSpeakers = 0 }
                        ForEach(2...8, id: \.self) { n in
                            Button("\(n)") { service.expectedSpeakers = n }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(service.expectedSpeakers == 0 ? "Automático" : "\(service.expectedSpeakers)")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                        .foregroundStyle(.brand)
                    }
                }
            }

            if case .failed(let msg) = service.phase {
                Text(msg)
                    .font(.footnote).foregroundStyle(.red)
                    .multilineTextAlignment(.center).padding(.top, 4)
            } else if !service.showsResults {
                Text("Se procesa en tu iPhone, en español y sin internet.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.top, 4)
            }
        }
        .card()
    }

    var recordingCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Circle().fill(.red).frame(width: 12, height: 12)
                Text("Grabando…").font(.headline)
                Spacer()
                Text(timeLabel(recorder.elapsed))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.brand)
            }
            Button {
                if let url = recorder.stop() {
                    Task { await service.process(mediaURL: url) }
                }
            } label: {
                Label("Detener y transcribir", systemImage: "stop.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            Button(role: .destructive) {
                recorder.cancel()
            } label: {
                Text("Cancelar")
                    .font(.subheadline.weight(.medium))
            }
        }
        .card()
    }

    var liveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if service.liveDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3).foregroundStyle(.green)
                    Text("Transcripción lista").font(.headline)
                } else {
                    Circle().fill(.red).frame(width: 12, height: 12)
                    Text(service.liveStarting ? "Preparando…" : "En vivo")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.title3).foregroundStyle(.brand)
                        .symbolEffect(.variableColor.iterative, isActive: service.isLive)
                }
                if service.liveDone { Spacer() }
            }

            ScrollView {
                Text(liveAttributed)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 140, maxHeight: 260)

            if service.liveStarting {
                Text("Despertando el modelo… habla en un momento.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if !service.liveDone && service.liveFullText.isEmpty {
                Text("Empieza a hablar… el texto aparecerá aquí.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if service.liveDone {
                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = service.liveFullText
                    } label: {
                        Label("Copiar texto", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(role: .destructive) {
                        service.clearLive()
                    } label: {
                        Text("Listo").font(.subheadline.weight(.medium))
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await service.stopLive() }
                    } label: {
                        Label("Detener", systemImage: "stop.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        UIPasteboard.general.string = service.liveFullText
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.headline)
                            .foregroundStyle(.brand)
                            .frame(width: 52, height: 50)
                            .background(Color.brand.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(service.liveFullText.isEmpty)
                }
            }
        }
        .card()
    }

    // Texto confirmado en negro + lo "en proceso" en gris.
    var liveAttributed: AttributedString {
        var result = AttributedString()
        if !service.liveConfirmed.isEmpty {
            var confirmed = AttributedString(service.liveConfirmed + " ")
            confirmed.foregroundColor = .primary
            result += confirmed
        }
        if !service.liveHypothesis.isEmpty {
            var pending = AttributedString(service.liveHypothesis)
            pending.foregroundColor = .secondary
            result += pending
        }
        return result
    }

    // MARK: Progreso por etapas

    var progressCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 8) {
                stepItem("Preparar", index: 0)
                stepItem("Transcribir", index: 1)
                stepItem("Analizar", index: 2)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    if service.showStageSpinner {
                        ProgressView().controlSize(.small)
                    }
                    Text(service.stageTitle)
                        .font(.headline)
                    Spacer()
                    if let pct = service.stagePercentText {
                        Text(pct)
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .foregroundStyle(.brand)
                            .contentTransition(.numericText())
                    }
                }

                if case .transcribing(let frac) = service.phase {
                    ProgressView(value: frac)
                        .tint(.brand)
                }

                Text(service.stageSubtitle)
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    func stepItem(_ label: String, index: Int) -> some View {
        VStack(spacing: 7) {
            Capsule()
                .fill(index <= service.currentStep
                      ? AnyShapeStyle(LinearGradient.brand)
                      : AnyShapeStyle(Color(.systemGray5)))
                .frame(height: 5)
            Text(label)
                .font(.caption2.weight(index == service.currentStep ? .semibold : .regular))
                .foregroundStyle(index <= service.currentStep ? Color.brand : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
