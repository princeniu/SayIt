import AVFoundation
import Foundation
import whisper

enum WhisperCppError: Error {
    case invalidModel
    case inferenceFailed
    case conversionFailed
}

final class WhisperCppContext {
    private let context: OpaquePointer

    init(modelURL: URL) throws {
        let params = whisper_context_default_params()
        guard let context = whisper_init_from_file_with_params(modelURL.path, params) else {
            throw WhisperCppError.invalidModel
        }
        self.context = context
    }

    deinit {
        whisper_free(context)
    }

    func transcribe(samples: [Float], languageCode: String) throws -> String {
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.translate = false
        params.no_context = true
        params.single_segment = false
        params.n_threads = Int32(max(1, min(8, ProcessInfo.processInfo.activeProcessorCount - 2)))

        let result = languageCode.withCString { code in
            params.language = code
            return whisper_full(context, params, samples, Int32(samples.count))
        }

        guard result == 0 else {
            throw WhisperCppError.inferenceFailed
        }

        var text = ""
        let count = whisper_full_n_segments(context)
        for index in 0..<count {
            text += String(cString: whisper_full_get_segment_text(context, index))
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum WhisperAudioConverter {
    static func toMono16kFloat(_ buffer: AVAudioPCMBuffer) throws -> [Float] {
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

        let convertedBuffer: AVAudioPCMBuffer
        if buffer.format == targetFormat {
            convertedBuffer = buffer
        } else {
            guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
                throw WhisperCppError.conversionFailed
            }
            let frameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate)
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
                throw WhisperCppError.conversionFailed
            }
            var error: NSError?
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if error != nil {
                throw WhisperCppError.conversionFailed
            }
            convertedBuffer = outputBuffer
        }

        guard let channelData = convertedBuffer.floatChannelData?.pointee else {
            throw WhisperCppError.conversionFailed
        }
        let frameLength = Int(convertedBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    }
}
