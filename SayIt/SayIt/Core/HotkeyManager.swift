import Carbon.HIToolbox
import Foundation

protocol HotkeyManaging: AnyObject {
    func register(hotkey: Hotkey, toggleHandler: @escaping () -> Void) throws
    func unregister()
}

enum HotkeyManagerError: Error {
    case registrationFailed(OSStatus)
    case handlerInstallFailed(OSStatus)
}

final class HotkeyManager: HotkeyManaging {
    private var handler: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x53415954, id: 1) // 'SAYT'

    func register(hotkey: Hotkey, toggleHandler: @escaping () -> Void) throws {
        unregister()
        handler = toggleHandler
        try installHandlerIfNeeded()
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers.carbonValue,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else {
            throw HotkeyManagerError.registrationFailed(status)
        }
        self.hotKeyRef = hotKeyRef
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() throws {
        guard eventHandlerRef == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard result == noErr else { return result }
                if hotKeyID.signature == manager.hotKeyID.signature && hotKeyID.id == manager.hotKeyID.id {
                    manager.handler?()
                }
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
        guard status == noErr else {
            throw HotkeyManagerError.handlerInstallFailed(status)
        }
    }
}
