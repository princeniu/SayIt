import Foundation
import Combine
import SwiftUI

@MainActor
final class PopoverViewModel: ObservableObject {
    @Published var state: AppState
    @Published var selectedMicName: String
    
    var primaryStatusText: String {
        switch state.mode {
        case .idle:
            return AppLanguageManager.shared.localized("Ready to Record")
        case .recording:
            return AppLanguageManager.shared.localized("Recording…")
        case .transcribing:
            return AppLanguageManager.shared.localized("Transcribing…")
        case .error:
            return AppLanguageManager.shared.localized("Error")
        }
    }
    
    var secondaryStatusText: String? {
        switch state.mode {
        case .idle:
            return String(format: AppLanguageManager.shared.localized("Mic: %@"), selectedMicName)
        case .recording:
            return nil
        case .transcribing(let isSlow):
            return isSlow
                ? AppLanguageManager.shared.localized("This is taking longer than usual…")
                : AppLanguageManager.shared.localized("Processing audio…")
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    init(state: AppState, selectedMicName: String) {
        self.state = state
        self.selectedMicName = selectedMicName
    }
    
    func update(state: AppState) {
        self.state = state
    }
    
    func update(selectedMicName: String) {
        self.selectedMicName = selectedMicName
    }
}

extension AppError {
    var localizedDescription: String {
        switch self {
        case .permissionDenied: return AppLanguageManager.shared.localized("Check permissions")
        case .captureFailed: return AppLanguageManager.shared.localized("Audio input unavailable")
        case .transcriptionFailed: return AppLanguageManager.shared.localized("Transcription failed")
        }
    }
}
