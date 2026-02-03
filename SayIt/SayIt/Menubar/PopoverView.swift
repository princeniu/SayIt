import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appController: AppController
    @State private var selectedMic = "Default"
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
        switch appController.state.mode {
        case .idle:
            return "Mic: \(selectedMic)"
        case .recording:
            return "Tap to stop"
        case .transcribing:
            return "Working…"
        case .error:
            return "Check permissions"
        }
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
                Picker("Microphone", selection: $selectedMic) {
                    Text("Default").tag("Default")
                    Text("Built-in").tag("Built-in")
                    Text("External").tag("External")
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
            break
        case .transcribing:
            break
        }
    }
}

#Preview {
    PopoverView()
        .environmentObject(AppController())
}
