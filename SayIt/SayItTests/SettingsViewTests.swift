import XCTest
@testable import SayIt

@MainActor
final class SettingsViewTests: XCTestCase {
    func test_settingsView_initializes() {
        _ = SettingsView()
    }
}
