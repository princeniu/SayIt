import Testing
@testable import SayIt

@Test func startRecording_fromIdle_setsRecordingState() async throws {
    let controller = AppController()
    #expect(controller.state.mode == .idle)

    controller.send(.startRecording)

    #expect(controller.state.mode == .recording)
}
