import CoreFoundation
import Testing
@testable import SayIt

@Test func popoverCardStyle_usesThemeTokens() async throws {
    #expect(PopoverCardStyle.radius == Theme.Radius.card)
    #expect(PopoverCardStyle.borderOpacity > 0)
}
