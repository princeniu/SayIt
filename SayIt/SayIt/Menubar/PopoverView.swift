import CoreAudio
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appController: AppController
    @State private var selectedEngine = "System"

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
        }
        .padding(16)
        .frame(width: 320)
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
