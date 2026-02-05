import Testing
@testable import SayIt

@MainActor
@Test func menuBarController_initializes() async throws {
    _ = MenuBarController()
}

@Test func menuBarController_symbolName_mapsModes() async throws {
    #expect(MenuBarController.symbolName(for: .idle) == "mic")
    #expect(MenuBarController.symbolName(for: .recording) == "mic.circle.fill")
    #expect(MenuBarController.symbolName(for: .transcribing(isSlow: false)) == "waveform.circle.fill")
    #expect(MenuBarController.symbolName(for: .error(.captureFailed)) == "mic.slash")
}
