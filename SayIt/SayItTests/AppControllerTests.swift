import AppKit
import CoreAudio
import Foundation
import Testing
@testable import SayIt

@Test func startRecording_fromIdle_setsRecordingState() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
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
        autoRequestPermissions: false
    )
    #expect(controller.state.mode == AppMode.idle)

    controller.send(AppIntent.startRecording)

    #expect(controller.state.mode == AppMode.recording)
    #expect(audioCaptureEngine.startCalled == true)
}

@Test func stopAndTranscribe_copiesAndReturnsIdle() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
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
        autoRequestPermissions: false
    )

    NSPasteboard.general.clearContents()
    controller.send(AppIntent.startRecording)
    controller.send(AppIntent.stopAndTranscribe)

    for _ in 0..<50 {
        if controller.state.mode == .idle {
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    #expect(transcriptionEngine.transcribeCalled == true)
    #expect(audioCaptureEngine.stopCalled == true)
    #expect(controller.state.mode == AppMode.idle)
    #expect(NSPasteboard.general.string(forType: .string) == "hello")
}

@Test func startRecording_usesSelectedDevice() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
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
        autoRequestPermissions: false
    )

    controller.send(AppIntent.startRecording)

    #expect(audioCaptureEngine.lastStartDeviceID == deviceID)
}
