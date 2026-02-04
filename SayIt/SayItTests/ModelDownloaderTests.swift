import Testing
@testable import SayIt

struct ModelDownloaderTests {
    @Test func cancel_setsStatusCanceled() async throws {
        let downloader = ModelDownloader()
        downloader.cancel()
        #expect(downloader.status == .canceled)
    }
}
