import AppKit
import Testing
@testable import SayIt

@MainActor
@Test func menuBarController_initializes() async throws {
    _ = MenuBarController(appController: AppController(autoRequestPermissions: false))
}

@Test func menuBarController_symbolName_mapsModes() async throws {
    #expect(MenuBarController.symbolName(for: .idle) == "mic")
    #expect(MenuBarController.symbolName(for: .recording) == "mic.circle.fill")
    #expect(MenuBarController.symbolName(for: .transcribing(isSlow: false)) == "waveform.circle.fill")
    #expect(MenuBarController.symbolName(for: .error(.captureFailed)) == "mic.slash")
}

@MainActor
@Test func menuBarController_outsideClickClosesPopover() async throws {
    let popover = TestPopover()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let controller = MenuBarController(
        appController: AppController(autoRequestPermissions: false),
        statusItem: statusItem,
        popover: popover
    )

    controller.showPopover()
    controller.handlePopoverClick(.outside)

    #expect(popover.closeCallCount == 1)
}

private final class TestPopover: PopoverControlling {
    private(set) var isShown = false
    private(set) var closeCallCount = 0
    var contentWindow: NSWindow?

    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        isShown = true
    }

    func performClose(_ sender: Any?) {
        closeCallCount += 1
        isShown = false
    }
}
