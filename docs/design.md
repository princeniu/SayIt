# SayIt Design Doc

## Understanding Summary
- Build a macOS menu bar dictation tool with a Popover UI; no Dock icon, no focus stealing.
- Primary flow: Start Recording → Stop & Transcribe → auto-copy → HUD “Copied”.
- Apple Speech is default engine; Whisper is Pro (offline) with model download.
- Dynamic microphone selection in-app; handle device changes and fallback.
- Permissions requested once on first launch (mic + speech); denied states show guidance.
- MVP includes global hotkey and login item; no history and no audio persistence.
- Whisper uses whisper.cpp, models download on first launch prompt; default model small.

## Assumptions
- Minimum supported macOS: 14 (Sonoma).
- Stability > speed; no strict latency SLA.
- Crash reporting allowed but user can disable.
- Small private beta scale (<100 users).
- Whisper short-utterance target latency: 10–20 seconds.

## Decision Log
- Architecture: SwiftUI + AppKit StatusItem bridge for best control (chosen over pure SwiftUI/AppKit).
- Popover: non-activating; HUD used for transient “Copied” events.
- State machine: Idle/Recording/Transcribing/Error; `isSlow` only UI hint, not error.
- Error UX: primary button always “Start Recording”; error actions are secondary.
- Permissions: request mic + speech once on first launch.
- Storage: no audio saved; no history in MVP.
- Settings: login item + global hotkey included.
- Menu bar icon: light status indication for Recording/Transcribing.
- Feedback UX: recording time + transcribing text shown below button; copied uses HUD.
- Global hotkey: Carbon RegisterEventHotKey for reliability; default ⌥Z; user can rebind.
- Audio level: system-like dot indicator; only visible during recording; placed under recording duration.
- Whisper route: whisper.cpp (CPU-friendly, quantization possible).
- Whisper download: prompt on first launch; user can skip; model stored in Application Support.
- Default Whisper model: small; user can switch tiny/base/small.
- Download UI: progress below primary button; failure shows retry.
- Download completion: prompt to switch to Pro.
- Whisper failure: prompt to fallback to system.
- Model updates: background check every 30 days; prompt to update and switch.
- Download can be canceled by user.

## Architecture
### High-Level Modules
- **AppController (StateMachineRunner)**: single source of truth; handles intents and side effects.
- **PermissionManager**: requests/reads mic + speech permissions; opens System Settings.
- **AudioDeviceManager**: enumerates input devices; listens for changes; maintains selection and fallback.
- **AudioCaptureEngine**: captures audio from selected device; finalize on stop; no disk persistence.
- **TranscriptionEngine (protocol)**
  - **AppleSpeechEngine**: concrete implementation.
  - **WhisperEngine**: whisper.cpp integration (Pro).
- **ClipboardManager**: writes transcription to clipboard (primary success signal).
- **HUDManager**: toast/HUD for copied, device switch, errors.
- **ModelManager**: model metadata, paths, hash/size validation, readiness.
- **ModelDownloader**: download lifecycle, progress, retry, cancel.

### Data Flow
- UI → `AppController.send(intent)` → state transition + side effects
- Side effects update state and trigger HUD/clipboard events
- Device events → `AudioDeviceManager` → `AppController` → state + HUD
- Whisper usage: finalize audio → WhisperEngine (if model ready) → clipboard

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
- **ModelStatus (Whisper)**
  - `idle` → `downloading(progress)` → `ready(modelType)` → `failed(error)`

## UI/UX (Popover)
- **Status Row**: `State` + `Reason` (single line)
- **Primary Button**: Start Recording / Stop & Transcribe
- **Secondary** (Recording only): Cancel
- **Microphone Selector**: dropdown showing current selection; device change handled dynamically
- **Engine Selector**: System (recommended) / High Accuracy (Offline) [Pro]
- **Whisper Download Progress**: shown below primary button when downloading
- **Permissions Denied**: clear message + Open System Settings
- **Audio Level Indicator**: system-like dot bar; visible only during recording; placed under recording duration

## User Feedback (Smooth & Consistent)
- **Recording Duration**: show `MM:SS` below the primary button, updating every second.
- **Transcribing**: show “Transcribing…” below the primary button; after 5s show “Still working…”.
- **Copied**: show HUD/Toast “Copied ✓” (no focus steal), then return to Idle.
- **Whisper Download**: progress below primary button; failure shows retry.

## Settings
- Login item (auto start)
- Global hotkey (editable, default ⌥Z)
- Crash reporting toggle
- Whisper model selection (tiny/base/small)

## Non-goals (MVP)
- No push-to-talk
- No history or transcript library
- No audio storage
- No main window

## Risks / Mitigations
- **Device disconnect during recording**: stop capture, show error, allow restart.
- **Speech permission denial**: explicit UI state + settings link.
- **Transcription latency**: `isSlow` UI hint; no premature error.
- **Whisper download failure**: retry action; fallback to system.
