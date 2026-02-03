import AVFoundation
import Combine
import CoreAudio

struct AudioInputDevice: Identifiable, Equatable {
    let id: AudioDeviceID
    let name: String
}

enum AudioDeviceEvent: Equatable {
    case deviceSwitched(from: AudioDeviceID?, to: AudioDeviceID)
    case deviceUnavailable
}

final class AudioDeviceManager: ObservableObject {
    @Published private(set) var devices: [AudioInputDevice] = []
    @Published private(set) var selectedDeviceID: AudioDeviceID?

    let events = PassthroughSubject<AudioDeviceEvent, Never>()

    private var observers: [NSObjectProtocol] = []

    init(
        devices: [AudioInputDevice] = [],
        selectedDeviceID: AudioDeviceID? = nil,
        startMonitoring: Bool = true
    ) {
        self.devices = devices
        self.selectedDeviceID = selectedDeviceID
        if startMonitoring {
            refreshDevices()
            observeDeviceChanges()
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func selectDevice(id: AudioDeviceID) {
        guard devices.contains(where: { $0.id == id }) else { return }
        let previous = selectedDeviceID
        selectedDeviceID = id
        events.send(.deviceSwitched(from: previous, to: id))
    }

    func refreshDevices() {
        let newDevices = Self.enumerateInputDevices()
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

    private static func enumerateInputDevices() -> [AudioInputDevice] {
        let ids = allDeviceIDs()
        return ids.compactMap { id in
            guard inputChannelCount(for: id) > 0 else { return nil }
            guard let name = deviceName(for: id) else { return nil }
            return AudioInputDevice(id: id, name: name)
        }
    }

    private static func allDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else {
            return []
        }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &ids
        ) == noErr else {
            return []
        }
        return ids
    }

    private static func inputChannelCount(for deviceID: AudioDeviceID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else {
            return 0
        }
        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(dataSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { rawPointer.deallocate() }
        let bufferList = rawPointer.bindMemory(to: AudioBufferList.self, capacity: 1)
        guard AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            bufferList
        ) == noErr else {
            return 0
        }
        let audioBufferList = UnsafeMutableAudioBufferListPointer(bufferList)
        return audioBufferList.reduce(0) { $0 + $1.mNumberChannels }
    }

    private static func deviceName(for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let namePointer = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { namePointer.deallocate() }
        namePointer.pointee = nil
        guard AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            namePointer
        ) == noErr else {
            return nil
        }
        return namePointer.pointee as String?
    }
}
