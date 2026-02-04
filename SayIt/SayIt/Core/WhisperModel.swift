import Foundation

enum WhisperModelType: String, CaseIterable, Codable {
    case tiny
    case base
    case small
}

struct WhisperModelSpec: Codable, Equatable {
    let type: WhisperModelType
    let fileName: String
    let expectedSize: Int64
    let sha256: String
    let version: String
}
