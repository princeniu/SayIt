import Foundation

enum TranscriptionEngineType: String, CaseIterable, Codable {
    case system
    case whisper

    var displayTitle: String {
        switch self {
        case .system:
            return "Apple Speech"
        case .whisper:
            return "Whisper"
        }
    }
}
