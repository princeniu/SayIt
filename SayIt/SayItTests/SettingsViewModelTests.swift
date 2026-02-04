import Testing
@testable import SayIt

@MainActor @Test func settingsViewModel_initializesFromManager() async throws {
    let manager = TestLaunchAtLoginManager(isEnabled: true)
    let viewModel = SettingsViewModel(launchAtLoginManager: manager)

    #expect(viewModel.launchAtLoginEnabled == true)
}

@MainActor @Test func settingsViewModel_toggleUpdatesManager() async throws {
    let manager = TestLaunchAtLoginManager(isEnabled: false)
    let viewModel = SettingsViewModel(launchAtLoginManager: manager)

    viewModel.setLaunchAtLoginEnabled(true)

    #expect(manager.setCalls == [true])
    #expect(viewModel.launchAtLoginEnabled == true)
}

final class TestLaunchAtLoginManager: LaunchAtLoginManaging {
    private(set) var setCalls: [Bool] = []
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        setCalls.append(enabled)
        isEnabled = enabled
    }
}
