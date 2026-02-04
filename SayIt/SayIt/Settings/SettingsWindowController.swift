import AppKit
import SwiftUI

protocol SettingsWindowControlling {
    @MainActor func show()
}

final class SettingsWindowController: SettingsWindowControlling {
    private var window: NSWindow?

    @MainActor func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = hosting.view
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
