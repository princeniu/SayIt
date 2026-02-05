import AppKit
import CoreAudio
import XCTest
@testable import SayIt

@MainActor
final class AppControllerFlowTests: XCTestCase {
    func test_startRecording_callsAudioCaptureEngineStart() {
        let suite = UserDefaults(suiteName: "AppControllerFlowTests")
        suite?.removePersistentDomain(forName: "AppControllerFlowTests")
        let audioCaptureEngine = TestAudioCaptureEngine()
        let permissionManager = PermissionManager(
            micStatus: .authorized,
            speechStatus: .authorized,
            userDefaults: suite ?? .standard,
            useSystemStatus: false
        )
        let controller = AppController(
            permissionManager: permissionManager,
            audioDeviceManager: AudioDeviceManager(startMonitoring: false),
            audioCaptureEngine: audioCaptureEngine,
            transcriptionEngine: TestTranscriptionEngine(),
            settingsUserDefaults: suite ?? .standard,
            autoRequestPermissions: false
        )

        controller.send(.startRecording)

        XCTAssertEqual(controller.state.mode, .recording)
        XCTAssertTrue(audioCaptureEngine.startCalled)
    }

    func test_startRecording_passesSelectedDeviceToCaptureEngine() {
        let suite = UserDefaults(suiteName: "AppControllerFlowTests")
        suite?.removePersistentDomain(forName: "AppControllerFlowTests")
        let audioCaptureEngine = TestAudioCaptureEngine()
        let permissionManager = PermissionManager(
            micStatus: .authorized,
            speechStatus: .authorized,
            userDefaults: suite ?? .standard,
            useSystemStatus: false
        )
        let deviceID: AudioDeviceID = 123
        let deviceManager = AudioDeviceManager(
            devices: [AudioInputDevice(id: deviceID, name: "iPhone Mic")],
            selectedDeviceID: deviceID,
            startMonitoring: false
        )
        let controller = AppController(
            permissionManager: permissionManager,
            audioDeviceManager: deviceManager,
            audioCaptureEngine: audioCaptureEngine,
            transcriptionEngine: TestTranscriptionEngine(),
            settingsUserDefaults: suite ?? .standard,
            autoRequestPermissions: false
        )

        controller.send(.startRecording)

        XCTAssertEqual(audioCaptureEngine.lastStartDeviceID, deviceID)
    }

    func test_firstRun_showsPermissionsPromptBeforeRecording() {
        let suite = UserDefaults(suiteName: "AppControllerFlowTests")
        suite?.removePersistentDomain(forName: "AppControllerFlowTests")
        let audioCaptureEngine = TestAudioCaptureEngine()
        let permissionManager = PermissionManager(
            micStatus: .unknown,
            speechStatus: .unknown,
            userDefaults: suite ?? .standard,
            useSystemStatus: false
        )
        let controller = AppController(
            permissionManager: permissionManager,
            audioDeviceManager: AudioDeviceManager(startMonitoring: false),
            audioCaptureEngine: audioCaptureEngine,
            transcriptionEngine: TestTranscriptionEngine(),
            settingsUserDefaults: suite ?? .standard,
            autoRequestPermissions: false
        )

        controller.send(.startRecording)

        XCTAssertFalse(audioCaptureEngine.startCalled)
        XCTAssertEqual(controller.state.mode, .error(.permissionDenied))
        XCTAssertEqual(controller.state.phaseDetail, .needsPermissions)
    }

    func test_stopAndTranscribe_copiesAndReturnsIdle() async throws {
        let suite = UserDefaults(suiteName: "AppControllerFlowTests")
        suite?.removePersistentDomain(forName: "AppControllerFlowTests")
        let audioCaptureEngine = TestAudioCaptureEngine()
        let transcriptionEngine = TestTranscriptionEngine(result: "hello")
        let permissionManager = PermissionManager(
            micStatus: .authorized,
            speechStatus: .authorized,
            userDefaults: suite ?? .standard,
            useSystemStatus: false
        )
        let controller = AppController(
            permissionManager: permissionManager,
            audioDeviceManager: AudioDeviceManager(startMonitoring: false),
            audioCaptureEngine: audioCaptureEngine,
            transcriptionEngine: transcriptionEngine,
            settingsUserDefaults: suite ?? .standard,
            autoRequestPermissions: false
        )

        NSPasteboard.general.clearContents()
        controller.send(.startRecording)
        controller.send(.stopAndTranscribe)

        for _ in 0..<50 {
            if controller.state.mode == .idle {
                break
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTAssertTrue(transcriptionEngine.transcribeCalled)
        XCTAssertTrue(audioCaptureEngine.stopCalled)
        XCTAssertEqual(controller.state.mode, .idle)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "hello")
    }
}
