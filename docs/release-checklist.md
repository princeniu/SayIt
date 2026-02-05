# Release Checklist

Follow these steps before every public release of SayIt.

## 1. Pre-Build Verification
- [ ] **Unit Tests**: Run `xcodebuild test` and ensure all tests pass.
- [ ] **UI Tests**: Verify core flows (hotkey, recording, transcribing) manually or via UI tests.
- [ ] **Permissions**: Test on a clean machine to ensure permission prompts appear correctly.
- [ ] **Model Download**: Verify Whisper model downloading works and progress is shown.

## 2. Versioning
- [ ] Increment `MARKETING_VERSION` in Project Settings (e.g., `1.0.1`).
- [ ] Increment `CURRENT_PROJECT_VERSION` (Build number).
- [ ] Update `README.md` and `CHANGELOG.md` (if applicable).

## 3. Build & Packaging
- [ ] Run `scripts/package-release.sh`.
- [ ] Verify the generated `.dmg` contains the app and launches correctly.
- [ ] (Optional) Notarize the app using `xcrun notarytool` if distributed outside Mac App Store.

## 4. Distribution
- [ ] Create a new Release Tag on GitHub (`v1.0.0`).
- [ ] Upload the `.dmg` to the GitHub Release assets.
- [ ] Update the project website/documentation.
