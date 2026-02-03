import Foundation
import Testing
@testable import SayIt

@Test func startRecording_fromIdle_setsRecordingState() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    let permissionManager = PermissionManager(
        micStatus: .authorized,
        speechStatus: .authorized,
        userDefaults: suite ?? .standard,
        useSystemStatus: false
    )
    let controller = AppController(permissionManager: permissionManager)
    #expect(controller.state.mode == AppMode.idle)

    controller.send(AppIntent.startRecording)

    #expect(controller.state.mode == AppMode.recording)
}
