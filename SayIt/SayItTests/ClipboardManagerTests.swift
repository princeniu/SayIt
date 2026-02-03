import Testing
@testable import SayIt

@Test func clipboardManager_write_returnsTrue() async throws {
    let manager = ClipboardManager()
    #expect(manager.write("hello"))
}
