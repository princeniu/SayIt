import Testing
@testable import SayIt

struct AppControllerWhisperTests {
    @Test func downloadCancel_setsModelStatusIdle() async throws {
        let controller = AppController(autoRequestPermissions: false)
        controller.cancelModelDownload()
        #expect(controller.state.modelStatus == .idle)
    }

    @Test func startModelDownload_setsModelStatusDownloading() async throws {
        let controller = AppController(autoRequestPermissions: false)
        controller.startModelDownload()
        #expect(controller.state.modelStatus == .downloading(0))
    }
}
