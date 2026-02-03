import XCTest
@testable import SayIt

final class AppStateStatusTests: XCTestCase {
    func test_statusDetail_idle_showsMic() {
        let state = AppState(mode: .idle)

        XCTAssertEqual(state.statusDetail(selectedMic: "Built-in"), "Mic: Built-in")
    }

    func test_statusDetail_connecting_doesNotOverrideMic() {
        var state = AppState(mode: .idle)
        state.phaseDetail = .connecting

        XCTAssertEqual(state.statusDetail(selectedMic: "Built-in"), "Mic: Built-in")
    }

    func test_statusDetail_error_permission() {
        let state = AppState(mode: .error(.permissionDenied))

        XCTAssertEqual(state.statusDetail(selectedMic: "Any"), "Check permissions")
    }

    func test_statusDetail_error_captureFailed() {
        let state = AppState(mode: .error(.captureFailed))

        XCTAssertEqual(state.statusDetail(selectedMic: "Any"), "Audio input unavailable")
    }

    func test_statusDetail_error_transcriptionFailed() {
        let state = AppState(mode: .error(.transcriptionFailed))

        XCTAssertEqual(state.statusDetail(selectedMic: "Any"), "Transcription failed")
    }
}
