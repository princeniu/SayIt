import AppKit
import SwiftUI

private struct OnAppLanguageChangeKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var onAppLanguageChange: (() -> Void)? {
        get { self[OnAppLanguageChangeKey.self] }
        set { self[OnAppLanguageChangeKey.self] = newValue }
    }
}

protocol SettingsWindowControlling {
    @MainActor func show(appController: AppController)
}

final class SettingsWindowController: SettingsWindowControlling {
    private var window: NSWindow?

    @MainActor func show(appController: AppController) {
        if let window {
            updateWindowTitle()
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = createHostingController(appController: appController)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        self.window = window
        updateWindowTitle()
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = hosting.view
        window.makeKeyAndOrderFront(nil)
    }

    @MainActor private func updateWindowTitle() {
        window?.title = AppLanguageManager.shared.localized("Settings")
    }

    @MainActor
    private func createHostingController(appController: AppController) -> NSHostingController<some View> {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        let localeID = (lang == "system") ? Locale.current.identifier : lang
        let onLanguageChange: (() -> Void)? = { [weak self] in self?.updateWindowTitle() }
        let view = SettingsView()
            .environmentObject(appController)
            .environment(\.locale, Locale(identifier: localeID))
            .environment(\.onAppLanguageChange, onLanguageChange)
        return NSHostingController(rootView: view)
    }
}
