---
name: snapshot
description: Use swift-snapshot-testing to visually verify SwiftUI views during implementation. Renders views to PNG for comparison against design references. Fast feedback loop (~25s/cycle).
user-invocable: true
allowed-tools: "Bash, Read, Write, Edit, Grep, Glob"
argument-hint: "[view-name or test-target]"
---

# Snapshot-Driven UI Iteration

Use swift-snapshot-testing to create a visual feedback loop when implementing UI changes. Render SwiftUI views to PNG after each code change, compare against design goals, fix mismatches, and repeat.

## When to Use
- Implementing UI from Figma designs or reference screenshots
- Multi-step view redesigns where each step should match a target
- Any SwiftUI work where you need to visually verify output
- When design reference images are available for comparison

## When NOT to Use
- Simple single-property changes (color, font)
- Logic-only changes with no visual impact
- When the project already has snapshot tests covering the view

## Core Flow
```
1. SETUP      Add swift-snapshot-testing dependency (temporary)
2. GOAL       Collect design reference images
3. SCAFFOLD   Create snapshot test rendering the target view
4. LOOP       For each implementation step:
                a. Edit code
                b. Run snapshot test (record mode)
                c. Read generated PNG
                d. Compare against design
                e. If mismatch -> fix and re-snapshot
                f. If match -> commit the verified change, move to next step
5. CLEANUP    Revert dependency + delete test file
```

## Setup: Add Dependency

Check if `swift-snapshot-testing` already exists in `Modules/Package.swift`. If not, add it temporarily.

**In the `dependencies` array of `Modules/Package.swift`:**
```swift
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
```

**In the relevant test target's `dependencies` array:**
```swift
.product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
```

Common test targets in this project:
- `PointOfSaleTests` — for POS views
- `WooFoundationTests` — for shared UI components
- `YosemiteTests` — for business logic views

**Remember the original state** of `Modules/Package.swift` so you can revert exactly after cleanup.

## Goal: Collect References

If the user provides design reference images (Figma exports, screenshots):
```bash
mkdir -p ~/Downloads/snapshot_experiment
cp ~/path/to/design.png ~/Downloads/snapshot_experiment/design.png
```
Read each reference image to understand the target state before writing code.

If no reference image, the goal is inferred from the user's description of desired UI behavior.

## Scaffold: Create Snapshot Test

Create a test file in the appropriate `Modules/Tests/*Tests/` directory:

```swift
import XCTest
import SnapshotTesting
import SwiftUI
@testable import TargetModule

final class ViewNameSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func test_defaultState_snapshot() {
        let view = YourView(/* props for default state */)
            .frame(width: 375, height: 900)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func test_alternateState_snapshot() {
        let view = YourView(/* props for alternate state */)
            .frame(width: 375, height: 900)
        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
```

**Important details for this project:**
- `record: .all` in `invokeTest()` forces PNG generation every run
- For POS views, set `.environment(\.horizontalSizeClass, .regular)` — POS is iPad-first
- Use `.frame(width:height:)` to control render size. Start with `height: 900`, increase to `1200+` if content is clipped
- Tests will always "fail" in record mode — this is expected, they report recording, not comparison
- Use POS design tokens (`POSPadding`, `POSSpacing`, `POSFontStyle`, `Color+POSColorPalette`) when comparing POS designs

## Run: Execute Snapshot Tests

Use the `/simulator` skill approach to discover a booted simulator UDID.

Run only the snapshot tests for fast feedback:
```bash
xcodebuild test \
  -workspace WooCommerce.xcworkspace \
  -scheme WooCommerce \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -only-testing:<TestTarget>/<SnapshotTestClass> \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```

**Prefer module-level test targets** over the full app for faster feedback (~25s vs minutes).

**Generated PNGs appear at:**
```
Modules/Tests/<TestTarget>/__Snapshots__/<TestClass>/test_name.1.png
```

## Compare: Read and Assess

After each run:
1. Read the generated PNG using the Read tool
2. If a design reference exists, read it side by side
3. Identify specific mismatches: layout, spacing, missing elements, text wrapping, colors
4. Copy PNGs to working directory with step labels for history:
```bash
cp Modules/Tests/<Target>/__Snapshots__/<Class>/test_name.1.png ~/Downloads/snapshot_experiment/step1.png
```

## Fix: Iterate on Mismatches

Common issues caught by snapshots:
- **Text wrapping** in pills/badges at narrow widths — add `.lineLimit(1).fixedSize(horizontal: true, vertical: false)`, reduce padding
- **Back button showing** in non-compact context — set `.environment(\.horizontalSizeClass, .regular)`
- **Content clipped** at bottom — increase frame height in test
- **Spacing mismatches** — check `POSPadding`/`POSSpacing` values against design
- **Wrong section order** — compare VStack children order with design

When fixing: edit the code and re-run snapshots to verify. Only commit once the snapshot matches the design goal — don't commit untested changes.

## Cleanup: Remove ALL Temporary Artifacts

After implementation is complete, revert ALL temporary changes:

```bash
# Revert Package.swift (removes snapshot dependency)
git checkout -- Modules/Package.swift

# Revert Package.resolved if it changed
git checkout -- Modules/Package.resolved

# Also revert workspace Package.resolved if changed
git checkout -- WooCommerce.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Delete the snapshot test file
rm Modules/Tests/<TestTarget>/<SnapshotTestClass>.swift

# Delete generated snapshot directory
rm -rf Modules/Tests/<TestTarget>/__Snapshots__

# Verify clean state
git status
```

**Critical**: Never commit snapshot test files, `__Snapshots__/` directories, or the `swift-snapshot-testing` dependency. These are temporary iteration tools only.

## Quick Reference

| Action | Command/Tool |
|--------|-------------|
| Add dependency | Edit `Modules/Package.swift` |
| Run snapshots | `xcodebuild test -only-testing:<Target>/<Class>` |
| Find PNGs | `Modules/Tests/<Target>/__Snapshots__/<Class>/test_name.1.png` |
| View snapshot | Read tool on the PNG path |
| Compare | Read both snapshot PNG and design reference |
| Fix + re-run | Edit code, re-run xcodebuild, commit once verified |
| Clean up | `git checkout -- Modules/Package.swift`, `rm` test file + snapshots |
