import CoreAudio
import Foundation
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appController: AppController
    @State private var selectedEngine = "System"
    @AppStorage("transcriptionLanguage") private var transcriptionLanguage = "system"

    enum Section: Hashable {
        case settings
        case actions
        case error
    }

    enum SettingsRow: Hashable {
        case settingsButton
        case microphone
        case engine
        case language
    }

    struct LanguageOption: Identifiable, Equatable {
        let id: String
        let title: String
    }

    static let languageOptions: [LanguageOption] = [
        LanguageOption(id: "system", title: "System (Recommended)"),
        LanguageOption(id: "zh-Hans", title: "Chinese (Simplified)"),
        LanguageOption(id: "en-US", title: "English")
    ]

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    static func shouldShowLevel(for mode: AppMode) -> Bool {
        if case .recording = mode {
            return true
        }
        return false
    }

    static func shouldShowSecondaryStatus(for mode: AppMode) -> Bool {
        if case .recording = mode {
            return true
        }
        return false
    }

    static func shouldShowErrorStatus(for mode: AppMode) -> Bool {
        if case .error = mode {
            return true
        }
        return false
    }

    static func sectionOrderLayout(for mode: AppMode) -> [Section] {
        var sections: [Section] = [.settings, .actions]
        if shouldShowErrorStatus(for: mode) {
            sections.append(.error)
        }
        return sections
    }

    static func settingsSectionOrderLayout() -> [SettingsRow] {
        [.settingsButton, .microphone, .engine, .language]
    }

    static func shouldDisableLanguage(forEngine engine: String) -> Bool {
        engine == "Pro"
    }

    static func levelBarCount(level: Double, maxBars: Int) -> Int {
        guard maxBars > 0 else { return 0 }
        let clamped = min(1, max(0, level))
        if clamped < 0.016 { return 0 }
        let boosted = pow(clamped, 0.25)
        let scaled = (boosted * Double(maxBars)).rounded()
        return min(maxBars, max(0, Int(scaled)))
    }

    private var micSelection: Binding<AudioDeviceID?> {
        Binding(
            get: { appController.selectedMicID },
            set: { newValue in
                if let id = newValue {
                    appController.send(.selectMic(id))
                }
            }
        )
    }

    private var downloadStatusState: DownloadStatusViewState {
        DownloadStatusViewModel.state(for: appController.state.modelStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Self.sectionOrderLayout(for: appController.state.mode), id: \.self) { section in
                switch section {
                case .settings:
                    settingsSection
                case .actions:
                    actionsSection
                case .error:
                    errorSection
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Self.settingsSectionOrderLayout(), id: \.self) { row in
                switch row {
                case .settingsButton:
                    settingsButtonRow
                case .microphone:
                    microphoneRow
                case .engine:
                    engineRow
                case .language:
                    languageRow
                }
            }
        }
    }

    private var settingsButtonRow: some View {
        HStack {
            Spacer()
            Button("Settings…") {
                appController.send(.openSettingsWindow)
            }
            .buttonStyle(.link)
        }
    }

    private var microphoneRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Microphone")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Microphone", selection: micSelection) {
                if appController.micDevices.isEmpty {
                    Text("No input devices").tag(Optional<AudioDeviceID>.none)
                }
                ForEach(appController.micDevices) { device in
                    Text(device.name).tag(Optional(device.id))
                }
            }
            .labelsHidden()
        }
    }

    private var engineRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Engine")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Engine", selection: $selectedEngine) {
                Text("System (Recommended)").tag("System")
                Text("High Accuracy (Offline) • Pro").tag("Pro")
                    .disabled(true)
            }
            .labelsHidden()
        }
    }

    private var languageRow: some View {
        let isDisabled = Self.shouldDisableLanguage(forEngine: selectedEngine)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Language")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Language", selection: $transcriptionLanguage) {
                ForEach(Self.languageOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Divider()

        Button(action: primaryAction) {
            Text(primaryButtonTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)

        downloadStatusSection

        VStack(spacing: 6) {
            if Self.shouldShowSecondaryStatus(for: appController.state.mode) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let text = secondaryStatusText(at: context.date) {
                        HStack {
                            Spacer()
                            Text(text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
            }

            if Self.shouldShowLevel(for: appController.state.mode) {
                LevelMeterView(level: appController.state.audioLevel)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        Text(appController.state.statusDetail(selectedMic: appController.selectedMicName))
            .font(.caption)
            .foregroundStyle(.red)
    }

    @ViewBuilder
    private var downloadStatusSection: some View {
        switch downloadStatusState {
        case .progress(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: .infinity)
        case .failed(let message):
            VStack(spacing: 4) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Retry") {
                    appController.startModelDownload()
                }
                .buttonStyle(.link)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .hidden:
            EmptyView()
        }
    }

    private func secondaryStatusText(at date: Date) -> String? {
        switch appController.state.mode {
        case .recording:
            guard let startedAt = appController.state.recordingStartedAt else { return nil }
            let elapsed = date.timeIntervalSince(startedAt)
            return Self.formatDuration(elapsed)
        case .idle, .transcribing, .error:
            return nil
        }
    }

    private var primaryButtonTitle: String {
        switch appController.state.mode {
        case .idle, .error:
            return "Start Recording"
        case .recording:
            return "Stop & Transcribe"
        case .transcribing:
            return "Transcribing…"
        }
    }

    private func primaryAction() {
        switch appController.state.mode {
        case .idle, .error:
            appController.send(.startRecording)
        case .recording:
            appController.send(.stopAndTranscribe)
        case .transcribing:
            break
        }
    }
}

private struct LevelMeterView: View {
    let level: Double
    private let maxBars = 12

    var body: some View {
        let activeBars = PopoverView.levelBarCount(level: level, maxBars: maxBars)
        HStack(spacing: 4) {
            ForEach(0..<maxBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 6, height: 6)
                    .foregroundStyle(index < activeBars ? .primary : .secondary)
                    .opacity(index < activeBars ? 0.9 : 0.3)
            }
        }
        .animation(.easeOut(duration: 0.12), value: activeBars)
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    PopoverView()
        .environmentObject(AppController())
}
#endif
