import Foundation

public enum AppMode: Equatable {
    case idle
    case recording
    case transcribing(isSlow: Bool)
    case error(AppError)
}

public struct AppState: Equatable {
    public var mode: AppMode = .idle

    func statusDetail(selectedMic: String) -> String {
        switch mode {
        case .idle:
            return "Mic: \(selectedMic)"
        case .recording:
            return "Tap to stop"
        case .transcribing:
            return "Working…"
        case .error(let error):
            switch error {
            case .permissionDenied:
                return "Check permissions"
            case .captureFailed:
                return "Audio input unavailable"
            case .transcriptionFailed:
                return "Transcription failed"
            }
        }
    }
}

public enum AppError: Equatable {
    case permissionDenied
    case captureFailed
    case transcriptionFailed
}
