import Foundation

enum DownloadStatusViewState: Equatable {
    case hidden
    case progress(Double)
    case failed(String)
}

struct DownloadStatusViewModel {
    static func state(for status: ModelStatus) -> DownloadStatusViewState {
        switch status {
        case .downloading(let progress):
            return .progress(progress)
        case .failed(let message):
            return .failed(message)
        case .idle, .ready:
            return .hidden
        }
    }
}
