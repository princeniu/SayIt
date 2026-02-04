import Foundation

enum TranscriptionEngineType: String, CaseIterable, Codable {
    case system
    case whisper

    var displayTitle: String {
        switch self {
        case .system:
            return "System (Recommended)"
        case .whisper:
            return "High Accuracy (Offline) • Pro"
        }
    }
}
