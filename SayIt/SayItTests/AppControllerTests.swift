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

@Test func startRecording_setsConnectingThenRecordingOnFirstBuffer() async throws {
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

    controller.send(AppIntent.startRecording)

    #expect(controller.state.phaseDetail == .connecting)
    #expect(controller.state.recordingStartedAt == nil)

    audioCaptureEngine.simulateFirstBuffer()

    #expect(controller.state.phaseDetail == .recording)
    #expect(controller.state.recordingStartedAt != nil)
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

@Test func stopAndTranscribe_setsTranscribingStart() async throws {
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

    controller.send(AppIntent.startRecording)
    audioCaptureEngine.simulateFirstBuffer()
    controller.send(AppIntent.stopAndTranscribe)

    #expect(controller.state.phaseDetail == .transcribing)
    #expect(controller.state.transcribingStartedAt != nil)
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

@Test func stopAndTranscribe_usesConfiguredLanguage() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    suite?.set("zh-Hans", forKey: "transcriptionLanguage")
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

    controller.send(AppIntent.startRecording)
    controller.send(AppIntent.stopAndTranscribe)

    for _ in 0..<50 {
        if controller.state.mode == .idle {
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    #expect(transcriptionEngine.lastLocaleIdentifier == "zh-Hans")
}

@Test func openSettingsWindow_showsSettings() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    let settingsWindow = TestSettingsWindowController()
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
        settingsWindowController: settingsWindow,
        autoRequestPermissions: false
    )

    controller.send(.openSettingsWindow)

    #expect(settingsWindow.showCalled == true)
}

final class TestSettingsWindowController: SettingsWindowControlling {
    private(set) var showCalled = false

    func show() {
        showCalled = true
    }
}
