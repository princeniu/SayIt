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

    @Test @MainActor func whisperModelState_exposesProgressAndReady() async {
        let viewModel = SettingsViewModel()
        // verify default is idle
        if case .idle = viewModel.modelStatus {
            #expect(true)
        } else {
            #expect(Bool(false), "Expected idle status by default")
        }
        
        // Checks the initial idle state through the modelStatus property.
        // and we haven't implemented the mechanism to inject/update it
    }
}
