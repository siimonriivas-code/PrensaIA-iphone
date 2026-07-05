//
//  LiveCapture.swift
//  PrensaIA
//
//  Captura del audio de pantalla (Facebook Live) vía extensión de broadcast.
//

import SwiftUI
import ReplayKit

// MARK: - Captura de audio de pantalla (Facebook Live)

// Botón del sistema para iniciar/detener la grabación de pantalla hacia nuestra extensión.
struct BroadcastPickerView: UIViewRepresentable {
    let extensionID: String
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        view.preferredExtension = extensionID
        view.showsMicrophoneButton = false
        return view
    }
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

// Lee el audio que la extensión va guardando en el App Group.
@MainActor
@Observable
final class LiveCaptureController {
    let appGroup = "group.com.simonrivas.Prensa.PrensaIA"
    let broadcastExtensionID = "com.simonrivas.Prensa.PrensaIA.PrensaLiveCapture"
    private(set) var sizeBytes: Int = 0
    private(set) var status: String = ""   // "recording" | "finished" | ""

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    private var wavURL: URL? { containerURL?.appendingPathComponent("liveCapture.wav") }
    private var statusURL: URL? { containerURL?.appendingPathComponent("liveStatus.txt") }

    var isCapturing: Bool { status == "recording" }

    // Duración aproximada de lo capturado (WAV 16 kHz mono a 16 bits = 32,000 bytes/seg).
    var capturedSeconds: Double {
        max(0, Double(sizeBytes - 44) / 32_000)
    }

    func refresh() {
        if let url = statusURL, let s = try? String(contentsOf: url, encoding: .utf8) {
            status = s.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            status = ""
        }
        guard let url = wavURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int else {
            sizeBytes = 0
            return
        }
        sizeBytes = size
    }

    // Devuelve el WAV capturado si ya tiene audio suficiente para transcribir.
    func capturedAudioURL() -> URL? {
        guard let url = wavURL,
              FileManager.default.fileExists(atPath: url.path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int, size > 4000 else { return nil }
        return url
    }

    func capturedSizeText() -> String? {
        guard sizeBytes > 44 else { return nil }
        let dur = capturedSeconds
        let m = Int(dur) / 60, s = Int(dur) % 60
        return String(format: "%d:%02d min", m, s)
    }

    // Borra la captura (para empezar de cero). No borres mientras se está grabando.
    func clearCapture() {
        guard !isCapturing else { return }
        if let url = wavURL { try? FileManager.default.removeItem(at: url) }
        if let url = statusURL { try? FileManager.default.removeItem(at: url) }
        sizeBytes = 0
        status = ""
    }
}
