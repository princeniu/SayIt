import AVFoundation

final class WhisperEngine: TranscriptionEngine {
    private let modelProvider: (WhisperModelType) -> URL?
    private let modelType: WhisperModelType

    init(modelType: WhisperModelType = .small, modelProvider: @escaping (WhisperModelType) -> URL? = { _ in nil }) {
        self.modelType = modelType
        self.modelProvider = modelProvider
    }

    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        guard modelProvider(modelType) != nil else {
            throw NSError(domain: "Whisper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not ready"])
        }
        return ""
    }
}
