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
            HStack(spacing: 8) {
                Text(statusTitle)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let text = secondaryStatusText(at: context.date) {
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        case .transcribing:
            if let startedAt = appController.state.transcribingStartedAt {
                if date.timeIntervalSince(startedAt) > 5 {
                    return "Still working…"
                }
            }
            return "Transcribing…"
        case .idle, .error:
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

#Preview {
    PopoverView()
        .environmentObject(AppController())
}
