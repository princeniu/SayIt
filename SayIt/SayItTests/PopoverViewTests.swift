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

@Test func popoverView_shouldShowSecondaryStatus_onlyWhenRecording() async throws {
    #expect(PopoverView.shouldShowSecondaryStatus(for: .recording))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .idle))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .transcribing(isSlow: false)))
    #expect(!PopoverView.shouldShowSecondaryStatus(for: .error(.captureFailed)))
}

@Test func popoverView_shouldShowErrorStatus_onlyWhenError() async throws {
    #expect(PopoverView.shouldShowErrorStatus(for: .error(.captureFailed)))
    #expect(!PopoverView.shouldShowErrorStatus(for: .idle))
    #expect(!PopoverView.shouldShowErrorStatus(for: .recording))
    #expect(!PopoverView.shouldShowErrorStatus(for: .transcribing(isSlow: false)))
}

@Test func popoverView_sectionOrder_movesSettingsToTopAndErrorToBottom() async throws {
    #expect(PopoverView.sectionOrderLayout(for: .idle, includeFeedback: false) == [PopoverView.Section.settings, .actions])
    #expect(PopoverView.sectionOrderLayout(for: .recording, includeFeedback: false) == [PopoverView.Section.settings, .actions])
    #expect(PopoverView.sectionOrderLayout(for: .transcribing(isSlow: false), includeFeedback: false) == [PopoverView.Section.settings, .actions])
    #expect(PopoverView.sectionOrderLayout(for: .error(.captureFailed), includeFeedback: false) == [PopoverView.Section.settings, .actions, .error])
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

@Test func popoverView_feedbackVisibility_rules() async throws {
    #expect(PopoverView.shouldShowFeedback(for: .transcribing(isSlow: false), downloadState: .hidden, showDownloadPrompt: false) == true)
    #expect(PopoverView.shouldShowFeedback(for: .idle, downloadState: .progress(0.2), showDownloadPrompt: false) == true)
    #expect(PopoverView.shouldShowFeedback(for: .idle, downloadState: .hidden, showDownloadPrompt: true) == true)
    #expect(PopoverView.shouldShowFeedback(for: .idle, downloadState: .hidden, showDownloadPrompt: false) == false)
}

@Test func popoverView_feedbackStatusText_forTranscribing() async throws {
    #expect(PopoverView.feedbackStatusText(for: .transcribing(isSlow: false)) == "Transcribing…")
    #expect(PopoverView.feedbackStatusText(for: .transcribing(isSlow: true)) == "Transcribing (Slow)…")
    #expect(PopoverView.feedbackStatusText(for: .recording) == nil)
}
