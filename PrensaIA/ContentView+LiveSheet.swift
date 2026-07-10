//
//  ContentView+LiveSheet.swift
//  PrensaIA
//
//  Pantalla de captura de Facebook Live y lectura casi en vivo.
//

import SwiftUI

extension ContentView {

    // MARK: Facebook Live (captura de audio por pantalla)

    var liveCaptureSheet: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Estado en vivo (se actualiza solo, sin botón "Actualizar").
                    HStack(spacing: 10) {
                        if liveCapture.isCapturing {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.liveRed)
                                .symbolEffect(.pulse, isActive: !reduceMotion)
                            Text("Capturando…")
                                .font(.display(16, .heavy)).foregroundStyle(.textPrimary)
                            Spacer()
                            if let size = liveCapture.capturedSizeText() {
                                Text(size)
                                    .font(.display(14, .bold).monospacedDigit())
                                    .foregroundStyle(.brandText)
                                    .contentTransition(.numericText())
                            }
                        } else if liveCapture.capturedSizeText() != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 19)).foregroundStyle(.successGreen)
                            Text("Captura lista")
                                .font(.display(16, .heavy)).foregroundStyle(.textPrimary)
                            Spacer()
                            Text(liveCapture.capturedSizeText() ?? "")
                                .font(.display(14, .bold).monospacedDigit())
                                .foregroundStyle(.brandText)
                        } else {
                            Image(systemName: "waveform.slash")
                                .font(.system(size: 19)).foregroundStyle(.textTertiary)
                            Text("Sin captura todavía")
                                .font(.display(16, .heavy))
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    .card(radius: 22, padding: 16)
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cómo funciona")
                            .font(.display(15.5, .heavy)).foregroundStyle(.textPrimary)
                        liveStep("1.", "Conecta tus AirPods/audífonos (o baja el volumen). Así nadie en tu oficina escucha.")
                        liveStep("2.", "Toca el botón de captura de abajo y elige “PrensaLiveCapture” → Iniciar transmisión.")
                        liveStep("3.", "Abre Facebook y reproduce el live. La app va guardando el audio en segundo plano.")
                        liveStep("4.", "Cuando quieras (a media transmisión o al final), vuelve aquí y toca “Transcribir lo capturado”.")
                    }
                    .card(radius: 22, padding: 16)

                    HStack(spacing: 14) {
                        BroadcastPickerView(extensionID: liveCapture.broadcastExtensionID)
                            .frame(width: 56, height: 56)
                            .background(liveCapture.isCapturing ? Color.liveRed : Color.brand,
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .accessibilityLabel("Iniciar o detener la captura de audio")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Iniciar / detener captura")
                                .font(.display(14.5, .bold)).foregroundStyle(.textPrimary)
                            Text("Toca el ícono. La barra roja de arriba indica que está capturando.")
                                .font(.display(12.5, .medium)).foregroundStyle(.textTertiary)
                        }
                    }

                    // Lectura casi en tiempo real, mientras la captura sigue corriendo.
                    if liveCapture.isCapturing || service.followActive || !service.followText.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Leer casi en vivo", systemImage: "text.viewfinder")
                                    .font(.display(14, .heavy))
                                    .foregroundStyle(.brandText)
                                Spacer()
                                if service.followActive {
                                    Button("Pausar") { service.stopFollowing() }
                                        .font(.display(12.5, .bold)).foregroundStyle(.textTertiary)
                                } else if liveCapture.isCapturing {
                                    Button {
                                        if let url = liveCapture.capturedAudioURL() {
                                            service.startFollowing(captureURL: url)
                                        }
                                    } label: {
                                        Label("Activar", systemImage: "play.fill")
                                            .font(.display(12.5, .heavy))
                                    }
                                    .foregroundStyle(.brandText)
                                    .disabled(liveCapture.capturedAudioURL() == nil)
                                }
                            }

                            if !service.followText.isEmpty {
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        Text(service.followText)
                                            .font(.serifItalic(16.5, .regular))
                                            .lineSpacing(9)
                                            .foregroundStyle(.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                        Color.clear.frame(height: 1).id("finDelTexto")
                                    }
                                    .frame(minHeight: 120, maxHeight: 210)
                                    .onChange(of: service.followText) { _, _ in
                                        withAnimation { proxy.scrollTo("finDelTexto", anchor: .bottom) }
                                    }
                                }
                            }

                            if !service.followHint.isEmpty && service.followActive {
                                Text(service.followHint)
                                    .font(.display(11, .medium)).foregroundStyle(.textTertiary)
                            }
                            Text("Es una lectura rápida por tramos. Al final, “Transcribir lo capturado” te da la versión completa y precisa.")
                                .font(.display(11.5, .medium)).foregroundStyle(.textTertiary)
                        }
                        .card(radius: 22, padding: 16)
                    }

                    Button {
                        if let url = liveCapture.capturedAudioURL() {
                            service.clearFollow()   // detiene la lectura en vivo: entra la versión buena
                            showLiveCapture = false
                            Task {
                                await service.process(mediaURL: url)
                                // Limpia SOLO si la transcripción de verdad corrió
                                // (si había otra en curso, process() no hace nada y
                                // no debemos borrar la captura sin usarla).
                                liveCapture.refresh()
                                if !service.isBusy { liveCapture.clearCapture() }
                            }
                        }
                    } label: {
                        Label("Transcribir lo capturado", systemImage: "text.badge.checkmark")
                            .mainButtonLabel()
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .tint(.brand)
                    .disabled(liveCapture.capturedAudioURL() == nil)
                    .opacity(liveCapture.capturedAudioURL() == nil ? 0.5 : 1)

                    if liveCapture.capturedSizeText() != nil && !liveCapture.isCapturing {
                        Button {
                            service.clearFollow()
                            liveCapture.clearCapture()
                        } label: {
                            Label("Borrar captura y empezar de cero", systemImage: "trash")
                                .font(.display(13.5, .semibold))
                                .foregroundStyle(.liveRed)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Text("Nota: algunos videos protegidos (con copia bloqueada) no se pueden capturar. Si la transcripción sale en silencio, prueba reproducir el live desde Safari (facebook.com) en vez de la app de Facebook.")
                        .font(.display(11, .medium)).foregroundStyle(.textTertiary)
                }
                .padding(18)
            }
            .background { AppBackdrop() }
            .navigationTitle("Facebook Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .task {
                // Refresco automático mientras la pantalla está abierta.
                while !Task.isCancelled {
                    liveCapture.refresh()
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
    }

    func liveStep(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num).font(.display(13, .heavy)).foregroundStyle(.brandText)
            Text(text).font(.display(13, .medium)).lineSpacing(3)
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
