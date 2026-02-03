import AVFoundation

final class WhisperEngine: TranscriptionEngine {
    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        throw TranscriptionError.notImplemented
    }
}
