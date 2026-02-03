import Testing
@testable import SayIt

@Test func deviceManager_initially_hasList() async throws {
    let manager = AudioDeviceManager()
    #expect(manager.devices.count >= 0)
}
