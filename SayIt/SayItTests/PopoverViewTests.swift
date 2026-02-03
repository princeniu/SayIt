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

@Test func popoverView_shouldShowLevel_onlyWhenRecording() async throws {
    #expect(PopoverView.shouldShowLevel(for: .recording))
    #expect(!PopoverView.shouldShowLevel(for: .idle))
    #expect(!PopoverView.shouldShowLevel(for: .transcribing(isSlow: false)))
    #expect(!PopoverView.shouldShowLevel(for: .error(.captureFailed)))
}

@Test func popoverView_levelBarCount_clampsAndScales() async throws {
    #expect(PopoverView.levelBarCount(level: -0.2, maxBars: 12) == 0)
    #expect(PopoverView.levelBarCount(level: 0, maxBars: 12) == 0)
    #expect(PopoverView.levelBarCount(level: 0.02, maxBars: 12) == 2)
    #expect(PopoverView.levelBarCount(level: 0.35, maxBars: 12) == 7)
    #expect(PopoverView.levelBarCount(level: 1.0, maxBars: 12) == 12)
    #expect(PopoverView.levelBarCount(level: 1.4, maxBars: 12) == 12)
}
