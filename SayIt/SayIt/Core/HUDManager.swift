import AppKit
import SwiftUI

final class HUDManager {
    private var panel: NSPanel?
    weak var anchorWindow: NSWindow?

    func showCopied() {
        show(message: AppLanguageManager.shared.localized("Copied"))
    }

    /// - Parameter message: Localized message string to display
    func show(message: String) {
        print("SayIt: HUD show '\(message)'. isMainThread=\(Thread.isMainThread)")
        panel?.orderOut(nil)
        let host = NSHostingController(rootView: HUDView(message: message))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = host.view
        self.panel = panel

        if let anchorWindow = anchorWindow {
            let frame = anchorWindow.frame
            let origin = NSPoint(
                x: frame.midX - panel.frame.width / 2,
                y: frame.midY - panel.frame.height / 2
            )
            panel.setFrameOrigin(origin)
            anchorWindow.addChildWindow(panel, ordered: .above)
            panel.orderFront(nil)
        } else if let screen = NSScreen.main ?? NSScreen.screens.first {
            let frame = screen.visibleFrame
            let origin = NSPoint(
                x: frame.midX - panel.frame.width / 2,
                y: frame.maxY - panel.frame.height - 24
            )
            panel.setFrameOrigin(origin)
            panel.orderFrontRegardless()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let anchorWindow = self.anchorWindow {
                anchorWindow.removeChildWindow(panel)
            }
            panel.orderOut(nil)
            if self.panel === panel {
                self.panel = nil
            }
        }
    }
}

private struct HUDView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.accent)
                .font(.system(size: 14, weight: .semibold))
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Theme.Colors.border.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
