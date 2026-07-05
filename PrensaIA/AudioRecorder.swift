//
//  AudioRecorder.swift
//  PrensaIA
//
//  Grabadora de audio del micrófono.
//

import SwiftUI
import AVFoundation

// MARK: - Grabador de audio

@MainActor
@Observable
final class AudioRecorderController {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    var isRecording = false
    var elapsed: TimeInterval = 0
    private var lastURL: URL?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func start() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("grabacion-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.record()
            recorder = rec
            lastURL = url
            elapsed = 0
            isRecording = true
            startTimer()
        } catch {
            isRecording = false
        }
    }

    @discardableResult
    func stop() -> URL? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        stopTimer()
        return lastURL
    }

    // Detiene la grabación y descarta el archivo (botón Cancelar).
    func cancel() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        stopTimer()
        if let url = lastURL {
            try? FileManager.default.removeItem(at: url)
        }
        lastURL = nil
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() { elapsed += 0.5 }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
