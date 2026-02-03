import Foundation

public enum AppMode: Equatable {
    case idle
    case recording
    case transcribing(isSlow: Bool)
    case error(AppError)
}

public struct AppState: Equatable {
    public var mode: AppMode = .idle
}

public enum AppError: Equatable {
    case permissionDenied
}
