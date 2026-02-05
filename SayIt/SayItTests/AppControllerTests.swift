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
        settingsUserDefaults: suite ?? .standard,
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
        settingsUserDefaults: suite ?? .standard,
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
        settingsUserDefaults: suite ?? .standard,
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
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    controller.send(AppIntent.startRecording)
    audioCaptureEngine.simulateFirstBuffer()
    controller.send(AppIntent.stopAndTranscribe)

    #expect(controller.state.phaseDetail == .transcribing)
    #expect(controller.state.transcribingStartedAt != nil)
}

@Test func stopAndTranscribe_setsCopiedPhaseThenClears() async throws {
    let suiteName = "AppControllerTests.stopAndTranscribe_setsCopiedPhaseThenClears"
    let suite = UserDefaults(suiteName: suiteName) ?? .standard
    suite.removePersistentDomain(forName: suiteName)
    suite.set(TranscriptionEngineType.system.rawValue, forKey: "transcriptionEngine")
    let audioCaptureEngine = TestAudioCaptureEngine()
    let transcriptionEngine = TestTranscriptionEngine(result: "hello")
    let permissionManager = PermissionManager(
        micStatus: .authorized,
        speechStatus: .authorized,
        userDefaults: suite,
        useSystemStatus: false
    )
    let controller = AppController(
        permissionManager: permissionManager,
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: audioCaptureEngine,
        transcriptionEngine: transcriptionEngine,
        settingsUserDefaults: suite,
        autoRequestPermissions: false,
        hudDisplayDuration: 0.1
    )

    controller.send(.startRecording)
    controller.send(.stopAndTranscribe)

    for _ in 0..<50 {
        if controller.state.mode == .idle {
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    #expect(controller.state.phaseDetail == .copied)
    try await Task.sleep(nanoseconds: 200_000_000)
    #expect(controller.state.phaseDetail == nil)
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
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    controller.send(AppIntent.startRecording)

    #expect(audioCaptureEngine.lastStartDeviceID == deviceID)
}

@Test func stopAndTranscribe_usesConfiguredLanguage() async throws {
    let suiteName = "AppControllerTests.stopAndTranscribe_usesConfiguredLanguage"
    let suite = UserDefaults(suiteName: suiteName) ?? .standard
    suite.removePersistentDomain(forName: suiteName)
    suite.set(TranscriptionEngineType.system.rawValue, forKey: "transcriptionEngine")
    suite.set("zh-Hans", forKey: "transcriptionLanguage")
    #expect(suite.string(forKey: "transcriptionLanguage") == "zh-Hans")
    let audioCaptureEngine = TestAudioCaptureEngine()
    let transcriptionEngine = TestTranscriptionEngine(result: "hello")
    let permissionManager = PermissionManager(
        micStatus: .authorized,
        speechStatus: .authorized,
        userDefaults: suite,
        useSystemStatus: false
    )
    let controller = AppController(
        permissionManager: permissionManager,
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: audioCaptureEngine,
        transcriptionEngine: transcriptionEngine,
        settingsUserDefaults: suite,
        autoRequestPermissions: false
    )
    controller.setEngine(.system)

    controller.send(AppIntent.startRecording)
    controller.send(AppIntent.stopAndTranscribe)

    for _ in 0..<50 {
        if controller.state.mode == .idle {
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    #expect(transcriptionEngine.lastLocaleIdentifier?.hasPrefix("zh") == true)
}

@Test func openSettingsWindow_showsSettings() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests") ?? .standard
    suite.removePersistentDomain(forName: "AppControllerTests")
    let settingsWindow = TestSettingsWindowController()
    let permissionManager = PermissionManager(
        micStatus: .authorized,
        speechStatus: .authorized,
        userDefaults: suite,
        useSystemStatus: false
    )
    let controller = AppController(
        permissionManager: permissionManager,
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: TestAudioCaptureEngine(),
        transcriptionEngine: TestTranscriptionEngine(),
        settingsWindowController: settingsWindow,
        settingsUserDefaults: suite,
        autoRequestPermissions: false
    )

    controller.send(.openSettingsWindow)

    for _ in 0..<50 {
        if settingsWindow.showCalled {
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    #expect(settingsWindow.showCalled == true)
}

@Test func hotkeyToggle_fromIdle_startsRecording() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    let audioCaptureEngine = TestAudioCaptureEngine()
    let hotkeyManager = TestHotkeyManager()
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
        hotkeyManager: hotkeyManager,
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    hotkeyManager.simulateToggle()

    #expect(audioCaptureEngine.startCalled == true)
    #expect(controller.state.mode == AppMode.recording)
}

@Test func hotkeyRegister_usesDefaultHotkeyWhenMissing() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    let hotkeyManager = TestHotkeyManager()

    _ = AppController(
        permissionManager: PermissionManager(micStatus: .authorized, speechStatus: .authorized, userDefaults: suite ?? .standard, useSystemStatus: false),
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: TestAudioCaptureEngine(),
        transcriptionEngine: TestTranscriptionEngine(),
        hotkeyManager: hotkeyManager,
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    #expect(hotkeyManager.lastRegisteredHotkey == Hotkey.defaultValue)
}

@Test func hotkeyChange_reRegistersWithNewHotkey() async throws {
    let suite = UserDefaults(suiteName: "AppControllerTests")
    suite?.removePersistentDomain(forName: "AppControllerTests")
    let hotkeyManager = TestHotkeyManager()

    _ = AppController(
        permissionManager: PermissionManager(micStatus: .authorized, speechStatus: .authorized, userDefaults: suite ?? .standard, useSystemStatus: false),
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: TestAudioCaptureEngine(),
        transcriptionEngine: TestTranscriptionEngine(),
        hotkeyManager: hotkeyManager,
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    let newHotkey = Hotkey(
        keyCode: 6,
        modifiers: HotkeyModifiers(option: true, command: false, control: false, shift: false),
        display: "⌥Z"
    )
    HotkeyStorage.save(newHotkey, into: suite ?? .standard)
    NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: suite)

    #expect(hotkeyManager.lastRegisteredHotkey == newHotkey)
}

@Test func audioLevel_updatesDuringRecording() async throws {
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
        settingsUserDefaults: suite ?? .standard,
        autoRequestPermissions: false
    )

    controller.send(.startRecording)
    audioCaptureEngine.simulateLevel(0.42)

    #expect(controller.state.audioLevel == 0.42)
}

@Test func transcribing_showsSlowStatus_afterDelay() async throws {
    let suiteName = "AppControllerTests.transcribing_showsSlowStatus_afterDelay"
    let suite = UserDefaults(suiteName: suiteName) ?? .standard
    suite.removePersistentDomain(forName: suiteName)
    
    // Use a transcription engine that hangs/delays
    let transcriptionEngine = TestTranscriptionEngine(delay: 5.0, result: "hello")
    
    let controller = AppController(
        permissionManager: PermissionManager(micStatus: .authorized, speechStatus: .authorized, userDefaults: suite, useSystemStatus: false),
        audioDeviceManager: AudioDeviceManager(startMonitoring: false),
        audioCaptureEngine: TestAudioCaptureEngine(),
        transcriptionEngine: transcriptionEngine,
        settingsUserDefaults: suite,
        autoRequestPermissions: false
    )

    controller.send(AppIntent.startRecording)
    controller.send(AppIntent.stopAndTranscribe) // Starts 3s timer

    // Verify initial state is fast
    #expect(controller.state.mode == AppMode.transcribing(isSlow: false))

    // Wait for timer to fire (3.0s) + small buffer, but before transcription completes (5.0s)
    try await Task.sleep(nanoseconds: 3_200_000_000)

    // Check if state updated to slow
    if case .transcribing(let isSlow) = controller.state.mode {
        #expect(isSlow == true)
    } else {
        #expect(Bool(false), "Mode should be transcribing")
    }
}

final class TestSettingsWindowController: SettingsWindowControlling {
    private(set) var showCalled = false

    @MainActor func show(appController: AppController) {
        showCalled = true
    }
}

final class TestHotkeyManager: HotkeyManaging {
    private(set) var registerCalled = false
    private(set) var unregisterCalled = false
    private(set) var lastRegisteredHotkey: Hotkey?
    private var handler: (() -> Void)?

    func register(hotkey: Hotkey, toggleHandler: @escaping () -> Void) throws {
        registerCalled = true
        lastRegisteredHotkey = hotkey
        handler = toggleHandler
    }

    func unregister() {
        unregisterCalled = true
    }

    func simulateToggle() {
        handler?()
    }
}
