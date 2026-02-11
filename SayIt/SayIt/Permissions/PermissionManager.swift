import AppKit
import AVFoundation
import Combine
import Speech

final class PermissionManager: ObservableObject {
    enum Status: Equatable {
        case unknown
        case denied
        case authorized
    }

    @Published private(set) var micStatus: Status
    @Published private(set) var speechStatus: Status

    init(
        micStatus: Status = .unknown,
        speechStatus: Status = .unknown,
        useSystemStatus: Bool = true
    ) {
        self.micStatus = micStatus
        self.speechStatus = speechStatus

        guard useSystemStatus else { return }

        if micStatus == .unknown {
            self.micStatus = Self.mapMicStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        }
        if speechStatus == .unknown {
            self.speechStatus = Self.mapSpeechStatus(SFSpeechRecognizer.authorizationStatus())
        }
    }

    var isAuthorized: Bool {
        micStatus == .authorized && speechStatus == .authorized
    }

    func requestPermissionsIfNeeded() {
        // Request only when the current status is not determined (unknown)
        if micStatus == .unknown {
            requestMicrophone()
        }
        if speechStatus == .unknown {
            requestSpeech()
        }
    }

    /// Refresh system-reported statuses and request if still undetermined.
    func recheckAndRequestIfNeeded() {
        // Refresh cached statuses from the system first
        micStatus = Self.mapMicStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        speechStatus = Self.mapSpeechStatus(SFSpeechRecognizer.authorizationStatus())
        // Then try to request if undetermined
        requestPermissionsIfNeeded()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.micStatus = granted ? .authorized : .denied
            }
        }
    }

    private func requestSpeech() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechStatus = Self.mapSpeechStatus(status)
            }
        }
    }

    private static func mapMicStatus(_ status: AVAuthorizationStatus) -> Status {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private static func mapSpeechStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> Status {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
