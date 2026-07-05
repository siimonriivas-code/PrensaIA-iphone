//
//  SampleHandler.swift
//  PrensaLiveCapture
//
//  Captura el audio de las apps (p. ej. un Facebook Live) durante una grabación
//  de pantalla y lo guarda como WAV 16 kHz mono en el App Group, para que
//  PrensaIA lo transcriba. Es ligero a propósito: solo convierte y escribe audio
//  (las extensiones de broadcast tienen un límite de memoria muy chico).
//

import ReplayKit
import AVFoundation

class SampleHandler: RPBroadcastSampleHandler {

    private let appGroup = "group.com.simonrivas.Prensa.PrensaIA"
    private let lock = NSLock()
    private var fileHandle: FileHandle?
    private var bytesWritten = 0
    private var converter: AVAudioConverter?
    private let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                             sampleRate: 16000,
                                             channels: 1,
                                             interleaved: true)!

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    private var wavURL: URL? {
        containerURL?.appendingPathComponent("liveCapture.wav")
    }

    // MARK: Ciclo de vida del broadcast

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        guard let url = wavURL else { return }
        try? FileManager.default.removeItem(at: url)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        fileHandle = try? FileHandle(forWritingTo: url)
        bytesWritten = 0
        writeHeader(dataLength: 0)   // cabecera inicial; se actualiza en cada bloque
        writeStatus("recording")
    }

    override func broadcastPaused() {}
    override func broadcastResumed() {}

    override func broadcastFinished() {
        lock.lock()
        if let fileHandle {
            try? fileHandle.seek(toOffset: 0)
            try? fileHandle.write(contentsOf: wavHeader(dataLength: bytesWritten))
            try? fileHandle.close()
        }
        fileHandle = nil
        writeStatus("finished")
        lock.unlock()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                      with sampleBufferType: RPSampleBufferType) {
        // Solo el audio de las apps (el del Facebook Live). Ignoramos video y micrófono.
        guard sampleBufferType == .audioApp else { return }
        append(sampleBuffer)
    }

    // MARK: Conversión y escritura

    private func append(_ sampleBuffer: CMSampleBuffer) {
        guard let fmtDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc) else { return }
        var asbd = asbdPtr.pointee
        guard let inFormat = AVAudioFormat(streamDescription: &asbd) else { return }

        let frames = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frames > 0,
              let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frames) else { return }
        inBuffer.frameLength = frames
        let copyStatus = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer, at: 0, frameCount: Int32(frames),
            into: inBuffer.mutableAudioBufferList)
        guard copyStatus == noErr else { return }

        if converter == nil {
            converter = AVAudioConverter(from: inFormat, to: outputFormat)
        }
        guard let converter else { return }

        let ratio = outputFormat.sampleRate / inFormat.sampleRate
        let outCapacity = AVAudioFrameCount(Double(frames) * ratio) + 1024
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outCapacity) else { return }

        var fed = false
        var error: NSError?
        converter.convert(to: outBuffer, error: &error) { _, inStatus in
            if fed { inStatus.pointee = .noDataNow; return nil }
            fed = true
            inStatus.pointee = .haveData
            return inBuffer
        }
        guard error == nil,
              outBuffer.frameLength > 0,
              let channel = outBuffer.int16ChannelData else { return }

        let count = Int(outBuffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: channel[0], count: count)

        lock.lock()
        if let fileHandle {
            try? fileHandle.seekToEnd()
            try? fileHandle.write(contentsOf: data)
            bytesWritten += data.count
            // Mantiene la cabecera válida por si transcribes a mitad de captura.
            try? fileHandle.seek(toOffset: 0)
            try? fileHandle.write(contentsOf: wavHeader(dataLength: bytesWritten))
        }
        lock.unlock()
    }

    // MARK: Utilidades WAV

    private func writeHeader(dataLength: Int) {
        guard let fileHandle else { return }
        try? fileHandle.seek(toOffset: 0)
        try? fileHandle.write(contentsOf: wavHeader(dataLength: dataLength))
    }

    private func wavHeader(dataLength: Int) -> Data {
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bits: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bits / 8)
        let blockAlign = channels * (bits / 8)
        let dataLen = UInt32(truncatingIfNeeded: dataLength)
        let chunkSize = UInt32(36) + dataLen

        var header = Data()
        func str(_ s: String) { header.append(contentsOf: Array(s.utf8)) }
        func u32(_ v: UInt32) { var x = v.littleEndian; withUnsafeBytes(of: &x) { header.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var x = v.littleEndian; withUnsafeBytes(of: &x) { header.append(contentsOf: $0) } }

        str("RIFF"); u32(chunkSize); str("WAVE")
        str("fmt "); u32(16); u16(1); u16(channels)
        u32(sampleRate); u32(byteRate); u16(blockAlign); u16(bits)
        str("data"); u32(dataLen)
        return header
    }

    private func writeStatus(_ status: String) {
        guard let url = containerURL?.appendingPathComponent("liveStatus.txt") else { return }
        try? status.data(using: .utf8)?.write(to: url, options: .atomic)
    }
}
