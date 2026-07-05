//
//  MediaPlayback.swift
//  PrensaIA
//
//  Reproductor de audio/video y visualizador de onda.
//

import SwiftUI
import AVFoundation
import CoreMedia

// MARK: - Reproductor de medios (audio y video)

@MainActor
@Observable
final class MediaPlayerController {
    let avPlayer = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var boundaryObserver: Any?

    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var rate: Float = 1.0
    var isVideo = false
    var isLoaded = false

    func load(url: URL, isVideo: Bool) {
        stop()
        self.isVideo = isVideo
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }

        let item = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: item)
        avPlayer.rate = 0
        rate = 1.0
        currentTime = 0
        duration = 0
        isLoaded = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            if let d = try? await item.asset.load(.duration) {
                let secs = CMTimeGetSeconds(d)
                if secs.isFinite && secs > 0 { self.duration = secs }
            }
        }

        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = CMTimeGetSeconds(t)
                self.isPlaying = self.avPlayer.timeControlStatus == .playing
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleEnd() }
        }
    }

    private func handleEnd() {
        isPlaying = false
        removeBoundaryObserver()   // limpia el tope de una previsualización de corte pendiente
        avPlayer.seek(to: .zero)
        currentTime = 0
    }

    func cycleRate() {
        switch rate {
        case 1.0: rate = 1.5
        case 1.5: rate = 2.0
        default: rate = 1.0
        }
        if isPlaying { avPlayer.rate = rate }
    }

    func playFrom(_ time: Double) {
        guard isLoaded else { return }
        removeBoundaryObserver()
        let t = CMTime(seconds: max(0, time), preferredTimescale: 600)
        avPlayer.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
        avPlayer.playImmediately(atRate: rate)
        isPlaying = true
        currentTime = time
    }

    // Reproduce SOLO un tramo (inicio→fin) y se detiene al terminar. Para previsualizar cortes.
    func playRange(_ start: Double, _ end: Double) {
        guard isLoaded else { return }
        removeBoundaryObserver()
        let s = CMTime(seconds: max(0, start), preferredTimescale: 600)
        avPlayer.seek(to: s, toleranceBefore: .zero, toleranceAfter: .zero)
        avPlayer.playImmediately(atRate: rate)
        isPlaying = true
        currentTime = start
        guard end > start else { return }
        let boundary = NSValue(time: CMTime(seconds: end, preferredTimescale: 600))
        boundaryObserver = avPlayer.addBoundaryTimeObserver(forTimes: [boundary], queue: .main) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.avPlayer.pause()
                self.isPlaying = false
                self.removeBoundaryObserver()
            }
        }
    }

    func seek(toFraction f: Double) {
        guard isLoaded, duration > 0 else { return }
        removeBoundaryObserver()
        let time = duration * min(1, max(0, f))
        let wasPlaying = isPlaying
        let t = CMTime(seconds: max(0, time), preferredTimescale: 600)
        avPlayer.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        if wasPlaying { avPlayer.playImmediately(atRate: rate) }
    }

    func togglePlayPause() {
        guard isLoaded else { return }
        if avPlayer.timeControlStatus == .playing {
            avPlayer.pause()
            isPlaying = false
        } else {
            removeBoundaryObserver()
            avPlayer.playImmediately(atRate: rate)
            isPlaying = true
        }
    }

    private func removeBoundaryObserver() {
        if let boundaryObserver {
            avPlayer.removeTimeObserver(boundaryObserver)
            self.boundaryObserver = nil
        }
    }

    func stop() {
        if let timeObserver { avPlayer.removeTimeObserver(timeObserver); self.timeObserver = nil }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver); self.endObserver = nil }
        removeBoundaryObserver()
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        isPlaying = false
        isLoaded = false
        currentTime = 0
        duration = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Visualizador de onda de audio

struct WaveformView: View {
    let samples: [Float]
    let progress: Double          // 0...1
    var onSeek: (Double) -> Void  // fracción 0...1

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let count = samples.count
                guard count > 0 else { return }
                let spacing: CGFloat = 1
                let barW = max(1, size.width / CGFloat(count) - spacing)
                let mid = size.height / 2
                let playedColor = Color.brand
                let restColor = Color(.systemGray4)
                for (i, s) in samples.enumerated() {
                    let h = max(2, CGFloat(s) * size.height)
                    let x = CGFloat(i) * (size.width / CGFloat(count))
                    let rect = CGRect(x: x, y: mid - h / 2, width: barW, height: h)
                    let played = (Double(i) / Double(count)) <= progress
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: barW / 2),
                        with: .color(played ? playedColor : restColor)
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { v in
                    let f = min(1, max(0, v.location.x / max(1, geo.size.width)))
                    onSeek(f)
                }
            )
        }
    }
}

// Lee las muestras de audio de un archivo y las reduce a ~barras para dibujar la onda.
// El decodificado (pesado) corre en segundo plano para no congelar la interfaz.
enum WaveformLoader {
    static func load(url: URL, bars: Int = 160) async -> [Float] {
        var amplitudes = await rawAmplitudes(url: url, bars: bars)
        // Normaliza solo para DIBUJAR (la onda siempre llena la altura disponible).
        let maxV = amplitudes.max() ?? 1
        if maxV > 0 { amplitudes = amplitudes.map { min(1, $0 / maxV) } }
        return amplitudes
    }

    /// Nivel máximo REAL del audio (0 = silencio absoluto, 1 = volumen pleno).
    /// Sirve para detectar capturas en silencio antes de transcribir.
    static func peakAmplitude(url: URL) async -> Float {
        await rawAmplitudes(url: url, bars: 240).max() ?? 0
    }

    private static func rawAmplitudes(url: URL, bars: Int) async -> [Float] {
        await Task.detached(priority: .utility) {
            let asset = AVURLAsset(url: url)
            guard let tracks = try? await asset.loadTracks(withMediaType: .audio),
                  let track = tracks.first else { return [] }
            return extract(asset: asset, track: track, bars: bars)
        }.value
    }

    nonisolated private static func extract(asset: AVAsset, track: AVAssetTrack, bars: Int) -> [Float] {
        guard let reader = try? AVAssetReader(asset: asset) else { return [] }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        guard reader.startReading() else { return [] }

        var fineBuckets: [Float] = []
        let samplesPerBucket = 1024
        var sumSquares = 0.0
        var countInBucket = 0

        while reader.status == .reading {
            guard let sbuf = output.copyNextSampleBuffer() else { break }
            guard let block = CMSampleBufferGetDataBuffer(sbuf) else {
                CMSampleBufferInvalidate(sbuf); continue
            }
            let length = CMBlockBufferGetDataLength(block)
            if length > 0 {
                var data = Data(count: length)
                data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) in
                    if let base = raw.baseAddress {
                        CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: base)
                    }
                }
                data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                    let ints = raw.bindMemory(to: Int16.self)
                    for s in ints {
                        let v = Double(s) / Double(Int16.max)
                        sumSquares += v * v
                        countInBucket += 1
                        if countInBucket >= samplesPerBucket {
                            fineBuckets.append(Float((sumSquares / Double(countInBucket)).squareRoot()))
                            sumSquares = 0
                            countInBucket = 0
                        }
                    }
                }
            }
            CMSampleBufferInvalidate(sbuf)
        }
        if countInBucket > 0 {
            fineBuckets.append(Float((sumSquares / Double(countInBucket)).squareRoot()))
        }
        guard !fineBuckets.isEmpty else { return [] }

        // Devuelve amplitudes CRUDAS (sin normalizar): así sirven tanto para
        // dibujar la onda como para medir si el audio está en silencio.
        return resample(fineBuckets, to: bars)
    }

    nonisolated private static func resample(_ input: [Float], to count: Int) -> [Float] {
        guard input.count > count, count > 0 else { return input }
        var out: [Float] = []
        out.reserveCapacity(count)
        let stride = Double(input.count) / Double(count)
        for i in 0..<count {
            let startIdx = Int(Double(i) * stride)
            let endIdx = min(input.count, max(startIdx + 1, Int(Double(i + 1) * stride)))
            var maxV: Float = 0
            for j in startIdx..<endIdx { maxV = max(maxV, input[j]) }
            out.append(maxV)
        }
        return out
    }
}
