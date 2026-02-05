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
            return NSLocalizedString("Ready to Record", comment: "Status: Ready")
        case .recording:
            return NSLocalizedString("Recording…", comment: "Status: Recording")
        case .transcribing:
            return NSLocalizedString("Transcribing…", comment: "Status: Transcribing")
        case .error:
            return NSLocalizedString("Error", comment: "Status: Error")
        }
    }
    
    var secondaryStatusText: String? {
        switch state.mode {
        case .idle:
            return String(format: NSLocalizedString("Mic: %@", comment: "Microphone name"), selectedMicName)
        case .recording:
            return nil
        case .transcribing(let isSlow):
            return isSlow ? NSLocalizedString("This is taking longer than usual…", comment: "Slow transcription") : NSLocalizedString("Processing audio…", comment: "Processing")
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
        case .permissionDenied: return NSLocalizedString("Check permissions", comment: "Error: Permissions")
        case .captureFailed: return NSLocalizedString("Audio input unavailable", comment: "Error: Capture")
        case .transcriptionFailed: return NSLocalizedString("Transcription failed", comment: "Error: Transcription")
        }
    }
}
