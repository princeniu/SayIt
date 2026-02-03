import AVFoundation
@testable import SayIt

final class TestTranscriptionEngine: TranscriptionEngine {
    private(set) var transcribeCalled = false
    var result: String

    init(result: String = "") {
        self.result = result
    }

    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        transcribeCalled = true
        return result
    }
}
