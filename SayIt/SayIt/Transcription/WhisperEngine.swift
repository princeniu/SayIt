import AVFoundation
import Foundation

final class WhisperEngine: TranscriptionEngine {
    private let modelProvider: (WhisperModelType) -> URL?
    private let modelType: WhisperModelType

    init(modelType: WhisperModelType = .small, modelProvider: @escaping (WhisperModelType) -> URL? = { _ in nil }) {
        self.modelType = modelType
        self.modelProvider = modelProvider
    }

    func transcribe(buffer: AVAudioPCMBuffer, locale: Locale) async throws -> String {
        guard let modelURL = modelProvider(modelType) else {
            throw NSError(domain: "Whisper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not ready"])
        }

        let samples = try WhisperAudioConverter.toMono16kFloat(buffer)
        let languageCode = locale.identifier == "auto"
            ? "auto"
            : (locale.language.languageCode?.identifier ?? "en")

        return try await Task.detached(priority: .userInitiated) {
            let context = try WhisperCppContext(modelURL: modelURL)
            return try context.transcribe(samples: samples, languageCode: languageCode)
        }.value
    }
}
