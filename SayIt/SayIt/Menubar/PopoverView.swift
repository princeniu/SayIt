import CoreAudio
import Foundation
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appController: AppController
    @StateObject private var viewModel = PopoverViewModel(state: AppState(), selectedMicName: "Unknown")
    @AppStorage("transcriptionLanguage") private var transcriptionLanguage = "system"

    static let cardSpacing: CGFloat = 12
    static let contentWidth: CGFloat = 320

    enum Section: Hashable {
        case settings
        case actions
        case status
    }

    enum SettingsRow: Hashable {
        case settingsButton
        case microphone
        case engine
        case language
    }

    enum PrimaryButtonStyle: Equatable {
        case ready
        case recording
        case transcribing
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

    static func sectionOrderLayout(for mode: AppMode) -> [Section] {
        return [.settings, .actions, .status]
    }

    static func settingsSectionOrderLayout() -> [SettingsRow] {
        [.settingsButton, .microphone, .engine, .language]
    }

    static func shouldDisableLanguage(forEngine engine: TranscriptionEngineType) -> Bool {
        engine == .whisper
    }

    static func shouldBlur(for phaseDetail: PhaseDetail?) -> Bool {
        phaseDetail == .copied
    }

    static func primaryButtonStyle(for mode: AppMode) -> PrimaryButtonStyle {
        switch mode {
        case .idle, .error:
            return .ready
        case .recording:
            return .recording
        case .transcribing:
            return .transcribing
        }
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

    private var engineSelection: Binding<TranscriptionEngineType> {
        Binding(
            get: { appController.selectedEngine },
            set: { newValue in
                appController.setEngine(newValue)
            }
        )
    }

    private var downloadStatusState: DownloadStatusViewState {
        DownloadStatusViewModel.state(for: appController.state.modelStatus)
    }

    var body: some View {
        let showDownloadPrompt = appController.selectedEngine == .whisper && !appController.isWhisperModelReady
            && downloadStatusState == .hidden
        let isBlurred = Self.shouldBlur(for: appController.state.phaseDetail)
        VStack(alignment: .leading, spacing: Self.cardSpacing) {
            ForEach(Self.sectionOrderLayout(for: appController.state.mode), id: \.self) { section in
                switch section {
                case .settings:
                    settingsSection.popoverCard()
                case .actions:
                    actionsSection.popoverCard()
                case .status:
                    let shouldShowStatus = appController.state.mode != .idle 
                        || appController.state.phaseDetail == .needsPermissions
                        || appController.state.phaseDetail == .deviceFallback
                        || showDownloadPrompt
                    
                    if shouldShowStatus {
                        statusSection(showDownloadPrompt: showDownloadPrompt)
                            .popoverCard()
                    }
                }
            }
        }
        .padding(16)
        .frame(width: Self.contentWidth)
        .background(Theme.Colors.base)
        .blur(radius: isBlurred ? 6 : 0)
        .overlay(
            Group {
                if isBlurred {
                    Theme.Colors.base.opacity(0.35)
                }
            }
        )
        .allowsHitTesting(!isBlurred)
        .animation(.easeInOut(duration: Theme.Motion.standard), value: isBlurred)
        .onAppear {
            viewModel.update(state: appController.state)
            viewModel.update(selectedMicName: appController.selectedMicName)
        }
        .onReceive(appController.$state) { state in
            viewModel.update(state: state)
            viewModel.update(selectedMicName: appController.selectedMicName)
        }
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
                .foregroundStyle(Theme.Colors.textSecondary)
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
                .foregroundStyle(Theme.Colors.textSecondary)
            Picker("Engine", selection: engineSelection) {
                Text(TranscriptionEngineType.system.displayTitle).tag(TranscriptionEngineType.system)
                Text(TranscriptionEngineType.whisper.displayTitle).tag(TranscriptionEngineType.whisper)
            }
            .labelsHidden()
        }
    }

    private var languageRow: some View {
        let isDisabled = Self.shouldDisableLanguage(forEngine: appController.selectedEngine)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Language")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            Picker("Language", selection: $transcriptionLanguage) {
                ForEach(Self.languageOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .disabled(isDisabled)
            .allowsHitTesting(!isDisabled)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        let style = Self.primaryButtonStyle(for: appController.state.mode)
        VStack(spacing: 8) {
            Button(action: primaryAction) {
                Text(LocalizedStringKey(primaryButtonTitle))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(primaryButtonFill(for: style))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Theme.Colors.border.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(primaryButtonForeground(for: style))
            .shadow(color: Theme.Colors.accentGlow, radius: style == .recording ? 14 : 0, x: 0, y: 6)
            .animation(.easeInOut(duration: Theme.Motion.standard), value: style)
            .disabled(style == .transcribing)

            if Self.shouldShowSecondaryStatus(for: appController.state.mode) || Self.shouldShowLevel(for: appController.state.mode) {
                VStack(spacing: 6) {
                    if Self.shouldShowSecondaryStatus(for: appController.state.mode) {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            if let text = secondaryStatusText(at: context.date) {
                                Text(text)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }

                    if Self.shouldShowLevel(for: appController.state.mode) {
                        LevelMeterView(level: appController.state.audioLevel)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func statusSection(showDownloadPrompt: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Priority 1: Permissions / Fallback
            if appController.state.phaseDetail == .needsPermissions {
                VStack(spacing: 6) {
                    Text("Microphone and speech permissions required")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Open System Settings") {
                        appController.send(.openSettings)
                    }
                    .buttonStyle(.link)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHint("Opens macOS System Settings")
                }
            } else if appController.state.phaseDetail == .deviceFallback {
                Text("Input device disconnected. Switched to default.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                 // Priority 2: Standard Status
                 if !viewModel.primaryStatusText.isEmpty {
                     Text(viewModel.primaryStatusText)
                         .font(.caption)
                         .foregroundStyle(Theme.Colors.textPrimary)
                 }
                 if let secondary = viewModel.secondaryStatusText {
                     Text(secondary)
                         .font(.caption)
                         .foregroundStyle(Theme.Colors.textSecondary)
                 }
            }
            
            // Priority 3: Downloads
            downloadStatusSection(showDownloadPrompt: showDownloadPrompt)
        }
    }

    @ViewBuilder
    private func downloadStatusSection(showDownloadPrompt: Bool) -> some View {
        switch downloadStatusState {
        case .hidden where showDownloadPrompt:
            VStack(spacing: 6) {
                Text("Whisper model required")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Download Model") {
                    appController.startModelDownload()
                }
                .buttonStyle(.link)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .progress(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Download progress")
        case .failed(let message):
            VStack(spacing: 4) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.error)
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

    private func primaryButtonFill(for style: PrimaryButtonStyle) -> Color {
        switch style {
        case .ready:
            return Theme.Colors.accent
        case .recording:
            return Theme.Colors.accentPressed
        case .transcribing:
            return Theme.Colors.surface2
        }
    }

    private func primaryButtonForeground(for style: PrimaryButtonStyle) -> Color {
        switch style {
        case .transcribing:
            return Theme.Colors.textSecondary
        case .ready, .recording:
            return Theme.Colors.textPrimary
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
                    .foregroundStyle(index < activeBars ? Theme.Colors.accent : Theme.Colors.textTertiary)
                    .opacity(index < activeBars ? 0.9 : 0.35)
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
