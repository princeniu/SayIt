import Testing
@testable import SayIt
import Foundation

@MainActor
struct PopoverViewModelTests {
    @Test func statusText_whenIdle_showsMicName() {
        let state = AppState(mode: .idle, phaseDetail: nil)
        let viewModel = PopoverViewModel(state: state, selectedMicName: "Built-in Mic")
        
        #expect(viewModel.primaryStatusText == "Ready to Record")
        #expect(viewModel.secondaryStatusText == "Mic: Built-in Mic")
    }

    @Test func statusText_whenRecording_showsRecording() {
        let state = AppState(mode: .recording)
        let viewModel = PopoverViewModel(state: state, selectedMicName: "Built-in Mic")
        
        #expect(viewModel.primaryStatusText == "Recording…")
    }
}
