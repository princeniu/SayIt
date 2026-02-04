import Foundation

final class ModelManager {
    private let rootURL: URL
    private let modelsDirName = "Models"
    private let remoteBaseURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

    init(rootURL: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!) {
        self.rootURL = rootURL
    }

    func modelsDirectory() -> URL {
        rootURL.appendingPathComponent("SayIt").appendingPathComponent(modelsDirName)
    }

    func localURL(for type: WhisperModelType) -> URL {
        modelsDirectory().appendingPathComponent("\(type.rawValue).bin")
    }

    func isModelReady(_ type: WhisperModelType) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: type).path)
    }

    func remoteURL(for type: WhisperModelType) -> URL {
        URL(string: "\(remoteBaseURL)/ggml-\(type.rawValue).bin")!
    }

    func ensureModelsDirectory() throws {
        let directory = modelsDirectory()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
