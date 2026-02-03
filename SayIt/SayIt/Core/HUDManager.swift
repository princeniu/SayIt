import AppKit
import SwiftUI

final class HUDManager {
    func showCopied() {
        show(message: "Copied ✓")
    }

    func show(message: String) {
        let host = NSHostingController(rootView: HUDView(message: message))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = host.view

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let origin = NSPoint(
                x: frame.midX - panel.frame.width / 2,
                y: frame.maxY - panel.frame.height - 24
            )
            panel.setFrameOrigin(origin)
        }

        panel.makeKeyAndOrderFront(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            panel.orderOut(nil)
        }
    }
}

private struct HUDView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.9))
                    .shadow(radius: 8)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
