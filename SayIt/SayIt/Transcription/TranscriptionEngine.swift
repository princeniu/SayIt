import AVFoundation

protocol TranscriptionEngine {
    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String
}

enum TranscriptionError: Error, Equatable {
    case notAuthorized
    case recognizerUnavailable
    case failed
    case notImplemented
}
