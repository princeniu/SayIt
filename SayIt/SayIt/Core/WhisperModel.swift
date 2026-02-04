import Foundation

public enum WhisperModelType: String, CaseIterable, Codable {
    case tiny
    case base
    case small
}

public struct WhisperModelSpec: Codable, Equatable {
    public let type: WhisperModelType
    public let fileName: String
    public let expectedSize: Int64
    public let sha256: String
    public let version: String

    public init(type: WhisperModelType, fileName: String, expectedSize: Int64, sha256: String, version: String) {
        self.type = type
        self.fileName = fileName
        self.expectedSize = expectedSize
        self.sha256 = sha256
        self.version = version
    }
}
