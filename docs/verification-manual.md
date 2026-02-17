# Manual Verification Checklist

Use this checklist for smoke testing before release.

## Release Artifact Sanity
- [ ] Open the generated `.dmg` and confirm it mounts without errors.
- [ ] Confirm the DMG contains `SayIt.app` and the expected install shortcut/layout.
- [ ] Launch `SayIt.app` directly from DMG once to verify first-run startup.
- [ ] Install `SayIt.app` into `/Applications`, then relaunch from `/Applications`.
- [ ] Confirm no Gatekeeper/signing warning appears on first launch from `/Applications`.
- [ ] Verify app version/build in UI matches the intended release version.

## Core Flow
- [ ] Start recording from popover, then stop and transcribe; clipboard auto-copies.
- [ ] HUD shows "Copied ✓" after transcription completes.
- [ ] Menu bar icon reflects Recording and Transcribing states.
- [ ] While HUD is visible, popover blurs and ignores interactions.

## Permissions
- [ ] First launch requests microphone and speech permissions once.
- [ ] If denied, app shows "Open System Settings" button and prevents recording.
- [ ] After granting permissions in System Settings, app allows recording without restart.
- [ ] Recording is gated: clicking "Start Recording" without permissions shows error state.

## Devices
- [ ] Switching microphone while idle updates active device immediately.
- [ ] If current device disconnects while idle, app automatically falls back to default device and shows HUD notification.
- [ ] If device disconnects while recording, app stops recording and shows error with option to restart.
- [ ] Reconnected devices reappear in the device list and can be manually reselected.

## Settings
- [ ] Login item toggle changes launch-at-login behavior.
- [ ] Global hotkey setting shows current binding.
- [ ] Attempting to set a system reserved shortcut (e.g., Cmd+Q, Cmd+W) shows error message.
- [ ] Error message "Cannot use system shortcut" appears below hotkey field.
- [ ] Invalid hotkey is rejected and previous value is retained.
- [ ] Crash reporting toggle updates preference.
- [ ] Engine selector shows Apple Speech and Whisper.
- [ ] Settings view uses the same dark card styling as the popover.

## Whisper
- [ ] Switching Engine to Whisper prompts download if the model is missing.
- [ ] Download progress shows in Settings with percentage (e.g., "45%") and supports cancel.
- [ ] Download progress also appears in popover status area.
- [ ] Failed downloads show error message with a "Retry" button.
- [ ] After download completes, status shows "Ready" with checkmark icon.
- [ ] Language picker is disabled when Engine is Whisper.
- [ ] Whisper model selection works (Tiny/Base/Small) in Settings.
- [ ] After download completes, Pro engine produces non-empty text for a short sample.
- [ ] Optional integration test: set `SAYIT_WHISPER_MODEL_PATH` to a local model file and run WhisperIntegrationTests.
- [ ] Model files are readable from app sandbox path: `~/Library/Containers/com.niu.SayIt/Data/Library/Application Support/SayIt/Models/<model>.bin`
- [ ] If download fails with DNS/network errors, verify network access and retry.
- [ ] Offline copy fallback works: copy local model to sandbox path, relaunch app, and confirm readiness.

## Performance & Latency
- [ ] Start a recording and stop after speaking a few words.
- [ ] Transcription completes within 1-2 seconds for short audio.
- [ ] For longer transcriptions (or slow network with Apple Speech), after 3 seconds status changes to "Taking longer than usual…".
- [ ] Verify `isSlow` hint appears in UI when applicable.
- [ ] Long transcription still completes successfully.

## Accessibility & Localization
- [ ] All UI elements have proper accessibility labels.
- [ ] Hardcoded strings are extracted to `Localizable.strings`.
- [ ] Dynamic status text (e.g., "Mic: Built-in Microphone") uses localized format strings.
- [ ] VoiceOver basic pass: key controls are discoverable and read in expected order.
