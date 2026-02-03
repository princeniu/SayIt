import SwiftUI
import Testing
@testable import SayIt

@Test func popoverView_initializes() async throws {
    let controller = AppController()
    let _ = PopoverView().environmentObject(controller)
}
