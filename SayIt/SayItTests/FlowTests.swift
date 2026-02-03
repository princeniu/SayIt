import XCTest
@testable import SayIt

@MainActor
final class FlowTests: XCTestCase {
    func test_stopTransitionsToTranscribing() {
        let suite = UserDefaults(suiteName: "FlowTests")
        suite?.removePersistentDomain(forName: "FlowTests")
        let permissionManager = PermissionManager(
            micStatus: .authorized,
            speechStatus: .authorized,
            userDefaults: suite ?? .standard,
            useSystemStatus: false
        )
        let controller = AppController(
            permissionManager: permissionManager,
            audioDeviceManager: AudioDeviceManager(startMonitoring: false),
            audioCaptureEngine: TestAudioCaptureEngine(),
            transcriptionEngine: TestTranscriptionEngine(),
            autoRequestPermissions: false
        )
        controller.send(.startRecording)
        if case .recording = controller.state.mode { } else { XCTFail("Expected recording") }
        controller.send(.stopAndTranscribe)

        if case .transcribing = controller.state.mode {
            return
        }
        XCTFail("Expected transcribing")
    }
}
