import AVFoundation
import Foundation
import Testing
@testable import SayIt

struct WhisperIntegrationTests {
    @Test func transcribe_jfkSample_returnsEnglishText() async throws {
        let fixturesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        let wavURL = fixturesURL.appendingPathComponent("jfk.wav")
        let file = try AVAudioFile(forReading: wavURL)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        try file.read(into: buffer)

        let modelURL = WhisperIntegrationTests.resolveModelURL()
        guard let modelURL else {
            print("Whisper model not found. Set SAYIT_WHISPER_MODEL_PATH to run this test.")
            return
        }

        let engine = WhisperEngine(modelType: .small, modelProvider: { _ in modelURL })
        let text = try await engine.transcribe(buffer: buffer, locale: Locale(identifier: "en-US"))

        #expect(text.isEmpty == false)
    }

    private static func resolveModelURL() -> URL? {
        if let path = ProcessInfo.processInfo.environment["SAYIT_WHISPER_MODEL_PATH"] {
            return URL(fileURLWithPath: path)
        }

        let manager = ModelManager()
        let url = manager.localURL(for: .small)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
