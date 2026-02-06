import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let appController: AppController
    private var cancellables = Set<AnyCancellable>()

    init(appController: AppController) {
        self.appController = appController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()

        configureStatusItem()
        configurePopover()
        bindState()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        updateStatusItemIcon(for: appController.state)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 280)
        let root = PopoverRootView()
            .environmentObject(appController)
        popover.contentViewController = NSHostingController(rootView: root)
    }

    private func bindState() {
        appController.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateStatusItemIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemIcon(for state: AppState) {
        let symbolName = Self.symbolName(for: state.mode)
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "SayIt"
        )
        statusItem.button?.image?.isTemplate = true
    }

    nonisolated static func symbolName(for mode: AppMode) -> String {
        switch mode {
        case .idle:
            return "mic"
        case .recording:
            return "mic.circle.fill"
        case .transcribing:
            return "waveform.circle.fill"
        case .error:
            return "mic.slash"
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let window = self.popover.contentViewController?.view.window
                self.appController.setHUDAnchorWindow(window)
            }
        }
    }
}
