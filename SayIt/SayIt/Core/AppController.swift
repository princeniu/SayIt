import Combine
import Foundation

final class AppController: ObservableObject {
    @Published private(set) var state = AppState()

    private let permissionManager: PermissionManager

    init(permissionManager: PermissionManager = PermissionManager()) {
        self.permissionManager = permissionManager
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
