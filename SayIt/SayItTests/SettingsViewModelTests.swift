import Testing
@testable import SayIt
import Carbon

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

@MainActor @Test func settingsViewModel_validatesHotkeys() async throws {
    let viewModel = SettingsViewModel()
    
    // Conflict (Cmd+Q)
    let quitHotkey = Hotkey(
        keyCode: UInt32(kVK_ANSI_Q),
        modifiers: HotkeyModifiers(option: false, command: true, control: false, shift: false),
        display: "⌘Q"
    )
    #expect(viewModel.validateHotkey(quitHotkey) != nil)
    
    // Valid (Opt+Space)
    let validHotkey = Hotkey(
        keyCode: UInt32(kVK_Space),
        modifiers: HotkeyModifiers(option: true, command: false, control: false, shift: false),
        display: "⌥Space"
    )
    #expect(viewModel.validateHotkey(validHotkey) == nil)
}
