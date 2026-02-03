import Combine
import Foundation

final class AppController: ObservableObject {
    @Published private(set) var state = AppState()

    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager
    private let audioCaptureEngine: AudioCaptureEngine
    private let transcriptionEngine: TranscriptionEngine
    private let clipboardManager: ClipboardManager
    private let hudManager: HUDManager

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager(),
        audioCaptureEngine: AudioCaptureEngine = AudioCaptureEngine(),
        transcriptionEngine: TranscriptionEngine = AppleSpeechEngine(),
        clipboardManager: ClipboardManager = ClipboardManager(),
        hudManager: HUDManager = HUDManager()
    ) {
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager
        self.audioCaptureEngine = audioCaptureEngine
        self.transcriptionEngine = transcriptionEngine
        self.clipboardManager = clipboardManager
        self.hudManager = hudManager
        self.permissionManager.requestPermissionsIfNeeded()
    }

    func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            if permissionManager.isAuthorized {
                state.mode = .recording
            } else {
                state.mode = .error(.permissionDenied)
            }
        }
    }
}
