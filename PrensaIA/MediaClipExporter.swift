//
//  MediaClipExporter.swift
//  PrensaIA
//
//  Exportador de cortes como clips de video o audio.
//

import Foundation
import AVFoundation
import CoreMedia

// MARK: - Exportador de cortes (clips de video o audio)

enum MediaClipExporter {
    // Exporta cada bloque seleccionado como un archivo independiente.
    static func exportSeparate(
        media: URL,
        blocks: [BloqueTema],
        isVideo: Bool,
        progress: @escaping (Double) -> Void
    ) async -> [URL] {
        let asset = AVURLAsset(url: media)
        let total = await assetDuration(asset)
        var urls: [URL] = []
        for (i, b) in blocks.enumerated() {
            if let u = try? await exportOne(
                asset: asset, start: b.inicio, end: b.fin,
                totalDuration: total, index: i, name: b.tema, isVideo: isVideo
            ) {
                urls.append(u)
            }
            progress(Double(i + 1) / Double(blocks.count))
        }
        return urls
    }

    // Une los bloques seleccionados en un solo archivo nuevo, en orden cronológico.
    static func exportMerged(media: URL, blocks: [BloqueTema], isVideo: Bool) async -> URL? {
        let asset = AVURLAsset(url: media)
        let total = await assetDuration(asset)
        guard let srcAudio = try? await asset.loadTracks(withMediaType: .audio).first else { return nil }

        let comp = AVMutableComposition()
        let compAudio = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        var compVideo: AVMutableCompositionTrack?
        var srcVideo: AVAssetTrack?
        if isVideo, let v = try? await asset.loadTracks(withMediaType: .video).first {
            srcVideo = v
            compVideo = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        }

        let ordered = blocks.sorted { $0.inicio < $1.inicio }
        var cursor = CMTime.zero
        for b in ordered {
            let start = max(0, min(b.inicio, total))
            let end = max(start, min(b.fin, total))
            guard end > start else { continue }
            let range = CMTimeRange(
                start: CMTime(seconds: start, preferredTimescale: 600),
                end: CMTime(seconds: end, preferredTimescale: 600)
            )
            try? compAudio?.insertTimeRange(range, of: srcAudio, at: cursor)
            if let cv = compVideo, let sv = srcVideo {
                try? cv.insertTimeRange(range, of: sv, at: cursor)
            }
            cursor = cursor + range.duration
        }
        guard cursor > .zero else { return nil }

        if let sv = srcVideo, let cv = compVideo,
           let transform = try? await sv.load(.preferredTransform) {
            cv.preferredTransform = transform
        }

        let ext = isVideo ? "mp4" : "m4a"
        let fileType: AVFileType = isVideo ? .mp4 : .m4a
        let preset = isVideo ? AVAssetExportPresetHighestQuality : AVAssetExportPresetAppleM4A
        guard let export = AVAssetExportSession(asset: comp, presetName: preset) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrensaIA-cortes-\(UUID().uuidString.prefix(6)).\(ext)")
        try? FileManager.default.removeItem(at: url)
        do {
            try await export.export(to: url, as: fileType)
            return url
        } catch {
            return nil
        }
    }

    private static func exportOne(
        asset: AVAsset, start: Double, end: Double, totalDuration: Double,
        index: Int, name: String, isVideo: Bool
    ) async throws -> URL {
        let s = max(0, min(start, totalDuration))
        let e = max(s, min(end, totalDuration))
        let ext = isVideo ? "mp4" : "m4a"
        let fileType: AVFileType = isVideo ? .mp4 : .m4a
        let preset = isVideo ? AVAssetExportPresetHighestQuality : AVAssetExportPresetAppleM4A
        guard let export = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw NSError(domain: "PrensaIA", code: 2)
        }
        export.timeRange = CMTimeRange(
            start: CMTime(seconds: s, preferredTimescale: 600),
            end: CMTime(seconds: e, preferredTimescale: 600)
        )
        let safe = sanitize(name)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safe)-\(index + 1).\(ext)")
        try? FileManager.default.removeItem(at: url)
        try await export.export(to: url, as: fileType)
        return url
    }

    private static func assetDuration(_ asset: AVAsset) async -> Double {
        if let d = try? await asset.load(.duration) {
            let secs = CMTimeGetSeconds(d)
            return secs.isFinite && secs > 0 ? secs : .greatestFiniteMagnitude
        }
        return .greatestFiniteMagnitude
    }

    private static func sanitize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Corte" : trimmed
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let clean = base.components(separatedBy: invalid).joined(separator: "-")
        return String(clean.prefix(40))
    }
}
