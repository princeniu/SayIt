import Testing
@testable import SayIt

@MainActor
@Test func menuBarController_initializes() async throws {
    _ = MenuBarController()
}
