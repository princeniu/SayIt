import AVFoundation
@testable import SayIt

final class TestTranscriptionEngine: TranscriptionEngine {
    private(set) var transcribeCalled = false
    private(set) var lastLocaleIdentifier: String?
    var result: String
    private let delay: TimeInterval

    init(delay: TimeInterval = 0, result: String = "") {
        self.delay = delay
        self.result = result
    }

    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        transcribeCalled = true
        lastLocaleIdentifier = locale.identifier
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return result
    }
}
