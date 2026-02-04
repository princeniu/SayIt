import Testing
@testable import SayIt

struct DownloadStatusViewModelTests {
    @Test func downloading_mapsToProgress() {
        let state = DownloadStatusViewModel.state(for: .downloading(0.5))
        #expect(state == .progress(0.5))
    }

    @Test func failed_mapsToFailed() {
        let state = DownloadStatusViewModel.state(for: .failed("Network error"))
        #expect(state == .failed("Network error"))
    }

    @Test func ready_mapsToHidden() {
        let state = DownloadStatusViewModel.state(for: .ready(.small))
        #expect(state == .hidden)
    }
}
