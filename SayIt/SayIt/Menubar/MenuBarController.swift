import AppKit
import Combine
import SwiftUI

protocol PopoverControlling: AnyObject {
    var isShown: Bool { get }
    var contentWindow: NSWindow? { get }
    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge)
    func performClose(_ sender: Any?)
}

extension NSPopover: PopoverControlling {
    var contentWindow: NSWindow? {
        contentViewController?.view.window
    }
}

enum PopoverClickTarget {
    case popover
    case statusItem
    case outside
}

protocol PopoverOutsideClickMonitoring: AnyObject {
    func start()
    func stop()
}

final class NoopPopoverOutsideClickMonitor: PopoverOutsideClickMonitoring {
    func start() {}
    func stop() {}
}

final class PopoverOutsideClickMonitor: PopoverOutsideClickMonitoring {
    private let resolveTarget: (NSEvent) -> PopoverClickTarget
    private let handler: (PopoverClickTarget) -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(
        resolveTarget: @escaping (NSEvent) -> PopoverClickTarget,
        handler: @escaping (PopoverClickTarget) -> Void
    ) {
        self.resolveTarget = resolveTarget
        self.handler = handler
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        handler(resolveTarget(event))
    }
}

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: PopoverControlling
    private let appController: AppController
    private let popoverMonitorFactory: (@escaping (PopoverClickTarget) -> Void) -> PopoverOutsideClickMonitoring
    private var popoverMonitor: PopoverOutsideClickMonitoring?
    private var cancellables = Set<AnyCancellable>()

    init(
        appController: AppController,
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        popover: PopoverControlling? = nil,
        popoverMonitorFactory: ((@escaping (PopoverClickTarget) -> Void) -> PopoverOutsideClickMonitoring)? = nil
    ) {
        let resolvedPopover = popover ?? NSPopover()
        let resolvedPopoverMonitorFactory = popoverMonitorFactory ?? { [weak statusItem = statusItem, weak popover = resolvedPopover] handler in
            PopoverOutsideClickMonitor(
                resolveTarget: { event in
                    if let popoverWindow = popover?.contentWindow,
                       event.window === popoverWindow {
                        return .popover
                    }
                    if let statusWindow = statusItem?.button?.window,
                       event.window === statusWindow {
                        return .statusItem
                    }
                    return .outside
                },
                handler: handler
            )
        }
        self.appController = appController
        self.statusItem = statusItem
        self.popover = resolvedPopover
        self.popoverMonitorFactory = resolvedPopoverMonitorFactory

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
        if let popover = popover as? NSPopover {
            popover.behavior = .applicationDefined
            popover.contentSize = NSSize(width: 320, height: 380)
            let root = PopoverRootView()
                .environmentObject(appController)
            popover.contentViewController = NSHostingController(rootView: root)
            popover.appearance = NSAppearance(named: .darkAqua)
            NotificationCenter.default.publisher(for: NSPopover.didCloseNotification, object: popover)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.popoverMonitor?.stop()
                    self?.appController.setHUDAnchorWindow(nil)
                }
                .store(in: &cancellables)
        }
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
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        ensurePopoverMonitor()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popoverMonitor?.start()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let window = self.popover.contentWindow
            window?.appearance = NSAppearance(named: .darkAqua)
            self.appController.setHUDAnchorWindow(window)
        }
    }

    func closePopover(_ sender: AnyObject? = nil) {
        popoverMonitor?.stop()
        popover.performClose(sender)
    }

    func handlePopoverClick(_ target: PopoverClickTarget) {
        guard popover.isShown else { return }
        switch target {
        case .popover, .statusItem:
            return
        case .outside:
            closePopover(nil)
        }
    }

    private func ensurePopoverMonitor() {
        guard popoverMonitor == nil else { return }
        popoverMonitor = popoverMonitorFactory { [weak self] target in
            self?.handlePopoverClick(target)
        }
    }
}
