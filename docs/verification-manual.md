# Manual Verification Checklist

Use this checklist for smoke testing before release.

## Core Flow
- Start recording from popover, then stop and transcribe, clipboard auto-copies.
- HUD shows "Copied ✓" after transcription completes.
- Menu bar icon reflects Recording and Transcribing states.

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
- Engine selector shows System (recommended) and Pro disabled.

## Whisper (Pro)
- First launch prompts to download Whisper model; user can skip.
- Download shows progress below the primary button.
- Cancel download returns to idle without switching engine.
- Download failure shows error with retry.
- Download complete prompts to switch to Pro.
- Engine selector allows switching between System and Pro.
- Whisper failure prompts whether to fall back to System.
- Model selection (tiny/base/small) updates the next run.
