# SayIt Menu Bar Dictation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS menu bar dictation app with a single-toggle recording flow, reliable device selection, Apple Speech transcription, auto-copy, and local history.

**Architecture:** SwiftUI Popover UI sends intents to an AppController/StateMachineRunner. The controller reduces intents to state + side effects and coordinates PermissionManager, AudioDeviceManager, AudioCaptureEngine, TranscriptionEngine, ClipboardManager, HistoryStore, and HUDManager.

**Tech Stack:** Swift, SwiftUI, AppKit (NSStatusBar/NSPopover), AVFoundation, Speech framework, XCTest.

---

### Task 1: Create the Xcode project and base targets

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt.xcodeproj` (Xcode GUI)
- Create: `/Users/prince/Desktop/SayIt/SayIt/SayItApp.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Info.plist`

**Step 1: Create the project (GUI)**
- In Xcode, create a new macOS App named `SayIt` in `/Users/prince/Desktop/SayIt`.
- Language: Swift. Interface: SwiftUI. Include Tests: Yes.
- Disable document-based app.

**Step 2: Configure Info.plist for menu bar app**
- Add `Application is agent (UIElement)` = YES (LSUIElement).

**Step 3: Build to verify**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "chore: initialize macOS app"
```

---

### Task 2: Add AppState, AppIntent, and reducer skeleton

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/AppState.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/AppIntent.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/AppControllerTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class AppControllerTests: XCTestCase {
    func test_startRecording_fromIdle_setsRecordingState() {
        let controller = AppController()
        XCTAssertEqual(controller.state.mode, .idle)

        controller.send(.startRecording)

        XCTAssertEqual(controller.state.mode, .recording)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (AppController not found)

**Step 3: Write minimal implementation**
```swift
import Foundation

public enum AppMode: Equatable {
    case idle
    case recording
    case transcribing(isSlow: Bool)
    case error(AppError)
}

public struct AppState: Equatable {
    public var mode: AppMode = .idle
}

public enum AppIntent {
    case startRecording
}

public final class AppController: ObservableObject {
    @Published public private(set) var state = AppState()

    public func send(_ intent: AppIntent) {
        switch intent {
        case .startRecording:
            state.mode = .recording
        }
    }
}

public enum AppError: Equatable {
    case permissionDenied
}
```

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add app state and controller skeleton"
```

---

### Task 3: Wire menu bar app shell (status item + popover)

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Menubar/MenuBarController.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/SayItApp.swift`

**Step 1: Write the failing test**
- No UI test. Add a compile-only test to ensure MenuBarController initializes.

```swift
import XCTest
@testable import SayIt

final class MenuBarControllerTests: XCTestCase {
    func test_menuBarController_initializes() {
        _ = MenuBarController()
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (MenuBarController not found)

**Step 3: Write minimal implementation**
- MenuBarController creates NSStatusItem and NSPopover hosting SwiftUI view.
- SayItApp initializes MenuBarController once.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add menu bar popover shell"
```

---

### Task 4: Build Popover UI (state line + main button + mic + engine + recent 3)

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Menubar/PopoverView.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Menubar/RecentListView.swift`

**Step 1: Write the failing test**
- Snapshot tests not required. Add a compile-only test to ensure view compiles.

```swift
import XCTest
import SwiftUI
@testable import SayIt

final class PopoverViewTests: XCTestCase {
    func test_popoverView_initializes() {
        _ = PopoverView()
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (PopoverView not found)

**Step 3: Write minimal implementation**
- Render status line (left status, right explanation), main button, mic picker stub, engine picker stub, recent 3 stub.
- Bind UI to AppController state via EnvironmentObject.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add popover ui skeleton"
```

---

### Task 5: PermissionManager and permission flow

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Permissions/PermissionManager.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/PermissionManagerTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class PermissionManagerTests: XCTestCase {
    func test_permissionManager_initialState_unknown() {
        let manager = PermissionManager()
        XCTAssertEqual(manager.micStatus, .unknown)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (PermissionManager not found)

**Step 3: Write minimal implementation**
- Define mic/speech permission statuses.
- Add methods to request permissions and open system settings.
- AppController checks permissions before entering recording.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add permission manager"
```

---

### Task 6: AudioDeviceManager with dynamic device events

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Audio/AudioDeviceManager.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/AudioDeviceManagerTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class AudioDeviceManagerTests: XCTestCase {
    func test_deviceManager_initially_hasEmptyList() {
        let manager = AudioDeviceManager()
        XCTAssertNotNil(manager.devices)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (AudioDeviceManager not found)

**Step 3: Write minimal implementation**
- Enumerate input devices via AVFoundation.
- Publish devices and current selection.
- Emit events for deviceSwitched/deviceUnavailable.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add audio device manager"
```

---

### Task 7: AudioCaptureEngine with finalize/cancel

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Audio/AudioCaptureEngine.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/AudioCaptureEngineTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class AudioCaptureEngineTests: XCTestCase {
    func test_engine_startsAndStops() {
        let engine = AudioCaptureEngine()
        XCTAssertNoThrow(try engine.start())
        XCTAssertNoThrow(try engine.stopAndFinalize())
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (AudioCaptureEngine not found)

**Step 3: Write minimal implementation**
- Use AVAudioEngine/AVAudioFile to record selected input.
- Implement start(), stopAndFinalize(), cancel().

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add audio capture engine"
```

---

### Task 8: TranscriptionEngine protocol + AppleSpeechEngine

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Transcription/TranscriptionEngine.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Transcription/AppleSpeechEngine.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Transcription/WhisperEngine.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/TranscriptionEngineTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class TranscriptionEngineTests: XCTestCase {
    func test_engine_interface() async throws {
        let engine: TranscriptionEngine = AppleSpeechEngine()
        _ = try await engine.transcribe(url: URL(fileURLWithPath: "/tmp/empty.wav"), locale: Locale(identifier: "zh_CN"))
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (TranscriptionEngine not found)

**Step 3: Write minimal implementation**
- Define protocol with async `transcribe(url:locale:)`.
- AppleSpeechEngine uses Speech framework.
- WhisperEngine is placeholder throwing notImplemented.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS (or adjust test to skip if no file)

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add transcription engines"
```

---

### Task 9: ClipboardManager + HistoryStore + HUDManager

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/ClipboardManager.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/HistoryStore.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/Core/HUDManager.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`
- Test: `/Users/prince/Desktop/SayIt/SayItTests/ClipboardManagerTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class ClipboardManagerTests: XCTestCase {
    func test_writeToClipboard_returnsTrue() {
        let manager = ClipboardManager()
        XCTAssertTrue(manager.write("hello"))
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (ClipboardManager not found)

**Step 3: Write minimal implementation**
- ClipboardManager writes to NSPasteboard.
- HistoryStore persists to Application Support; caps by 7 days or N items.
- HUDManager shows toast for Copied/device changes.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add clipboard, history, hud managers"
```

---

### Task 10: Connect UI intents to AppController and complete flow

**Files:**
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Menubar/PopoverView.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Core/AppController.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class FlowTests: XCTestCase {
    func test_stopTransitionsToTranscribing() {
        let controller = AppController()
        controller.send(.startRecording)
        controller.send(.stopAndTranscribe)
        if case .transcribing = controller.state.mode { } else { XCTFail("Expected transcribing") }
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (stop intent not wired)

**Step 3: Write minimal implementation**
- Add intents: stopAndTranscribe, cancel, retryTranscribe, selectMic, openSettings.
- Implement reducer transitions and side effects sequencing.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: wire ui intents to controller"
```

---

### Task 11: Settings + History view (View all)

**Files:**
- Create: `/Users/prince/Desktop/SayIt/SayIt/Settings/SettingsView.swift`
- Create: `/Users/prince/Desktop/SayIt/SayIt/History/HistoryView.swift`
- Modify: `/Users/prince/Desktop/SayIt/SayIt/Settings/SettingsWindowController.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import SayIt

final class SettingsViewTests: XCTestCase {
    func test_settingsView_initializes() {
        _ = SettingsView()
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: FAIL (SettingsView not found)

**Step 3: Write minimal implementation**
- Settings shows engine selector, history retention values, and “View all”.
- HistoryView lists entries with copy action.

**Step 4: Run test to verify it passes**
Run: `xcodebuild -project /Users/prince/Desktop/SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' test`
Expected: PASS

**Step 5: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "feat: add settings and history views"
```

---

### Task 12: Manual verification checklist

**Files:**
- Create: `/Users/prince/Desktop/SayIt/docs/verification-manual.md`

**Step 1: Write checklist**
- Start recording, stop and transcribe, clipboard auto-copies.
- Device switch/fallback works while idle and recording.
- Permission denied shows settings button.
- Recent 3 entries copy on click.

**Step 2: Commit**
```bash
git -C /Users/prince/Desktop/SayIt add -A
git -C /Users/prince/Desktop/SayIt commit -m "docs: add manual verification checklist"
```
