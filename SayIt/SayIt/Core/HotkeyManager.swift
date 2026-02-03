import Foundation

protocol HotkeyManaging: AnyObject {
    func register(toggleHandler: @escaping () -> Void) throws
    func unregister()
}

final class HotkeyManager: HotkeyManaging {
    func register(toggleHandler: @escaping () -> Void) throws {
        // Implementation added in next step.
        _ = toggleHandler
    }

    func unregister() {
        // Implementation added in next step.
    }
}
