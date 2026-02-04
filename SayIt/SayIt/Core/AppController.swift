import AppKit
import AVFoundation
import Combine
import CoreAudio
import Foundation

final class AppController: ObservableObject {
    @Published private(set) var state = AppState()
    @Published private(set) var micDevices: [AudioInputDevice] = []
    @Published private(set) var selectedMicID: AudioDeviceID?

    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager
    private let audioCaptureEngine: AudioCaptureEngineProtocol
    private let transcriptionEngine: TranscriptionEngine
    private let clipboardManager: ClipboardManager
    private let hudManager: HUDManager
    private let settingsWindowController: SettingsWindowControlling
    private let hotkeyManager: HotkeyManaging
    private let settingsUserDefaults: UserDefaults
    private let modelManager: ModelManager
    private let modelDownloader: ModelDownloader
    private var cancellables: Set<AnyCancellable> = []
    private let languageKey = "transcriptionLanguage"
    private var hotkeyCancellable: AnyCancellable?

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager(),
        audioCaptureEngine: AudioCaptureEngineProtocol = AudioCaptureEngine(),
        transcriptionEngine: TranscriptionEngine = AppleSpeechEngine(),
        clipboardManager: ClipboardManager = ClipboardManager(),
        hudManager: HUDManager = HUDManager(),
        settingsWindowController: SettingsWindowControlling = SettingsWindowController(),
        hotkeyManager: HotkeyManaging = HotkeyManager(),
        settingsUserDefaults: UserDefaults = .standard,
        autoRequestPermissions: Bool = true,
        modelManager: ModelManager = ModelManager(),
        modelDownloader: ModelDownloader = ModelDownloader()
    ) {
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager
        self.audioCaptureEngine = audioCaptureEngine
        self.transcriptionEngine = transcriptionEngine
        self.clipboardManager = clipboardManager
        self.hudManager = hudManager
        self.settingsWindowController = settingsWindowController
        self.hotkeyManager = hotkeyManager
        self.settingsUserDefaults = settingsUserDefaults
        self.modelManager = modelManager
        self.modelDownloader = modelDownloader
        self.micDevices = audioDeviceManager.devices
        self.selectedMicID = audioDeviceManager.selectedDeviceID
        audioDeviceManager.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.micDevices = devices
            }
            .store(in: &cancellables)
        audioDeviceManager.$selectedDeviceID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                self?.selectedMicID = selected
            }
            .store(in: &cancellables)
        if autoRequestPermissions {
            self.permissionManager.requestPermissionsIfNeeded()
        }
        HotkeyStorage.ensureDefaults(in: settingsUserDefaults)
        registerHotkey()
        hotkeyCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: settingsUserDefaults)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.registerHotkey()
            }
    }

    func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            guard permissionManager.isAuthorized else {
                state.mode = .error(.permissionDenied)
                state.phaseDetail = nil
                return
            }
            print("SayIt: startRecording requested. selectedMicID=\(String(describing: audioDeviceManager.selectedDeviceID)) name=\(selectedMicName)")
            do {
                state.phaseDetail = .connecting
                state.recordingStartedAt = nil
                state.transcribingStartedAt = nil
                state.audioLevel = 0
                audioCaptureEngine.onFirstBuffer = { [weak self] in
                    guard let self else { return }
                    if self.state.mode == .recording {
                        print("SayIt: first audio buffer received. recordingStartAt set.")
                        self.state.phaseDetail = .recording
                        self.state.recordingStartedAt = Date()
                    }
                }
                audioCaptureEngine.onLevelUpdate = { [weak self] level in
                    guard let self else { return }
                    if self.state.mode == .recording {
                        self.state.audioLevel = level
                    }
                }
                try audioCaptureEngine.start(deviceID: audioDeviceManager.selectedDeviceID)
                state.mode = .recording
            } catch {
                print("SayIt: audioCaptureEngine.start failed: \(error)")
                state.mode = .error(.captureFailed)
                state.phaseDetail = nil
            }
        case .stopAndTranscribe:
            guard case .recording = state.mode else { return }
            print("SayIt: stopAndTranscribe requested.")
            state.mode = .transcribing(isSlow: false)
            state.phaseDetail = .transcribing
            state.transcribingStartedAt = Date()
            state.recordingStartedAt = nil
            state.audioLevel = 0
            Task { [weak self] in
                guard let self else { return }
                do {
                    let buffer: AVAudioPCMBuffer
                    do {
                        buffer = try self.audioCaptureEngine.stopAndFinalize()
                        print("SayIt: audioCaptureEngine.stopAndFinalize succeeded. frames=\(buffer.frameLength)")
                    } catch {
                        print("SayIt: audioCaptureEngine.stopAndFinalize failed: \(error)")
                        await MainActor.run {
                            self.state.mode = .error(.captureFailed)
                            self.state.phaseDetail = nil
                            self.state.transcribingStartedAt = nil
                            self.state.audioLevel = 0
                        }
                        return
                    }
                    let text = try await self.transcriptionEngine.transcribe(
                        buffer: buffer,
                        locale: self.transcriptionLocale()
                    )
                    await MainActor.run {
                        print("SayIt: transcription succeeded. textLength=\(text.count)")
                        _ = self.clipboardManager.write(text)
                        self.hudManager.showCopied()
                        self.state.mode = .idle
                        self.state.phaseDetail = nil
                        self.state.transcribingStartedAt = nil
                        self.state.audioLevel = 0
                    }
                } catch {
                    print("SayIt: transcription failed: \(error)")
                    await MainActor.run {
                        self.state.mode = .error(.transcriptionFailed)
                        self.state.phaseDetail = nil
                        self.state.transcribingStartedAt = nil
                        self.state.audioLevel = 0
                    }
                }
            }
        case .cancelRecording:
            audioCaptureEngine.cancel()
            state.mode = .idle
            state.phaseDetail = nil
            state.recordingStartedAt = nil
            state.transcribingStartedAt = nil
            state.audioLevel = 0
        case .retryTranscribe:
            break
        case .selectMic(let id):
            audioDeviceManager.selectDevice(id: id)
        case .openSettings:
            permissionManager.openSystemSettings()
        case .openSettingsWindow:
            Task { @MainActor in
                settingsWindowController.show()
            }
        }
    }

    func cancelModelDownload() {
        modelDownloader.cancel()
        state.modelStatus = .idle
    }

    func setHUDAnchorWindow(_ window: NSWindow?) {
        hudManager.anchorWindow = window
    }

    var selectedMicName: String {
        guard let selected = selectedMicID else { return "None" }
        return micDevices.first(where: { $0.id == selected })?.name ?? "Unknown"
    }

    private func transcriptionLocale() -> Locale {
        let stored = settingsUserDefaults.string(forKey: languageKey)
        guard let stored, !stored.isEmpty, stored != "system" else {
            return Locale.current
        }
        return Locale(identifier: stored)
    }

    private func registerHotkey() {
        let hotkey = HotkeyStorage.load(from: settingsUserDefaults)
        do {
            try hotkeyManager.register(hotkey: hotkey) { [weak self] in
                guard let self else { return }
                switch self.state.mode {
                case .idle:
                    self.send(.startRecording)
                case .recording:
                    self.send(.stopAndTranscribe)
                default:
                    break
                }
            }
        } catch {
            // TODO: surface hotkey registration failure
        }
    }
}
