import AppKit
import AVFoundation
import Combine
import CoreAudio
import Foundation

@MainActor
final class AppController: ObservableObject {
    @Published private(set) var state = AppState()
    @Published private(set) var micDevices: [AudioInputDevice] = []
    @Published private(set) var selectedMicID: AudioDeviceID?
    @Published private(set) var selectedEngine: TranscriptionEngineType

    private let permissionManager: PermissionManager
    private let audioDeviceManager: AudioDeviceManager
    private let audioCaptureEngine: AudioCaptureEngineProtocol
    private let transcriptionEngine: TranscriptionEngine
    private let whisperEngineFactory: (WhisperModelType, @escaping (WhisperModelType) -> URL?) -> TranscriptionEngine
    private let clipboardManager: ClipboardManager
    private let hudManager: HUDManager
    private let settingsWindowController: SettingsWindowControlling
    private let hotkeyManager: HotkeyManaging
    private let settingsUserDefaults: UserDefaults
    private let modelManager: ModelManager
    private let modelDownloader: ModelDownloader
    private let updater = Updater()
    private let hudDisplayDuration: TimeInterval
    private var cancellables: Set<AnyCancellable> = []
    private let languageKey = "transcriptionLanguage"
    private let engineKey = "transcriptionEngine"
    private let preferredModelKey = "whisperPreferredModel"
    private var hotkeyCancellable: AnyCancellable?

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager(),
        audioCaptureEngine: AudioCaptureEngineProtocol = AudioCaptureEngine(),
        transcriptionEngine: TranscriptionEngine = AppleSpeechEngine(),
        whisperEngineFactory: @escaping (WhisperModelType, @escaping (WhisperModelType) -> URL?) -> TranscriptionEngine = { type, provider in
            WhisperEngine(modelType: type, modelProvider: provider)
        },
        clipboardManager: ClipboardManager = ClipboardManager(),
        hudManager: HUDManager = HUDManager(),
        settingsWindowController: SettingsWindowControlling = SettingsWindowController(),
        hotkeyManager: HotkeyManaging = HotkeyManager(),
        settingsUserDefaults: UserDefaults = .standard,
        autoRequestPermissions: Bool = true,
        modelManager: ModelManager = ModelManager(),
        modelDownloader: ModelDownloader = ModelDownloader(),
        hudDisplayDuration: TimeInterval = 1.5
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
        self.hudDisplayDuration = hudDisplayDuration
        self.selectedEngine = TranscriptionEngineType(rawValue: settingsUserDefaults.string(forKey: engineKey) ?? "") ?? .system
        self.micDevices = audioDeviceManager.devices
        self.selectedMicID = audioDeviceManager.selectedDeviceID
        self.whisperEngineFactory = whisperEngineFactory
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
        audioDeviceManager.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .deviceUnavailable:
                    if self.selectedMicID == nil, let fallback = self.audioDeviceManager.devices.first?.id {
                        self.audioDeviceManager.selectDevice(id: fallback)
                    }
                    self.state.phaseDetail = .deviceFallback
                case .deviceSwitched:
                    break
                }
            }
            .store(in: &cancellables)
        if autoRequestPermissions {
            self.permissionManager.requestPermissionsIfNeeded()
        }
        configureModelDownloader()
        refreshModelStatus()
        HotkeyStorage.ensureDefaults(in: settingsUserDefaults)
        registerHotkey()
        hotkeyCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: settingsUserDefaults)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.registerHotkey()
            }
    }
    
    private func playSound(_ name: NSSound.Name) {
        NSSound(named: name)?.play()
    }

    func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            guard permissionManager.isAuthorized else {
                // Always recheck and attempt to request when starting a recording
                permissionManager.recheckAndRequestIfNeeded()
                state.mode = .error(.permissionDenied)
                // Show permissions needed message to guide users to System Settings
                state.phaseDetail = .needsPermissions
                return
            }
            do {
                state.phaseDetail = .connecting
                state.recordingStartedAt = nil
                state.transcribingStartedAt = nil
                state.audioLevel = 0
                audioCaptureEngine.onFirstBuffer = { [weak self] in
                    guard let self else { return }
                    if self.state.mode == .recording {
                        self.state.phaseDetail = .recording
                        self.state.recordingStartedAt = Date()
                        self.playSound(NSSound.Name("Funk"))
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
            state.mode = .transcribing(isSlow: false)
            state.phaseDetail = .transcribing
            state.transcribingStartedAt = Date()
            state.recordingStartedAt = nil
            state.audioLevel = 0
            
            // Start latency hint after 3 seconds
            let slowHintTask = DispatchWorkItem { [weak self] in
                guard let self, case .transcribing(let isSlow) = self.state.mode, !isSlow else { return }
                self.state.mode = .transcribing(isSlow: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: slowHintTask)
            
            Task { [weak self] in
                guard let self else {
                    slowHintTask.cancel()
                    return
                }
                do {
                    let buffer: AVAudioPCMBuffer
                    do {
                        buffer = try self.audioCaptureEngine.stopAndFinalize()
                    } catch {
                        print("SayIt: audioCaptureEngine.stopAndFinalize failed: \(error)")
                        slowHintTask.cancel()
                        await MainActor.run {
                            self.state.mode = .error(.captureFailed)
                            self.state.phaseDetail = nil
                            self.state.transcribingStartedAt = nil
                            self.state.audioLevel = 0
                        }
                        return
                    }
                    let engine = self.transcriptionEngineForCurrentSelection()
                    let locale = self.transcriptionLocaleForCurrentEngine()
                    let text = try await engine.transcribe(buffer: buffer, locale: locale)
                    slowHintTask.cancel()
                    await MainActor.run {
                        _ = self.clipboardManager.write(text)
                        self.playSound(NSSound.Name("Glass"))
                        self.hudManager.showCopied()
                        self.state.mode = .idle
                        self.state.phaseDetail = .copied
                        self.state.transcribingStartedAt = nil
                        self.state.audioLevel = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.hudDisplayDuration) { [weak self] in
                        guard let self else { return }
                        if self.state.phaseDetail == .copied {
                            self.state.phaseDetail = nil
                        }
                    }
                } catch {
                    print("SayIt: transcription failed: \(error)")
                    slowHintTask.cancel()
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
                settingsWindowController.show(appController: self)
            }
        case .terminate:
            NSApplication.shared.terminate(nil)
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }

    func cancelModelDownload() {
        modelDownloader.cancel()
        state.modelStatus = .idle
    }

    func startModelDownload() {
        let type = preferredModel()
        let url = modelManager.remoteURL(for: type)
        state.modelStatus = .downloading(0)
        modelDownloader.start(url: url)
    }

    func setEngine(_ engine: TranscriptionEngineType) {
        selectedEngine = engine
        settingsUserDefaults.set(engine.rawValue, forKey: engineKey)
        refreshModelStatus()
    }

    func setHUDAnchorWindow(_ window: NSWindow?) {
        hudManager.anchorWindow = window
    }

    var selectedMicName: String {
        guard let selected = selectedMicID else { return "None" }
        return micDevices.first(where: { $0.id == selected })?.name ?? "Unknown"
    }

    var isWhisperModelReady: Bool {
        modelURL(for: preferredModel()) != nil
    }

    private func transcriptionLocaleForCurrentEngine() -> Locale {
        if selectedEngine == .whisper {
            return Locale(identifier: "auto")
        }
        return transcriptionLocale()
    }

    private func transcriptionLocale() -> Locale {
        let stored = settingsUserDefaults.string(forKey: languageKey)
        guard let stored, !stored.isEmpty, stored != "system" else {
            return Locale.current
        }
        let resolvedIdentifier: String
        switch stored {
        case "zh-Hans":
            resolvedIdentifier = "zh-Hans-CN"
        default:
            resolvedIdentifier = stored
        }
        return Locale(identifier: resolvedIdentifier)
    }

    private func transcriptionEngineForCurrentSelection() -> TranscriptionEngine {
        switch selectedEngine {
        case .system:
            return transcriptionEngine
        case .whisper:
            return whisperEngineFactory(preferredModel()) { [weak self] type in
                self?.modelURL(for: type)
            }
        }
    }

    private func preferredModel() -> WhisperModelType {
        if let raw = settingsUserDefaults.string(forKey: preferredModelKey),
           let value = WhisperModelType(rawValue: raw) {
            return value
        }
        return .small
    }

    private func modelURL(for type: WhisperModelType) -> URL? {
        if let envPath = ProcessInfo.processInfo.environment["SAYIT_WHISPER_MODEL_PATH"] {
            return URL(fileURLWithPath: envPath)
        }
        let localURL = modelManager.localURL(for: type)
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    func checkModelStatus() {
        refreshModelStatus()
    }

    private func refreshModelStatus() {
        guard selectedEngine == .whisper else {
            state.modelStatus = .idle
            return
        }
        let type = preferredModel()
        if modelManager.isModelReady(type) || modelURL(for: type) != nil {
            state.modelStatus = .ready(type)
        } else {
            state.modelStatus = .idle
        }
    }

    private func configureModelDownloader() {
        modelDownloader.onProgress = { [weak self] progress in
            self?.state.modelStatus = .downloading(progress)
        }
        modelDownloader.onCompleted = { [weak self] location in
            guard let self else { return }
            let type = self.preferredModel()
            do {
                try self.modelManager.ensureModelsDirectory()
                let destination = self.modelManager.localURL(for: type)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                self.state.modelStatus = .ready(type)
            } catch {
                self.state.modelStatus = .failed("Model save failed")
            }
        }
        modelDownloader.onFailed = { [weak self] message in
            self?.state.modelStatus = .failed(message)
        }
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
