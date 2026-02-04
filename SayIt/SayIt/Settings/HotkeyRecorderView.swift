import AppKit
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    final class RecorderView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }

    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: RecorderView, context: Context) {
        nsView.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

struct HotkeyCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    let onSave: (Hotkey) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Press a new shortcut")
                .font(.headline)
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HotkeyRecorderView { event in
                handle(event: event)
            }
            .frame(height: 36)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func handle(event: NSEvent) {
        let modifiers = HotkeyModifiers.from(eventFlags: event.modifierFlags)
        guard modifiers.hasAny else {
            errorMessage = "Use at least one modifier key"
            return
        }
        guard let key = event.charactersIgnoringModifiers?.uppercased(), key.count == 1 else {
            errorMessage = "Unsupported key"
            return
        }
        let display = modifiers.display + key
        let hotkey = Hotkey(keyCode: UInt32(event.keyCode), modifiers: modifiers, display: display)
        onSave(hotkey)
        dismiss()
    }
}
