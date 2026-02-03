import Combine
import Foundation

final class AppController: ObservableObject {
    @Published private(set) var state = AppState()

    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager()
    ) {
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager
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
