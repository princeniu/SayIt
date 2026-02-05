import SwiftUI

@MainActor
struct SettingsView: View {
    @EnvironmentObject private var appController: AppController
    @StateObject private var viewModel: SettingsViewModel
    @State private var crashReportingEnabled = true
    @State private var showHotkeySheet = false
    @AppStorage("hotkeyDisplay") private var hotkeyDisplay = Hotkey.defaultValue.display
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode = Int(Hotkey.defaultValue.keyCode)
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers = Int(Hotkey.defaultValue.modifiers.carbonValue)

    static let cardWidth: CGFloat = 360
    static let cardPadding: CGFloat = 16

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsRow(title: "Launch at login") {
                Toggle("", isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                ))
                .labelsHidden()
            }
            settingsRow(title: "Whisper Model") {
                VStack(alignment: .trailing, spacing: 6) {
                    Picker("", selection: $viewModel.preferredModel) {
                        ForEach(WhisperModelType.allCases, id: \.self) { model in
                            Text(model.rawValue.capitalized).tag(model)
                        }
                    }
                    .onChange(of: viewModel.preferredModel) { _ in
                        appController.checkModelStatus()
                    }
                    
                    modelStatusView(status: appController.state.modelStatus)
                }
            }
            settingsRow(title: "Crash reporting") {
                Toggle("", isOn: $crashReportingEnabled)
                    .labelsHidden()
            }
        }
        .padding(Self.cardPadding)
        .frame(width: Self.cardWidth)
        .background(Theme.Colors.surface2)
        .cornerRadius(Theme.Radius.card)
        .padding()
        .sheet(isPresented: $showHotkeySheet) {
            HotkeyCaptureSheet(validate: viewModel.validateHotkey) { hotkey in
                hotkeyDisplay = hotkey.display
                hotkeyKeyCode = Int(hotkey.keyCode)
                hotkeyModifiers = Int(hotkey.modifiers.carbonValue)
                HotkeyStorage.save(hotkey, into: .standard)
            }
        }
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .foregroundColor(Theme.Colors.textPrimary)
            Spacer()
            content()
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func modelStatusView(status: ModelStatus) -> some View {
        switch status {
        case .idle:
            if !appController.isWhisperModelReady {
                Button("Download") {
                    appController.startModelDownload()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        case .ready:
            Label("Ready", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Theme.Colors.success)
        case .failed(let message):
            VStack(alignment: .trailing, spacing: 2) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.error)
                Button(String(localized: "Retry")) {
                    appController.startModelDownload()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    SettingsView()
}
#endif
