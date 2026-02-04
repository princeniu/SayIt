import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var preferredModel: WhisperModelType = .small

    private let launchAtLoginManager: LaunchAtLoginManaging

    init(launchAtLoginManager: LaunchAtLoginManaging = LaunchAtLoginManager()) {
        self.launchAtLoginManager = launchAtLoginManager
        self.launchAtLoginEnabled = launchAtLoginManager.isEnabled
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
