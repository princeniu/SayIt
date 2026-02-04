import Testing
import AVFoundation
@testable import SayIt

struct WhisperEngineTests {
    @Test func transcribe_requiresModelReady() async throws {
        let engine = WhisperEngine()
        let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!,
            frameCapacity: 1
        )!
        await #expect(throws: Error.self) {
            _ = try await engine.transcribe(buffer: buffer, locale: Locale.current)
        }
    }
}
