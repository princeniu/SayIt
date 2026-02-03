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
