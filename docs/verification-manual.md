# Manual Verification Checklist

Use this checklist for smoke testing before release.

## Core Flow
- Start recording from popover, then stop and transcribe, clipboard auto-copies.
- HUD shows "Copied ✓" after transcription completes.
- Menu bar icon reflects Recording and Transcribing states.
- While HUD is visible, popover blurs and ignores interactions.

## Permissions
- First launch requests microphone and speech permissions once.
- If denied, app shows settings entry and remains usable after enabling.

## Devices
- Switching microphone while idle updates active device.
- If current device disconnects while idle, app falls back and shows a toast.
- If device disconnects while recording, app stops and shows an error.

## Settings
- Login item toggle changes launch-at-login behavior.
- Global hotkey setting shows current binding.
- Crash reporting toggle updates preference.
- Engine selector shows System (recommended) and High Accuracy (Offline) • Pro.
- Settings view uses the same dark card styling as the popover.

## Whisper (Pro / Offline)
- Switching Engine to Pro prompts download if the model is missing.
- Download progress shows under the primary button and can be canceled.
- Failed downloads show a retry action.
- Language picker becomes disabled when Engine is Pro.
- Whisper model selection works (Tiny/Base/Small).
- After download completes, Pro engine produces non-empty text for a short sample.
- Optional integration test: set `SAYIT_WHISPER_MODEL_PATH` to the local model file (e.g. `/Users/prince/Desktop/SayIt/.worktrees/whisper/SayIt/vendor/whisper.cpp/models/ggml-small.bin`) and run WhisperIntegrationTests.
- Model files must live in the app sandbox:
  - `~/Library/Containers/com.niu.SayIt/Data/Library/Application Support/SayIt/Models/<model>.bin`
  - Example: `small.bin`
- If download fails with DNS/network errors, verify the app can access the network and then retry.
- Offline copy option:
  - Copy a local model into the sandbox path above (e.g. `small.bin`), then relaunch the app.
