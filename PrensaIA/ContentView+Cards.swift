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
                // Tipografía dinámica: crece si el usuario sube el tamaño de texto en Ajustes.
                Text("PrensaIA")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                HStack(spacing: 10) {
                    Rectangle().fill(.secondary.opacity(0.35)).frame(width: 26, height: 1)
                    Text("TRANSCRIBE · ESCUCHA · ANALIZA")
                        .font(.caption2.weight(.semibold))
                        .tracking(2.2)
                        .foregroundStyle(.secondary)
                    Rectangle().fill(.secondary.opacity(0.35)).frame(width: 26, height: 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Semáforo de estado del motor (discreto, en la pantalla principal)

    // Muestra de un vistazo si el motor de transcripción está listo, preparándose
    // o descargándose. Píldora pequeña de vidrio; no estorba.
    var engineStatusChip: some View {
        HStack(spacing: 8) {
            Image(systemName: engineStatus.icon)
                .font(.caption)
                .foregroundStyle(engineStatus.color)
                .symbolEffect(.pulse, isActive: engineStatus.busy && !reduceMotion)
            Text(engineStatus.text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            if let pct = engineStatus.percent {
                Text("\(pct)%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
        .animation(.smooth(duration: 0.3), value: engineStatus.text)
        .animation(.smooth(duration: 0.3), value: engineStatus.percent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estado del motor: \(engineStatus.text)")
    }

    // (color, icono, texto, ¿ocupado?, porcentaje) según el motor elegido.
    var engineStatus: (color: Color, icon: String, text: String, busy: Bool, percent: Int?) {
        if engineRaw == "fast" {
            let fast = FastTranscriber.shared
            if fast.status == .loading {
                let p = Int(fast.downloadProgress * 100)
                return (.orange, "arrow.down.circle", "Descargando motor Rápido", true, p)
            }
            if fast.isReady || fast.isDownloaded {
                return (.green, "checkmark.circle.fill", "Motor Rápido listo", false, nil)
            }
            return (.secondary, "arrow.down.circle", "Motor Rápido: sin descargar", false, nil)
        } else {
            if service.whisperReady {
                return (.green, "checkmark.circle.fill", "Listo para transcribir", false, nil)
            }
            let dl = service.whisperDownloadProgress
            if dl > 0 && dl < 1 {
                return (.orange, "arrow.down.circle", "Descargando motor (solo una vez)", true, Int(dl * 100))
            }
            return (.orange, "circle.fill", "Preparando el motor…", true, nil)
        }
    }

    // MARK: Acciones

    var actionCard: some View {
        VStack(spacing: 12) {
            // Los botones de vidrio van agrupados en un GlassEffectContainer
            // para que el sistema los fusione visualmente (Liquid Glass, iOS 26).
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Subir audio o video", systemImage: "square.and.arrow.up.fill")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.brand)

                    Button {
                        Task {
                            let granted = await recorder.requestPermission()
                            if granted {
                                recorder.start()
                                recordFailed = !recorder.isRecording
                            } else { recordDenied = true }
                        }
                    } label: {
                        Label("Grabar audio", systemImage: "mic.fill")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glass)
                    .tint(.brand)

                    Button {
                        Task {
                            let granted = await recorder.requestPermission()
                            if granted { await service.startLive() } else { recordDenied = true }
                        }
                    } label: {
                        Label("Transcripción en vivo", systemImage: "waveform.badge.mic")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glass)
                    .tint(.brand)

                    PhotosPicker(selection: $photoItem, matching: .videos) {
                        Label("Elegir video de la galería", systemImage: "photo.on.rectangle.angled")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glass)
                    .tint(.brand)

                    Button {
                        liveCapture.refresh()
                        showLiveCapture = true
                    } label: {
                        Label("Transcribir Facebook Live", systemImage: "dot.radiowaves.left.and.right")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glass)
                    .tint(.brand)
                }
            }

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
                // Punto rojo que "late" mientras se graba.
                Image(systemName: "circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
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
                    .mainButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .tint(.brand)
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
                    Image(systemName: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, isActive: !reduceMotion)
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
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = service.liveFullText
                        } label: {
                            Label("Copiar texto", systemImage: "doc.on.doc")
                                .mainButtonLabel()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.brand)

                        Button(role: .destructive) {
                            service.clearLive()
                        } label: {
                            Text("Listo").font(.subheadline.weight(.medium))
                        }
                    }
                }
            } else {
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            Task { await service.stopLive() }
                        } label: {
                            Label("Detener", systemImage: "stop.fill")
                                .mainButtonLabel()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.brand)

                        Button {
                            UIPasteboard.general.string = service.liveFullText
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.glass)
                        .tint(.brand)
                        .disabled(service.liveFullText.isEmpty)
                        .accessibilityLabel("Copiar el texto transcrito")
                    }
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

                // Descarga única del motor Rápido: avance real en pantalla
                // (antes parecía congelado durante varios minutos).
                if case .preparingModel = service.phase,
                   FastTranscriber.shared.status == .loading,
                   FastTranscriber.shared.downloadProgress > 0,
                   FastTranscriber.shared.downloadProgress < 1 {
                    ProgressView(value: FastTranscriber.shared.downloadProgress)
                        .tint(.brand)
                    Text("Descargando el motor Rápido (~600 MB, solo esta vez)… \(Int(FastTranscriber.shared.downloadProgress * 100))%")
                        .font(.caption2).foregroundStyle(.secondary)
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
