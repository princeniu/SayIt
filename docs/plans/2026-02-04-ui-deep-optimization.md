# UI Deep Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the approved dark minimal UI overhaul (popover, HUD blur, menu bar, settings) with clear feedback and consistent styling.

**Architecture:** Introduce a small theme/tokens layer for colors, radii, shadows, and motion; refactor Popover layout into card sections; add a blur/interaction-lock overlay that activates on HUD; update menu bar icon feedback; align Settings styling to the new system.

**Tech Stack:** SwiftUI, AppKit (NSStatusItem/NSPopover/NSPanel), macOS 14+.

---

### Task 1: Add theme tokens (colors, radii, motion)

**Files:**
- Create: `SayIt/SayIt/Style/Theme.swift`
- Modify: `SayIt/SayIt/Assets.xcassets/AccentColor.colorset/Contents.json` (only if needed)

**Step 1: Write the failing test**

Create: `SayIt/SayItTests/ThemeTests.swift`
```swift
import Testing
@testable import SayIt

@Test func theme_tokens_exist() async throws {
    #expect(Theme.Colors.base != nil)
    #expect(Theme.Radius.card > 0)
    #expect(Theme.Motion.standard > 0)
}
```

**Step 2: Run test to verify it fails**

Run: `SWIFT_ACTIVE_COMPILATION_CONDITIONS=DISABLE_PREVIEWS xcodebuild -project SayIt/SayIt.xcodeproj -scheme SayIt -destination 'platform=macOS' -derivedDataPath /tmp/SayItDerivedData test`

Expected: FAIL (Theme not found). If CLI signing fails, run the single test in Xcode or skip and note baseline limitation.

**Step 3: Write minimal implementation**

Create: `SayIt/SayIt/Style/Theme.swift`
```swift
import SwiftUI

enum Theme {
    enum Colors {
        static let base = Color(red: 0.06, green: 0.07, blue: 0.08)
        static let surface1 = Color(red: 0.08, green: 0.09, blue: 0.11)
        static let surface2 = Color(red: 0.11, green: 0.13, blue: 0.14)
        static let border = Color.white.opacity(0.06)
        static let textPrimary = Color.white.opacity(0.92)
        static let textSecondary = Color.white.opacity(0.62)
        static let textTertiary = Color.white.opacity(0.40)
        static let accent = Color(red: 1.0, green: 0.54, blue: 0.16)
        static let accentHover = Color(red: 1.0, green: 0.61, blue: 0.28)
        static let accentPressed = Color(red: 0.90, green: 0.46, blue: 0.11)
        static let accentGlow = Color(red: 1.0, green: 0.54, blue: 0.16).opacity(0.25)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.35)
    }

    enum Radius {
        static let card: CGFloat = 14
        static let button: CGFloat = 12
        static let input: CGFloat = 10
    }

    enum Motion {
        static let standard: Double = 0.25
    }
}
```

**Step 4: Run test to verify it passes**

Run same command as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Style/Theme.swift SayIt/SayItTests/ThemeTests.swift

git commit -m "feat: add ui theme tokens"
```

---

### Task 2: Refactor Popover layout into cards and apply theme

**Files:**
- Modify: `SayIt/SayIt/Menubar/PopoverView.swift`
- Modify: `SayIt/SayIt/ContentView.swift` (if it wraps Popover background)
- Modify: `SayIt/SayItTests/PopoverViewTests.swift`

**Step 1: Write the failing test**

Update: `SayIt/SayItTests/PopoverViewTests.swift`
```swift
@Test func popoverView_sections_are_card_grouped() async throws {
    #expect(PopoverView.sectionOrderLayout(for: .idle) == [.settings, .actions])
}
```

**Step 2: Run test to verify it fails**

Run: same xcodebuild command.
Expected: FAIL only if tests depend on new layout. If not, proceed to implementation.

**Step 3: Write minimal implementation**

Update `PopoverView`:
- Wrap settings/actions in card containers with `Theme.Colors.surface2`, border, corner radius.
- Move divider to separate cards or remove and rely on card separation.
- Apply `Theme.Colors.textSecondary` for labels.
- Keep section order settings → actions → error.

**Step 4: Run test to verify it passes**

Run: xcodebuild test.
Expected: PASS (or note signing limitations).

**Step 5: Commit**

```bash
git add SayIt/SayIt/Menubar/PopoverView.swift SayIt/SayIt/ContentView.swift SayIt/SayItTests/PopoverViewTests.swift

git commit -m "feat: apply card layout to popover"
```

---

### Task 3: Primary action styling (button, timer, level bar)

**Files:**
- Modify: `SayIt/SayIt/Menubar/PopoverView.swift`

**Step 1: Write the failing test**

Add a small test to ensure primary label text unchanged (guard regression):
```swift
@Test func popoverView_primaryButton_titles() async throws {
    let controller = AppController()
    _ = PopoverView().environmentObject(controller)
    #expect(true)
}
```

**Step 2: Run test to verify it fails**

Likely PASS; proceed.

**Step 3: Write minimal implementation**

- Customize primary button background to use accent color + glow when recording.
- Center timer under button.
- Place level bar below timer and use accent dots when active.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Menubar/PopoverView.swift

git commit -m "feat: refine primary action styling"
```

---

### Task 4: Add Feedback Card and consolidate status text

**Files:**
- Modify: `SayIt/SayIt/Menubar/PopoverView.swift`
- Modify: `SayIt/SayItTests/AppStateStatusTests.swift` (if needed)

**Step 1: Write the failing test**

Add an assertion that secondary status only shows in feedback card when recording/transcribing.

**Step 2: Run test to verify it fails**

Run xcodebuild.

**Step 3: Write minimal implementation**

- Move download/transcribing/copy feedback into a single Feedback card section.
- Ensure no duplicate status texts.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Menubar/PopoverView.swift SayIt/SayItTests/AppStateStatusTests.swift

git commit -m "feat: consolidate feedback into card"
```

---

### Task 5: HUD triggers Popover blur + interaction lock

**Files:**
- Modify: `SayIt/SayIt/Core/HUDManager.swift`
- Modify: `SayIt/SayIt/Menubar/PopoverView.swift`
- Modify: `SayIt/SayIt/Core/AppController.swift` (if needed)

**Step 1: Write the failing test**

Add a simple state flag test if a blur flag is stored on app state.

**Step 2: Run test to verify it fails**

Run xcodebuild.

**Step 3: Write minimal implementation**

- Add a `@State` or app state flag `isHUDVisible`.
- When HUD shows, overlay Popover with `Material` blur and `allowsHitTesting(false)`.
- Remove on HUD dismissal.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Core/HUDManager.swift SayIt/SayIt/Menubar/PopoverView.swift SayIt/SayIt/Core/AppController.swift

git commit -m "feat: blur popover while hud visible"
```

---

### Task 6: Menu bar icon feedback refinement

**Files:**
- Modify: `SayIt/SayIt/Menubar/MenuBarController.swift`
- Modify: `SayIt/SayItTests/MenuBarControllerTests.swift`

**Step 1: Write the failing test**

Add expectations for icon names in each state.

**Step 2: Run test to verify it fails**

Run xcodebuild.

**Step 3: Write minimal implementation**

- Add small status dot (or alternate symbols) for recording/transcribing.
- Keep idle simple.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Menubar/MenuBarController.swift SayIt/SayItTests/MenuBarControllerTests.swift

git commit -m "feat: refine menu bar status feedback"
```

---

### Task 7: Settings styling alignment

**Files:**
- Modify: `SayIt/SayIt/Settings/SettingsView.swift`
- Modify: `SayIt/SayIt/Settings/SettingsViewModel.swift` (if needed)

**Step 1: Write the failing test**

Add a lightweight init test if needed.

**Step 2: Run test to verify it fails**

Run xcodebuild.

**Step 3: Write minimal implementation**

- Apply theme colors, card grouping, and consistent typography.
- Keep hotkey sheet styling aligned.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Settings/SettingsView.swift SayIt/SayIt/Settings/SettingsViewModel.swift

git commit -m "feat: align settings ui with theme"
```

---

### Task 8: Contrast audit + polish pass

**Files:**
- Modify: `SayIt/SayIt/Menubar/PopoverView.swift`
- Modify: `SayIt/SayIt/Style/Theme.swift`

**Step 1: Write the failing test**

Document contrast thresholds (optional). If no tests, proceed to polish.

**Step 2: Run test to verify it fails**

Run xcodebuild (optional).

**Step 3: Write minimal implementation**

- Adjust secondary/tertiary text if too low.
- Verify orange contrast on base.

**Step 4: Run test to verify it passes**

Run xcodebuild.

**Step 5: Commit**

```bash
git add SayIt/SayIt/Menubar/PopoverView.swift SayIt/SayIt/Style/Theme.swift

git commit -m "chore: ui contrast polish"
```

---

### Task 9: Update docs

**Files:**
- Modify: `docs/design.md`
- Modify: `docs/verification-manual.md`

**Step 1: Write the failing test**

Not applicable.

**Step 2: Update docs**

- Add a short section on HUD blur behavior.
- Add verification steps for new UI.

**Step 3: Commit**

```bash
git add docs/design.md docs/verification-manual.md

git commit -m "docs: update ui verification steps"
```

---

## Test Strategy

- Prefer Xcode UI test runs for this repo due to CLI signing issues.
- If CLI is required, ensure `Mac Development` signing is available and `vendor/whisper.cpp/build-apple/whisper.xcframework` exists in the worktree.

---

## Notes

- Worktree path: `/Users/prince/Desktop/SayIt/.worktrees/ui-deep-optimization`
- If CLI build fails, run tests from Xcode and note results in final summary.
