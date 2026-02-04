import Testing
@testable import SayIt

struct AppStateTests {
    @Test func modelStatus_defaultsToIdle() {
        let state = AppState()
        #expect(state.modelStatus == .idle)
    }
}
