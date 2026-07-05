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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Estado en vivo (se actualiza solo, sin botón "Actualizar").
                    HStack(spacing: 10) {
                        if liveCapture.isCapturing {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse, isActive: !reduceMotion)
                            Text("Capturando…").font(.headline)
                            Spacer()
                            if let size = liveCapture.capturedSizeText() {
                                Text(size)
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(.brand)
                                    .contentTransition(.numericText())
                            }
                        } else if liveCapture.capturedSizeText() != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3).foregroundStyle(.green)
                            Text("Captura lista").font(.headline)
                            Spacer()
                            Text(liveCapture.capturedSizeText() ?? "")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.brand)
                        } else {
                            Image(systemName: "waveform.slash")
                                .font(.title3).foregroundStyle(.secondary)
                            Text("Sin captura todavía").font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cómo funciona")
                            .font(.headline)
                        liveStep("1.", "Conecta tus AirPods/audífonos (o baja el volumen). Así nadie en tu oficina escucha.")
                        liveStep("2.", "Toca el botón de captura de abajo y elige “PrensaLiveCapture” → Iniciar transmisión.")
                        liveStep("3.", "Abre Facebook y reproduce el live. La app va guardando el audio en segundo plano.")
                        liveStep("4.", "Cuando quieras (a media transmisión o al final), vuelve aquí y toca “Transcribir lo capturado”.")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 14) {
                        BroadcastPickerView(extensionID: liveCapture.broadcastExtensionID)
                            .frame(width: 56, height: 56)
                            .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityLabel("Iniciar o detener la captura de audio")
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Iniciar / detener captura")
                                .font(.subheadline.weight(.semibold))
                            Text("Toca el ícono. La barra roja de arriba indica que está capturando.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    // Lectura casi en tiempo real, mientras la captura sigue corriendo.
                    if liveCapture.isCapturing || service.followActive || !service.followText.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Leer casi en vivo", systemImage: "text.viewfinder")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.brand)
                                Spacer()
                                if service.followActive {
                                    Button("Pausar") { service.stopFollowing() }
                                        .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                                } else if liveCapture.isCapturing {
                                    Button {
                                        if let url = liveCapture.capturedAudioURL() {
                                            service.startFollowing(captureURL: url)
                                        }
                                    } label: {
                                        Label("Activar", systemImage: "play.fill")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundStyle(.brand)
                                    .disabled(liveCapture.capturedAudioURL() == nil)
                                }
                            }

                            if !service.followText.isEmpty {
                                ScrollViewReader { proxy in
                                    ScrollView {
                                        Text(service.followText)
                                            .font(.system(.body, design: .serif))
                                            .lineSpacing(5)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                        Color.clear.frame(height: 1).id("finDelTexto")
                                    }
                                    .frame(minHeight: 120, maxHeight: 280)
                                    .onChange(of: service.followText) { _, _ in
                                        withAnimation { proxy.scrollTo("finDelTexto", anchor: .bottom) }
                                    }
                                }
                            }

                            if !service.followHint.isEmpty && service.followActive {
                                Text(service.followHint)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Text("Es una lectura rápida por tramos. Al final, “Transcribir lo capturado” te da la versión completa y precisa.")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    .tint(.brand)
                    .disabled(liveCapture.capturedAudioURL() == nil)

                    if liveCapture.capturedSizeText() != nil && !liveCapture.isCapturing {
                        Button(role: .destructive) {
                            service.clearFollow()
                            liveCapture.clearCapture()
                        } label: {
                            Label("Borrar captura y empezar de cero", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Text("Nota: algunos videos protegidos (con copia bloqueada) no se pueden capturar. Si la transcripción sale en silencio, prueba reproducir el live desde Safari (facebook.com) en vez de la app de Facebook.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .background { AppBackdrop() }
            .navigationTitle("Facebook Live")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Refresco automático mientras la pantalla está abierta.
                while !Task.isCancelled {
                    liveCapture.refresh()
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showLiveCapture = false }
                }
            }
        }
    }

    func liveStep(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num).font(.subheadline.weight(.bold)).foregroundStyle(.brand)
            Text(text).font(.callout).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
