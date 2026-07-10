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
        VStack(spacing: 18) {
            HStack(spacing: 9) {
                // Punto rojo que "late" mientras se graba.
                Image(systemName: "circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.liveRed)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
                Text("Grabando")
                    .font(.display(16, .heavy))
                    .foregroundStyle(.textPrimary)
            }
            .frame(maxWidth: .infinity)

            // Cronómetro grande: legible de un vistazo desde el escritorio.
            Text(timeLabel(recorder.elapsed))
                .font(.display(58, .bold).monospacedDigit())
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText())

            RecordingWaveView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                if let url = recorder.stop() {
                    Task { await service.process(mediaURL: url) }
                }
            } label: {
                Label("Detener y transcribir", systemImage: "stop.fill")
                    .mainButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .tint(.brand)

            Button {
                recorder.cancel()
            } label: {
                Text("Cancelar")
                    .font(.display(15, .semibold))
                    .foregroundStyle(.liveRed)
            }
        }
        .card()
    }

    var liveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if service.liveDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 19)).foregroundStyle(.successGreen)
                    Text("Transcripción lista")
                        .font(.display(17, .heavy))
                        .foregroundStyle(.textPrimary)
                    Spacer()
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.liveRed)
                        .symbolEffect(.pulse, isActive: !reduceMotion)
                    PLCapsule(text: service.liveStarting ? "PREPARANDO…" : "EN VIVO",
                              variant: .wine)
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.system(size: 19)).foregroundStyle(.brandText)
                        .symbolEffect(.variableColor.iterative, isActive: service.isLive && !reduceMotion)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    Text(liveAttributed)
                        .font(.serifItalic(18, .regular))
                        .lineSpacing(11)
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
                    .font(.display(12, .medium)).foregroundStyle(.textTertiary)
            } else if !service.liveDone && service.liveFullText.isEmpty {
                Text("Empieza a hablar… el texto aparecerá aquí.")
                    .font(.display(12, .medium)).foregroundStyle(.textTertiary)
            } else if !service.liveDone {
                Text("El texto gris es provisional; se confirma al escuchar mejor.")
                    .font(.display(12, .medium)).foregroundStyle(.textTertiary)
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
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                        .tint(.brand)

                        Button {
                            service.clearLive()
                        } label: {
                            Text("Listo")
                                .font(.display(14, .semibold))
                                .foregroundStyle(.textSecondary)
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
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                        .tint(.liveRed)

                        Button {
                            UIPasteboard.general.string = service.liveFullText
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: 54, height: 54)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .tint(.brandText)
                        .disabled(service.liveFullText.isEmpty)
                        .accessibilityLabel("Copiar el texto transcrito")
                    }
                }
            }
        }
        .card()
    }

    // Texto confirmado (TextPrimary) + lo "en proceso" (TextTertiary) + caret.
    var liveAttributed: AttributedString {
        var result = AttributedString()
        if !service.liveConfirmed.isEmpty {
            var confirmed = AttributedString(service.liveConfirmed + " ")
            confirmed.foregroundColor = UIColor(named: "TextPrimary") ?? .label
            result += confirmed
        }
        if !service.liveHypothesis.isEmpty {
            var pending = AttributedString(service.liveHypothesis)
            pending.foregroundColor = UIColor(named: "TextTertiary") ?? .tertiaryLabel
            result += pending
        }
        if service.isLive {
            var caret = AttributedString("▍")
            caret.foregroundColor = UIColor(named: "BrandText") ?? .label
            result += caret
        }
        return result
    }

    // MARK: Progreso por etapas

    var progressCard: some View {
        VStack(spacing: 20) {
            // Anillo editorial: logo PL al centro (indeterminado) o % real.
            ProgressRingView(progress: {
                if case .transcribing(let frac) = service.phase, frac > 0 {
                    return frac
                }
                return nil
            }())

            HStack(alignment: .top, spacing: 8) {
                stepItem("Preparar", index: 0)
                stepItem("Transcribir", index: 1)
                stepItem("Analizar", index: 2)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    if service.showStageSpinner {
                        ProgressView().controlSize(.small).tint(.brandText)
                    }
                    Text(service.stageTitle)
                        .font(.display(16, .heavy))
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    if let pct = service.stagePercentText {
                        Text(pct)
                            .font(.display(14, .bold).monospacedDigit())
                            .foregroundStyle(.brandText)
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
                        .font(.display(11, .medium)).foregroundStyle(.textTertiary)
                }

                Text(service.stageSubtitle)
                    .font(.display(12.5, .medium)).foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Puedes bloquear la pantalla; seguimos trabajando.")
                .font(.display(11.5, .medium))
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .card()
    }

    func stepItem(_ label: String, index: Int) -> some View {
        VStack(spacing: 7) {
            Capsule()
                .fill(index <= service.currentStep
                      ? AnyShapeStyle(Color.brand)
                      : AnyShapeStyle(Color.hairline))
                .frame(height: 5)
            Text(label)
                .font(.display(11, index == service.currentStep ? .bold : .medium))
                .foregroundStyle(index <= service.currentStep ? .brandText : .textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Onda animada de grabación (26 barras, cada 5ª dorada)

struct RecordingWaveView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false
    // Alturas aleatorias fijas por aparición (el movimiento lo da el scaleY).
    private let heights: [CGFloat] = (0..<26).map { _ in CGFloat.random(in: 0.28...1.0) }

    var body: some View {
        HStack(spacing: 4.5) {
            ForEach(0..<26, id: \.self) { i in
                Capsule()
                    .fill(i % 5 == 4 ? Color.goldFill : Color.brandText)
                    .frame(width: 4.5, height: 46 * heights[i])
                    .scaleEffect(y: (animating && !reduceMotion) ? 0.4 : 1, anchor: .center)
                    .animation(reduceMotion ? nil
                               : .easeInOut(duration: 1.05)
                                   .repeatForever(autoreverses: true)
                                   .delay(Double(i) * 0.055),
                               value: animating)
            }
        }
        .frame(height: 52)
        .onAppear { animating = true }
        .accessibilityHidden(true)
    }
}

// MARK: - Anillo de progreso editorial (128 pt)

struct ProgressRingView: View {
    /// nil = indeterminado (arco girando con el logo PL al centro).
    let progress: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brandSoft, lineWidth: 9)
            if let p = progress {
                Circle()
                    .trim(from: 0, to: max(0.02, p))
                    .stroke(LinearGradient.brand,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.3), value: p)
                Text("\(Int(p * 100))%")
                    .font(.display(24, .bold).monospacedDigit())
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())
            } else {
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(LinearGradient.brand,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(spinning ? 270 : -90))
                    .animation(reduceMotion ? nil
                               : .linear(duration: 1.1).repeatForever(autoreverses: false),
                               value: spinning)
                Image("LogoPL")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46)
            }
        }
        .frame(width: 128, height: 128)
        .onAppear { spinning = true }
        .accessibilityHidden(true)
    }
}
