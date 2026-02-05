import CoreFoundation
import Testing
@testable import SayIt

struct SettingsViewModelWhisperTests {
    @Test @MainActor func defaultModel_isSmall() {
        let viewModel = SettingsViewModel()
        #expect(viewModel.preferredModel == .small)
    }

    @Test @MainActor func settingsStyles_areConsistent() {
        #expect(SettingsView.cardWidth == 360)
        #expect(SettingsView.cardPadding == 16)
    }
}
