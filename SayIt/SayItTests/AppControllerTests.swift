import XCTest
@testable import SayIt

final class AppControllerTests: XCTestCase {
    func test_startRecording_fromIdle_setsRecordingState() {
        let controller = AppController()
        XCTAssertEqual(controller.state.mode, .idle)

        controller.send(.startRecording)

        XCTAssertEqual(controller.state.mode, .recording)
    }
}
