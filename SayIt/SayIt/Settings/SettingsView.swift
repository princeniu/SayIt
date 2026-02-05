import SwiftUI

@MainActor
struct SettingsView: View {
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
                Picker("", selection: $viewModel.preferredModel) {
                    ForEach(WhisperModelType.allCases, id: \.self) { model in
                        Text(model.rawValue.capitalized).tag(model)
                    }
                }
                .labelsHidden()
            }
            settingsRow(title: "Global hotkey") {
                HStack(spacing: 8) {
                    Text(hotkeyDisplay)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Button("Change…") {
                        showHotkeySheet = true
                    }
                    .buttonStyle(.link)
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
            HotkeyCaptureSheet { hotkey in
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
}

#if !DISABLE_PREVIEWS
#Preview {
    SettingsView()
}
#endif
