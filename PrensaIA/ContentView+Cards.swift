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

    // MARK: Cabecera (identidad PL)

    // Fila nav (logo PL en círculo de vidrio + fecha serif) y héroe editorial.
    var homeHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image("LogoPL")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27, height: 25)
                    .padding(10)
                    .glassEffect(.regular, in: Circle())
                Spacer()
                Text(Date.now.formatted(
                    .dateTime.weekday(.wide).day().month(.wide)
                        .locale(Locale(identifier: "es_MX"))))
                    .font(.serifItalic(14.5, .regular))
                    .foregroundStyle(.textTertiary)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("PrensaIA")
                        .font(.display(32, .black))
                        .tracking(-0.6)
                        .foregroundStyle(.textPrimary)
                    PLCapsule(text: "IA LOCAL")
                }
                Text("Transcribe, escucha y analiza — sin internet.")
                    .font(.display(14.5, .medium))
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(.top, 6)
    }

    // MARK: Semáforo de estado del motor (discreto, en la pantalla principal)

    // Muestra de un vistazo si el motor de transcripción está listo, preparándose
    // o descargándose. Píldora pequeña de vidrio; no estorba.
    var engineStatusChip: some View {
        HStack(spacing: 8) {
            Image(systemName: engineStatus.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(engineStatus.color)
                .symbolEffect(.pulse, isActive: engineStatus.busy && !reduceMotion)
            Text(engineStatus.text)
                .font(.display(12, .semibold))
                .foregroundStyle(.textSecondary)
            if let pct = engineStatus.percent {
                Text("\(pct)%")
                    .font(.display(12, .bold).monospacedDigit())
                    .foregroundStyle(.textSecondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .glassEffect(.clear, in: Capsule())
        .frame(maxWidth: .infinity)
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
                return (.goldText, "arrow.down.circle", "Descargando motor Rápido", true, p)
            }
            if fast.isReady || fast.isDownloaded {
                return (.successGreen, "checkmark.circle.fill", "Motor Rápido listo", false, nil)
            }
            return (.textTertiary, "arrow.down.circle", "Motor Rápido: sin descargar", false, nil)
        } else {
            if service.whisperReady {
                return (.successGreen, "checkmark.circle.fill", "Listo para transcribir", false, nil)
            }
            let dl = service.whisperDownloadProgress
            if dl > 0 && dl < 1 {
                return (.goldText, "arrow.down.circle", "Descargando motor (solo una vez)", true, Int(dl * 100))
            }
            return (.goldText, "circle.fill", "Preparando el motor…", true, nil)
        }
    }

    // MARK: Acciones (Inicio)

    var homeActions: some View {
        VStack(spacing: 18) {
            engineStatusChip

            // CTA principal: subir audio o video.
            Button {
                showImporter = true
            } label: {
                Label("Subir audio o video", systemImage: "square.and.arrow.up")
                    .font(.display(15.5, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .tint(.brand)

            // Mosaico: Grabar · En vivo · Galería.
            HStack(spacing: 12) {
                Button {
                    Task {
                        let granted = await recorder.requestPermission()
                        if granted {
                            recorder.start()
                            recordFailed = !recorder.isRecording
                        } else { recordDenied = true }
                    }
                } label: {
                    homeTile("Grabar", icon: "mic")
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        let granted = await recorder.requestPermission()
                        if granted { await service.startLive() } else { recordDenied = true }
                    }
                } label: {
                    homeTile("En vivo", icon: "waveform.badge.mic")
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $photoItem, matching: .videos) {
                    homeTile("Galería", icon: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
            }

            if recordDenied {
                Text("Para grabar, activa el micrófono en Ajustes › PrensaIA.")
                    .font(.display(12.5, .medium)).foregroundStyle(.liveRed)
                    .multilineTextAlignment(.center)
            }

            // Facebook Live.
            Button {
                liveCapture.refresh()
                showLiveCapture = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.brandText)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Transcribir Facebook Live")
                            .font(.display(14.5, .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Captura el audio de una transmisión y léelo casi en vivo.")
                            .font(.display(12.5, .medium))
                            .foregroundStyle(.textTertiary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .card(radius: 22, padding: 16)

            // Oradores.
            VStack(spacing: 0) {
                PLSectionLabel("Oradores")
                VStack(spacing: 14) {
                    Toggle(isOn: Binding(
                        get: { service.diarizationEnabled },
                        set: { service.diarizationEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Identificar oradores")
                                .font(.display(14.5, .bold))
                                .foregroundStyle(.textPrimary)
                            Text("Detecta quién habla. La 1ª vez descarga un modelo.")
                                .font(.display(12.5, .medium))
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    .tint(.brand)

                    if service.diarizationEnabled {
                        Rectangle().fill(.hairline).frame(height: 1)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Número de oradores")
                                    .font(.display(14.5, .medium))
                                    .foregroundStyle(.textPrimary)
                                Text("Indícalo si lo sabes: es más preciso.")
                                    .font(.display(12.5, .medium))
                                    .foregroundStyle(.textTertiary)
                            }
                            Spacer()
                            Menu {
                                Button("Automático") { service.expectedSpeakers = 0 }
                                ForEach(2...8, id: \.self) { n in
                                    Button("\(n)") { service.expectedSpeakers = n }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(service.expectedSpeakers == 0 ? "Automático" : "\(service.expectedSpeakers)")
                                        .font(.display(14, .bold))
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundStyle(.brandText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .glassEffect(.clear, in: Capsule())
                            }
                        }
                    }
                }
                .card(radius: 22, padding: 16)
            }

            // Recientes (2 últimas transcripciones).
            if !history.items.isEmpty {
                VStack(spacing: 0) {
                    PLSectionLabel("Recientes")
                    VStack(spacing: 0) {
                        ForEach(Array(history.items.prefix(2).enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Rectangle().fill(.hairline).frame(height: 1)
                            }
                            Button {
                                loadItem(item)
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.display(14, .bold))
                                            .foregroundStyle(.textPrimary)
                                            .lineLimit(1)
                                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.serifItalic(12, .regular))
                                            .foregroundStyle(.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.textTertiary)
                                }
                                .padding(.vertical, 11)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .card(radius: 22, padding: 16)
                }
            }

            if case .failed(let msg) = service.phase {
                Text(msg)
                    .font(.display(12.5, .medium)).foregroundStyle(.liveRed)
                    .multilineTextAlignment(.center)
            } else if !service.showsResults {
                // Nota de privacidad — el sello de la casa.
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.goldText)
                    Text("Se procesa en tu iPhone, en español y sin internet.")
                        .font(.display(12.5, .medium))
                        .foregroundStyle(.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // Tile del mosaico: vidrio regular, ícono 24 + label 13.
    func homeTile(_ title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(.brandText)
            Text(title)
                .font(.display(13, .bold))
                .foregroundStyle(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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

            ScrollViewReader { proxy in
                ScrollView {
                    Text(liveAttributed)
                        .font(.system(.body, design: .serif))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                    // Ancla invisible al final para el auto-scroll.
                    Color.clear.frame(height: 1).id("liveBottom")
                }
                // Altura FIJA: la tarjeta ya no crece ni "salta" al llegar texto.
                .frame(height: 240)
                .onChange(of: service.liveFullText) { _, _ in
                    if reduceMotion {
                        proxy.scrollTo("liveBottom", anchor: .bottom)
                    } else {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("liveBottom", anchor: .bottom)
                        }
                    }
                }
            }

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
