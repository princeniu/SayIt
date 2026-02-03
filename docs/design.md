# SayIt Design Doc (MVP)

## Understanding Summary
- Build a macOS menu bar dictation tool with a Popover UI; no Dock icon, no focus stealing.
- Primary flow: Start Recording → Stop & Transcribe → auto-copy → HUD “Copied”.
- Apple Speech is default engine; Whisper shown as Pro (disabled).
- Dynamic microphone selection in-app; handle device changes and fallback.
- Permissions requested once on first launch (mic + speech); denied states show guidance.
- MVP includes global hotkey and login item; no history and no audio persistence.

## Assumptions
- Minimum supported macOS: 14 (Sonoma).
- Stability > speed; no strict latency SLA.
- Crash reporting allowed but user can disable.
- Small private beta scale (<100 users).

## Decision Log
- Architecture: SwiftUI + AppKit StatusItem bridge for best control (chosen over pure SwiftUI/AppKit).
- Popover: non-activating; HUD used for transient “Copied” events.
- State machine: Idle/Recording/Transcribing/Error; `isSlow` only UI hint, not error.
- Error UX: primary button always “Start Recording”; error actions are secondary.
- Permissions: request mic + speech once on first launch.
- Storage: no audio saved; no history in MVP.
- Settings: login item + global hotkey included.
- Menu bar icon: light status indication for Recording/Transcribing.
- Feedback UX: connection shown in status row; recording time + transcribing text shown below button; copied uses HUD.

## Architecture
### High-Level Modules
- **AppController (StateMachineRunner)**: single source of truth; handles intents and side effects.
- **PermissionManager**: requests/reads mic + speech permissions; opens System Settings.
- **AudioDeviceManager**: enumerates input devices; listens for changes; maintains selection and fallback.
- **AudioCaptureEngine**: captures audio from selected device; finalize on stop; no disk persistence.
- **TranscriptionEngine (protocol)**
  - **AppleSpeechEngine**: concrete implementation.
  - **WhisperEngine**: placeholder only.
- **ClipboardManager**: writes transcription to clipboard (primary success signal).
- **HUDManager**: toast/HUD for copied, device switch, errors.

### Data Flow
- UI → `AppController.send(intent)` → state transition + side effects
- Side effects update state and trigger HUD/clipboard events
- Device events → `AudioDeviceManager` → `AppController` → state + HUD

## State Machine
- **Idle**
  - Start Recording → Recording (after permissions ok)
- **Recording**
  - Stop & Transcribe → Finalize audio → Transcribing
  - Cancel → Idle (discard buffer)
  - Device disconnect → Error(deviceDisconnectedDuringRecording)
- **Transcribing**
  - Slow path → `isSlow = true` (UI “Still working…”)
  - Success → clipboard write → HUD “Copied” → Idle
  - Failure → Error(transcriptionFailed)
- **Error**
  - Primary: Start Recording (if recoverable)
  - Secondary: Open System Settings / Retry Transcribe (if applicable)

## UI/UX (Popover)
- **Status Row**: `State` + `Reason` (single line)
- **Primary Button**: Start Recording / Stop & Transcribe
- **Secondary** (Recording only): Cancel
- **Microphone Selector**: dropdown showing current selection; device change handled dynamically
- **Engine Selector**: System (recommended) / High Accuracy (Offline) [Pro disabled]
- **Permissions Denied**: clear message + Open System Settings

## User Feedback (Smooth & Consistent)
- **Connecting**: after Start, show “Connecting…” in status row until capture actually begins.
- **Recording Duration**: show `MM:SS` below the primary button, updating every second.
- **Transcribing**: show “Transcribing…” below the primary button; after 5s show “Still working…”.
- **Copied**: show HUD/Toast “Copied ✓” (no focus steal), then return to Idle.

## Settings
- Login item (auto start)
- Global hotkey (editable)
- Crash reporting toggle

## Non-goals (MVP)
- No push-to-talk
- No history or transcript library
- No audio storage
- No Whisper implementation
- No main window

## Risks / Mitigations
- **Device disconnect during recording**: stop capture, show error, allow restart.
- **Speech permission denial**: explicit UI state + settings link.
- **Transcription latency**: `isSlow` UI hint; no premature error.
