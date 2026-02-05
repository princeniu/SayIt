# Manual Verification Checklist

Use this checklist for smoke testing before release.

## Core Flow
- Start recording from popover, then stop and transcribe, clipboard auto-copies.
- HUD shows "Copied ✓" after transcription completes.
- Menu bar icon reflects Recording and Transcribing states.
- While HUD is visible, popover blurs and ignores interactions.

## Permissions
- First launch requests microphone and speech permissions once.
- If denied, app shows "Open System Settings" button and prevents recording.
- After granting permissions in System Settings, app allows recording without restart.
- Recording is gated: clicking "Start Recording" without permissions shows error state.

## Devices
- Switching microphone while idle updates active device immediately.
- If current device disconnects while idle, app automatically falls back to default device and shows HUD notification.
- If device disconnects while recording, app stops recording and shows error with option to restart.
- Reconnected devices reappear in the device list and can be manually reselected.

## Settings
- Login item toggle changes launch-at-login behavior.
- Global hotkey setting shows current binding.
  - Attempting to set a system reserved shortcut (e.g., Cmd+Q, Cmd+W) shows error message.
  - Error message: "Cannot use system shortcut" appears below hotkey field.
  - Invalid hotkey is rejected and previous value is retained.
- Crash reporting toggle updates preference.
- Engine selector shows System (recommended) and High Accuracy (Offline) • Pro.
- Settings view uses the same dark card styling as the popover.
- Developer section at bottom includes:
  - Debug logging toggle with subtitle "Enable verbose console output".
  - When enabled, detailed logs appear in Console.app for troubleshooting.

## Whisper (Pro / Offline)
- Switching Engine to Pro prompts download if the model is missing.
- Download progress shows in Settings view with percentage (e.g., "45%") and can be canceled.
- Download progress also appears in popover status area.
- Failed downloads show error message with "Retry" button.
- After download completes, status shows "Ready" with checkmark icon.
- Language picker becomes disabled when Engine is Pro.
- Whisper model selection works (Tiny/Base/Small) in Settings.
- After download completes, Pro engine produces non-empty text for a short sample.
- Optional integration test: set `SAYIT_WHISPER_MODEL_PATH` to the local model file (e.g. `/Users/prince/Desktop/SayIt/.worktrees/whisper/SayIt/vendor/whisper.cpp/models/ggml-small.bin`) and run WhisperIntegrationTests.
- Model files must live in the app sandbox:
  - `~/Library/Containers/com.niu.SayIt/Data/Library/Application Support/SayIt/Models/<model>.bin`
  - Example: `small.bin`
- If download fails with DNS/network errors, verify the app can access the network and then retry.
- Offline copy option:
  - Copy a local model into the sandbox path above (e.g. `small.bin`), then relaunch the app.

## Performance & Latency
- Start a recording and stop after speaking a few words.
- Transcription should complete within 1-2 seconds for short audio.
- For longer transcriptions (or slow network with Apple Speech):
  - After 3 seconds, status text changes to "Taking longer than usual…".
  - Verify the `isSlow` hint appears in the UI.
  - Transcription should still complete successfully.

## Accessibility & Localization
- All UI elements have proper accessibility labels.
- Hardcoded strings are extracted to `Localizable.strings`.
- Dynamic status text (e.g., "Mic: Built-in Microphone") uses localized format strings.
- Test with VoiceOver to verify screen reader compatibility.
