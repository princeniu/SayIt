import SwiftUI
import Testing
@testable import SayIt

@Test func popoverView_initializes() async throws {
        let controller = AppController(
            audioDeviceManager: AudioDeviceManager(startMonitoring: false),
            audioCaptureEngine: TestAudioCaptureEngine(),
            transcriptionEngine: TestTranscriptionEngine(),
            autoRequestPermissions: false
        )
    let _ = PopoverView().environmentObject(controller)
}
