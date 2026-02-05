import Combine
import Foundation
import Carbon

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var preferredModel: WhisperModelType {
        didSet {
            settingsUserDefaults.set(preferredModel.rawValue, forKey: preferredModelKey)
        }
    }
    @Published var modelStatus: ModelStatus = .idle
    @Published var debugLoggingEnabled: Bool {
        didSet {
            settingsUserDefaults.set(debugLoggingEnabled, forKey: debugLoggingKey)
        }
    }

    private let launchAtLoginManager: LaunchAtLoginManaging
    private let settingsUserDefaults: UserDefaults
    private let preferredModelKey = "whisperPreferredModel"
    private let debugLoggingKey = "debugLoggingEnabled"

    init(
        launchAtLoginManager: LaunchAtLoginManaging = LaunchAtLoginManager(),
        settingsUserDefaults: UserDefaults = .standard
    ) {
        self.launchAtLoginManager = launchAtLoginManager
        self.settingsUserDefaults = settingsUserDefaults
        self.launchAtLoginEnabled = launchAtLoginManager.isEnabled
        let rawValue = settingsUserDefaults.string(forKey: preferredModelKey) ?? WhisperModelType.small.rawValue
        self.preferredModel = WhisperModelType(rawValue: rawValue) ?? .small
        self.debugLoggingEnabled = settingsUserDefaults.bool(forKey: debugLoggingKey)
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
        } catch {
            // TODO: surface error to user
        }
        launchAtLoginEnabled = launchAtLoginManager.isEnabled
    }

    func validateHotkey(_ hotkey: Hotkey) -> String? {
        guard hotkey.modifiers.hasAny else { return "Modifier required" }

        // System reserved shortcuts that conflict
        if hotkey.modifiers.command {
            let reservedKeyCodes: Set<Int> = [
                kVK_ANSI_Q,
                kVK_ANSI_W,
                kVK_ANSI_H,
                kVK_ANSI_M,
                kVK_ANSI_O,
                kVK_ANSI_P,
                kVK_ANSI_S,
                kVK_ANSI_N,
                kVK_Tab
            ]
            if reservedKeyCodes.contains(Int(hotkey.keyCode)) {
                return "Cannot use system shortcut"
            }
        }
        return nil
    }
}
