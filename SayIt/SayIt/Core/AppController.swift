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
    private var cancellables: Set<AnyCancellable> = []

    init(
        permissionManager: PermissionManager = PermissionManager(),
        audioDeviceManager: AudioDeviceManager = AudioDeviceManager(),
        audioCaptureEngine: AudioCaptureEngineProtocol = AudioCaptureEngine(),
        transcriptionEngine: TranscriptionEngine = AppleSpeechEngine(),
        clipboardManager: ClipboardManager = ClipboardManager(),
        hudManager: HUDManager = HUDManager(),
        autoRequestPermissions: Bool = true
    ) {
        self.permissionManager = permissionManager
        self.audioDeviceManager = audioDeviceManager
        self.audioCaptureEngine = audioCaptureEngine
        self.transcriptionEngine = transcriptionEngine
        self.clipboardManager = clipboardManager
        self.hudManager = hudManager
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
                return
            }
            do {
                try audioCaptureEngine.start(deviceID: audioDeviceManager.selectedDeviceID)
                state.mode = .recording
            } catch {
                state.mode = .error(.captureFailed)
            }
        case .stopAndTranscribe:
            guard case .recording = state.mode else { return }
            state.mode = .transcribing(isSlow: false)
            Task { [weak self] in
                guard let self else { return }
                do {
                    let buffer: AVAudioPCMBuffer
                    do {
                        buffer = try self.audioCaptureEngine.stopAndFinalize()
                    } catch {
                        await MainActor.run {
                            self.state.mode = .error(.captureFailed)
                        }
                        return
                    }
                    let text = try await self.transcriptionEngine.transcribe(
                        buffer: buffer,
                        locale: Locale.current
                    )
                    await MainActor.run {
                        _ = self.clipboardManager.write(text)
                        self.hudManager.showCopied()
                        self.state.mode = .idle
                    }
                } catch {
                    await MainActor.run {
                        self.state.mode = .error(.transcriptionFailed)
                    }
                }
            }
        case .cancelRecording:
            audioCaptureEngine.cancel()
            state.mode = .idle
        case .retryTranscribe:
            break
        case .selectMic(let id):
            audioDeviceManager.selectDevice(id: id)
        case .openSettings:
            permissionManager.openSystemSettings()
        }
    }

    var selectedMicName: String {
        guard let selected = selectedMicID else { return "None" }
        return micDevices.first(where: { $0.id == selected })?.name ?? "Unknown"
    }
}
