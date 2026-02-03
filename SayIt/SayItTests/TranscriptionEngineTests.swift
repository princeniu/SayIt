import AVFoundation
import Testing
@testable import SayIt

@Test func transcriptionEngine_returnsEmptyStringForEmptyBuffer() async throws {
    let engine: TranscriptionEngine = AppleSpeechEngine()
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1)!
    buffer.frameLength = 0

    let result = try await engine.transcribe(buffer: buffer, locale: Locale(identifier: "en_US"))
    #expect(result.isEmpty)
}
