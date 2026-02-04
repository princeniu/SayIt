import Foundation

public enum AppMode: Equatable {
    case idle
    case recording
    case transcribing(isSlow: Bool)
    case error(AppError)
}

public enum PhaseDetail: Equatable {
    case connecting
    case recording
    case transcribing
    case copied
}

public enum ModelStatus: Equatable {
    case idle
    case downloading(Double)
    case ready(WhisperModelType)
    case failed(String)
}

public struct AppState: Equatable {
    public var mode: AppMode = .idle
    public var phaseDetail: PhaseDetail? = nil
    public var recordingStartedAt: Date? = nil
    public var transcribingStartedAt: Date? = nil
    public var audioLevel: Double = 0
    public var modelStatus: ModelStatus = .idle

    func statusDetail(selectedMic: String) -> String {
        switch mode {
        case .idle:
            return "Mic: \(selectedMic)"
        case .recording:
            return "Mic: \(selectedMic)"
        case .transcribing:
            return ""
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
