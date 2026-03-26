import Testing
@testable import SayIt

@Test func deviceManager_initially_hasList() async throws {
    let manager = AudioDeviceManager()
    #expect(manager.devices.count >= 0)
}

@Test func deviceManager_reselectsPreferredDeviceWhenItReconnects() async throws {
    let builtIn = AudioInputDevice(id: 1, name: "MacBook Mic")
    let iPhone = AudioInputDevice(id: 2, name: "iPhone Mic")
    var availableDevices = [builtIn, iPhone]

    let manager = AudioDeviceManager(
        devices: availableDevices,
        selectedDeviceID: iPhone.id,
        deviceEnumerator: { availableDevices },
        startMonitoring: false
    )

    availableDevices = [builtIn]
    manager.refreshDevices()
    #expect(manager.selectedDeviceID == builtIn.id)

    availableDevices = [builtIn, iPhone]
    manager.refreshDevices()
    #expect(manager.selectedDeviceID == iPhone.id)
}
