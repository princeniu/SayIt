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
    private let settingsUserDefaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []
    private let languageKey = "transcriptionLanguage"

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager(),
        audioCaptureEngine: AudioCaptureEngineProtocol = AudioCaptureEngine(),
        transcriptionEngine: TranscriptionEngine = AppleSpeechEngine(),
        clipboardManager: ClipboardManager = ClipboardManager(),
        hudManager: HUDManager = HUDManager(),
        settingsWindowController: SettingsWindowControlling = SettingsWindowController(),
        settingsUserDefaults: UserDefaults = .standard,
        autoRequestPermissions: Bool = true
    ) {
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager
        self.audioCaptureEngine = audioCaptureEngine
        self.transcriptionEngine = transcriptionEngine
        self.clipboardManager = clipboardManager
        self.hudManager = hudManager
        self.settingsWindowController = settingsWindowController
        self.settingsUserDefaults = settingsUserDefaults
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
    }

    func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            guard permissionManager.isAuthorized else {
                state.mode = .error(.permissionDenied)
                state.phaseDetail = nil
                return
            }
            do {
                state.phaseDetail = .connecting
                state.recordingStartedAt = nil
                state.transcribingStartedAt = nil
                audioCaptureEngine.onFirstBuffer = { [weak self] in
                    guard let self else { return }
                    if self.state.mode == .recording {
                        self.state.phaseDetail = .recording
                        self.state.recordingStartedAt = Date()
                    }
                }
                try audioCaptureEngine.start(deviceID: audioDeviceManager.selectedDeviceID)
                state.mode = .recording
            } catch {
                state.mode = .error(.captureFailed)
                state.phaseDetail = nil
            }
        case .stopAndTranscribe:
            guard case .recording = state.mode else { return }
            state.mode = .transcribing(isSlow: false)
            state.phaseDetail = .transcribing
            state.transcribingStartedAt = Date()
            state.recordingStartedAt = nil
            Task { [weak self] in
                guard let self else { return }
                do {
                    let buffer: AVAudioPCMBuffer
                    do {
                        buffer = try self.audioCaptureEngine.stopAndFinalize()
                    } catch {
                        await MainActor.run {
                            self.state.mode = .error(.captureFailed)
                            self.state.phaseDetail = nil
                            self.state.transcribingStartedAt = nil
                        }
                        return
                    }
                    let text = try await self.transcriptionEngine.transcribe(
                        buffer: buffer,
                        locale: self.transcriptionLocale()
                    )
                    await MainActor.run {
                        _ = self.clipboardManager.write(text)
                        self.hudManager.showCopied()
                        self.state.mode = .idle
                        self.state.phaseDetail = nil
                        self.state.transcribingStartedAt = nil
                    }
                } catch {
                    await MainActor.run {
                        self.state.mode = .error(.transcriptionFailed)
                        self.state.phaseDetail = nil
                        self.state.transcribingStartedAt = nil
                    }
                }
            }
        case .cancelRecording:
            audioCaptureEngine.cancel()
            state.mode = .idle
            state.phaseDetail = nil
            state.recordingStartedAt = nil
            state.transcribingStartedAt = nil
        case .retryTranscribe:
            break
        case .selectMic(let id):
            audioDeviceManager.selectDevice(id: id)
        case .openSettings:
            permissionManager.openSystemSettings()
        case .openSettingsWindow:
            settingsWindowController.show()
        }
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
}
