import AVFoundation
import Combine

struct AudioInputDevice: Identifiable, Equatable {
    let id: String
    let name: String
}

enum AudioDeviceEvent: Equatable {
    case deviceSwitched(from: String?, to: String)
    case deviceUnavailable
}

final class AudioDeviceManager: ObservableObject {
    @Published private(set) var devices: [AudioInputDevice] = []
    @Published private(set) var selectedDeviceID: String?

    let events = PassthroughSubject<AudioDeviceEvent, Never>()

    private var observers: [NSObjectProtocol] = []

    init() {
        refreshDevices()
        observeDeviceChanges()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func selectDevice(id: String) {
        guard devices.contains(where: { $0.id == id }) else { return }
        let previous = selectedDeviceID
        selectedDeviceID = id
        events.send(.deviceSwitched(from: previous, to: id))
    }

    func refreshDevices() {
        let newDevices = AVCaptureDevice.devices(for: .audio).map {
            AudioInputDevice(id: $0.uniqueID, name: $0.localizedName)
        }
        devices = newDevices
        handleSelectionAfterRefresh()
    }

    private func observeDeviceChanges() {
        let center = NotificationCenter.default
        let connected = center.addObserver(
            forName: AVCaptureDevice.wasConnectedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDevices()
        }
        let disconnected = center.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDevices()
        }
        observers = [connected, disconnected]
    }

    private func handleSelectionAfterRefresh() {
        if let current = selectedDeviceID,
           devices.contains(where: { $0.id == current }) {
            return
        }

        if let fallback = devices.first {
            let previous = selectedDeviceID
            selectedDeviceID = fallback.id
            events.send(.deviceSwitched(from: previous, to: fallback.id))
        } else {
            selectedDeviceID = nil
            events.send(.deviceUnavailable)
        }
    }
}
