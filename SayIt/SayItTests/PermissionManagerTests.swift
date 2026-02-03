import Foundation
import Testing
@testable import SayIt

@Test func permissionManager_initialState_unknown() async throws {
    let suite = UserDefaults(suiteName: "PermissionManagerTests")
    suite?.removePersistentDomain(forName: "PermissionManagerTests")

    let manager = PermissionManager(userDefaults: suite ?? .standard)
    #expect(manager.micStatus == PermissionManager.Status.unknown)
    #expect(manager.speechStatus == PermissionManager.Status.unknown)
}
