import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var preferredModel: WhisperModelType {
        didSet {
            settingsUserDefaults.set(preferredModel.rawValue, forKey: preferredModelKey)
        }
    }

    private let launchAtLoginManager: LaunchAtLoginManaging
    private let settingsUserDefaults: UserDefaults
    private let preferredModelKey = "whisperPreferredModel"

    init(
        launchAtLoginManager: LaunchAtLoginManaging = LaunchAtLoginManager(),
        settingsUserDefaults: UserDefaults = .standard
    ) {
        self.launchAtLoginManager = launchAtLoginManager
        self.settingsUserDefaults = settingsUserDefaults
        self.launchAtLoginEnabled = launchAtLoginManager.isEnabled
        let rawValue = settingsUserDefaults.string(forKey: preferredModelKey) ?? WhisperModelType.small.rawValue
        self.preferredModel = WhisperModelType(rawValue: rawValue) ?? .small
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
        } catch {
            // TODO: surface error to user
        }
        launchAtLoginEnabled = launchAtLoginManager.isEnabled
    }
}
