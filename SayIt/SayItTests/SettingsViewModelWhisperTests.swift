import Testing
@testable import SayIt

struct SettingsViewModelWhisperTests {
    @Test @MainActor func defaultModel_isSmall() {
        let viewModel = SettingsViewModel()
        #expect(viewModel.preferredModel == .small)
    }
}
