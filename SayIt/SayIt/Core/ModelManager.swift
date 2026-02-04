import Foundation

final class ModelManager {
    private let rootURL: URL
    private let modelsDirName = "Models"

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
}
