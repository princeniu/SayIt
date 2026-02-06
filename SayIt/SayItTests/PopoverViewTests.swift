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
    let ids = PopoverView.languageOptionKeys.map(\.id)
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

@Test func popoverView_shouldShowSecondaryStatus_onlyWhenRecording() async throws {
    #expect(PopoverView.shouldShowSecondaryStatus(for: .recording))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .idle))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .transcribing(isSlow: false)))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .error(.captureFailed)))
}


@Test func popoverView_sectionOrder_alwaysIncludesStatus() async throws {
    #expect(PopoverView.sectionOrderLayout(for: .idle) == [PopoverView.Section.settings, .actions, .status])
    #expect(PopoverView.sectionOrderLayout(for: .recording) == [PopoverView.Section.settings, .actions, .status])
    #expect(PopoverView.sectionOrderLayout(for: .transcribing(isSlow: false)) == [PopoverView.Section.settings, .actions, .status])
    #expect(PopoverView.sectionOrderLayout(for: .error(.captureFailed)) == [PopoverView.Section.settings, .actions, .status])
}

@Test func popoverView_settingsSectionOrder_placesSettingsButtonFirst() async throws {
    #expect(PopoverView.settingsSectionOrderLayout() == [
        PopoverView.SettingsRow.settingsButton,
        .microphone,
        .engine,
        .language
    ])
}

@Test func popoverView_layoutConstants_defineCardSpacingAndWidth() async throws {
    #expect(PopoverView.cardSpacing == 12)
    #expect(PopoverView.contentWidth == 320)
}

@Test func popoverView_levelBarCount_clampsAndScales() async throws {
    #expect(PopoverView.levelBarCount(level: -0.2, maxBars: 12) == 0)
    #expect(PopoverView.levelBarCount(level: 0, maxBars: 12) == 0)
    #expect(PopoverView.levelBarCount(level: 0.015, maxBars: 12) == 0)
    #expect(PopoverView.levelBarCount(level: 0.02, maxBars: 12) == 5)
    #expect(PopoverView.levelBarCount(level: 0.35, maxBars: 12) == 9)
    #expect(PopoverView.levelBarCount(level: 1.0, maxBars: 12) == 12)
    #expect(PopoverView.levelBarCount(level: 1.4, maxBars: 12) == 12)
}

@Test func popoverView_languageDisabledWhenUsingWhisper() async throws {
    #expect(PopoverView.shouldDisableLanguage(forEngine: .system) == false)
    #expect(PopoverView.shouldDisableLanguage(forEngine: .whisper) == true)
}

@Test func popoverView_primaryButtonStyle_mapsModes() async throws {
    #expect(PopoverView.primaryButtonStyle(for: .idle) == .ready)
    #expect(PopoverView.primaryButtonStyle(for: .error(.captureFailed)) == .ready)
    #expect(PopoverView.primaryButtonStyle(for: .recording) == .recording)
    #expect(PopoverView.primaryButtonStyle(for: .transcribing(isSlow: false)) == .transcribing)
}

@Test func popoverView_shouldBlurWhenCopiedPhase() async throws {
    #expect(PopoverView.shouldBlur(for: .copied) == true)
    #expect(PopoverView.shouldBlur(for: .recording) == false)
    #expect(PopoverView.shouldBlur(for: nil) == false)
}

