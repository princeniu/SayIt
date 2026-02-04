import CoreFoundation
import Testing
@testable import SayIt

@Test func theme_tokens_exist() async throws {
    #expect(Theme.Colors.base != nil)
    #expect(Theme.Radius.card > 0)
    #expect(Theme.Motion.standard > 0)
}
