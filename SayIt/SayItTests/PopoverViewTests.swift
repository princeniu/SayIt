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

@Test func popoverView_hasLanguageOptions() async throws {
    let ids = PopoverView.languageOptions.map(\.id)
    #expect(ids.contains("system"))
    #expect(ids.contains("zh-Hans"))
    #expect(ids.contains("en-US"))
}

@Test func popoverView_formatsDurationMinutesSeconds() async throws {
    #expect(PopoverView.formatDuration(0) == "00:00")
    #expect(PopoverView.formatDuration(5) == "00:05")
    #expect(PopoverView.formatDuration(65) == "01:05")
}
