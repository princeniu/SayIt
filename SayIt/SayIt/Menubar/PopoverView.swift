import CoreAudio
import Foundation
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appController: AppController
    @State private var selectedEngine = "System"
    @AppStorage("transcriptionLanguage") private var transcriptionLanguage = "system"

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

    static func shouldShowHeader(for mode: AppMode) -> Bool {
        if case .transcribing = mode {
            return false
        }
        return true
    }

    static func levelBarCount(level: Double, maxBars: Int) -> Int {
        guard maxBars > 0 else { return 0 }
        let clamped = min(1, max(0, level))
        if clamped < 0.016 { return 0 }
        let boosted = pow(clamped, 0.25)
        let scaled = (boosted * Double(maxBars)).rounded()
        return min(maxBars, max(0, Int(scaled)))
    }

    private var statusTitle: String {
        switch appController.state.mode {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .error:
            return "Error"
        }
    }

    private var statusDetail: String {
        appController.state.statusDetail(selectedMic: appController.selectedMicName)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if Self.shouldShowHeader(for: appController.state.mode) {
                HStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text(statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

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

            VStack(alignment: .leading, spacing: 6) {
                Text("Language")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Language", selection: $transcriptionLanguage) {
                    ForEach(Self.languageOptions) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .labelsHidden()
            }

            Divider()

            HStack {
                Spacer()
                Button("Settings…") {
                    appController.send(.openSettingsWindow)
                }
                .buttonStyle(.link)
            }
        }
        .padding(16)
        .frame(width: 320)
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

#Preview {
    PopoverView()
        .environmentObject(AppController())
}
