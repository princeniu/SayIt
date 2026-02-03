import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var crashReportingEnabled = true
    @State private var hotkeyDescription = "Not set"

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
            HStack {
                Text("Global hotkey")
                Spacer()
                Text(hotkeyDescription)
                    .foregroundColor(.secondary)
            }
            Toggle("Crash reporting", isOn: $crashReportingEnabled)
            Picker("Recognition engine", selection: .constant("system")) {
                Text("System (Recommended)").tag("system")
                Text("High Accuracy (Offline) — Pro").tag("pro")
            }
            .disabled(true)
        }
        .frame(width: 360, height: 220)
        .padding()
    }
}

#Preview {
    SettingsView()
}
