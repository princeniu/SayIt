import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var crashReportingEnabled = true
    @State private var showHotkeySheet = false
    @AppStorage("hotkeyDisplay") private var hotkeyDisplay = Hotkey.defaultValue.display
    @AppStorage("hotkeyKeyCode") private var hotkeyKeyCode = Int(Hotkey.defaultValue.keyCode)
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers = Int(Hotkey.defaultValue.modifiers.carbonValue)

    var body: some View {
        Form {
            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                )
            )
            Picker("Whisper Model", selection: $viewModel.preferredModel) {
                ForEach(WhisperModelType.allCases, id: \.self) { model in
                    Text(model.rawValue.capitalized).tag(model)
                }
            }
            HStack {
                Text("Global hotkey")
                Spacer()
                Text(hotkeyDisplay)
                    .foregroundColor(.secondary)
                Button("Change…") {
                    showHotkeySheet = true
                }
                .buttonStyle(.link)
            }
            Toggle("Crash reporting", isOn: $crashReportingEnabled)
        }
        .frame(width: 360, height: 220)
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
}

#if !DISABLE_PREVIEWS
#Preview {
    SettingsView()
}
#endif
