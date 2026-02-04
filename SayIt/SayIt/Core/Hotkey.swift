import AppKit
import Carbon.HIToolbox
import Foundation

struct HotkeyModifiers: Codable, Equatable {
    let option: Bool
    let command: Bool
    let control: Bool
    let shift: Bool

    var carbonValue: UInt32 {
        var value: UInt32 = 0
        if command { value |= UInt32(cmdKey) }
        if option { value |= UInt32(optionKey) }
        if control { value |= UInt32(controlKey) }
        if shift { value |= UInt32(shiftKey) }
        return value
    }

    var hasAny: Bool {
        option || command || control || shift
    }

    var display: String {
        var output = ""
        if control { output += "⌃" }
        if option { output += "⌥" }
        if shift { output += "⇧" }
        if command { output += "⌘" }
        return output
    }

    static func from(eventFlags: NSEvent.ModifierFlags) -> HotkeyModifiers {
        HotkeyModifiers(
            option: eventFlags.contains(.option),
            command: eventFlags.contains(.command),
            control: eventFlags.contains(.control),
            shift: eventFlags.contains(.shift)
        )
    }
}

struct Hotkey: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: HotkeyModifiers
    let display: String

    static let defaultValue = Hotkey(
        keyCode: 6,
        modifiers: HotkeyModifiers(option: true, command: false, control: false, shift: false),
        display: "⌥Z"
    )
}

enum HotkeyStorage {
    private static let keyCodeKey = "hotkeyKeyCode"
    private static let modifiersKey = "hotkeyModifiers"
    private static let displayKey = "hotkeyDisplay"

    static func load(from userDefaults: UserDefaults) -> Hotkey {
        let keyCode = userDefaults.object(forKey: keyCodeKey) as? Int
        let modifiers = userDefaults.object(forKey: modifiersKey) as? Int
        let display = userDefaults.string(forKey: displayKey)
        guard let keyCode, let modifiers, let display else {
            ensureDefaults(in: userDefaults)
            return Hotkey.defaultValue
        }
        let decodedModifiers = HotkeyModifiers(
            option: modifiers & Int(optionKey) != 0,
            command: modifiers & Int(cmdKey) != 0,
            control: modifiers & Int(controlKey) != 0,
            shift: modifiers & Int(shiftKey) != 0
        )
        return Hotkey(keyCode: UInt32(keyCode), modifiers: decodedModifiers, display: display)
    }

    static func save(_ hotkey: Hotkey, into userDefaults: UserDefaults) {
        userDefaults.set(Int(hotkey.keyCode), forKey: keyCodeKey)
        userDefaults.set(Int(hotkey.modifiers.carbonValue), forKey: modifiersKey)
        userDefaults.set(hotkey.display, forKey: displayKey)
    }

    static func ensureDefaults(in userDefaults: UserDefaults) {
        guard userDefaults.object(forKey: keyCodeKey) == nil else { return }
        save(Hotkey.defaultValue, into: userDefaults)
    }
}
