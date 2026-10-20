---
name: snapshot
description: Render SwiftUI view snapshots for design comparison and visual iteration. Use for layout, styling, or state variants; use verify for navigation and live app behavior.
user-invocable: true
allowed-tools: "Bash, Read, Write, Edit, Grep, Glob"
argument-hint: "[view-name or test-target]"
---

# Render View Snapshots

Use swift-snapshot-testing to create a visual feedback loop when implementing UI changes. Render SwiftUI views to PNG after each code change, compare against design goals, fix mismatches, and repeat.

## When to Use
- Implementing UI from Figma designs or reference screenshots
- Multi-step view redesigns where each step should match a target
- Any SwiftUI work where you need to visually verify output
- When design reference images are available for comparison

## When NOT to Use
- Logic-only changes with no visual impact
- For an already-covered view, extend its existing snapshot tests instead of adding a parallel fixture

## Core Flow
```
1. SETUP      Reuse existing snapshot coverage and dependencies; add temporary setup if needed
2. GOAL       Collect design reference images
3. SCAFFOLD   Create snapshot test rendering the target view
4. LOOP       For each implementation step:
                a. Edit code
                b. Run snapshot test (record mode)
                c. Read generated PNG
                d. Compare against design
                e. If mismatch -> fix and re-snapshot
                f. If match -> retain evidence and proceed to the next state
5. CLEANUP    Remove only task-owned temporary setup; retain reviewed evidence
```

## Setup: Add Dependency

Check existing tests, `Modules/Package.swift`, and the resolved dependency version first. Reuse
compatible setup. If absent, add a toolchain-compatible release temporarily to the owning test target.

**In the `dependencies` array of `Modules/Package.swift`:**
```swift
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.6"),
```

**In the relevant test target's `dependencies` array:**
```swift
.product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
```

Select the test target that can import the view: for example, `PointOfSaleTests` for POS or
`WooCommerceTests` for app-target views. Confirm its dependencies in the package or project.

**Remember the original state** of `Modules/Package.swift` so you can revert exactly after cleanup.

## Goal: Collect References

Choose a task artifact directory. If the user provides design reference images, copy them there:
```bash
mkdir -p "$HOME/Downloads/snapshot_experiment"
TASK_ARTIFACTS="$(mktemp -d "$HOME/Downloads/snapshot_experiment/snapshot.XXXXXX")"
cp /path/to/design.png "$TASK_ARTIFACTS/design.png"
```
Use this directory's absolute path for `<task-artifacts>` below, including in later shell calls.
Read each reference image to understand the target state before writing code.

If no reference image, the goal is inferred from the user's description of desired UI behavior.

## Scaffold: Create Snapshot Test

Create a test file in the appropriate `Modules/Tests/*Tests/` directory:

```swift
import Testing
import SnapshotTesting
import SwiftUI
@testable import TargetModule

@MainActor
struct ViewNameSnapshotTests {
    @Test
    func test_default_state_snapshot() {
        // Given: use the required viewport and representative dependencies.
        let view = YourView(/* props for default state */)
        // When: choose a fresh directory for each iteration.
        let diagnostic = verifySnapshot(
            of: view, as: .image(layout: .fixed(width: 390, height: 844)),
            record: .all, snapshotDirectory: "<task-artifacts>/iteration-1"
        )
        // Then: preserve the library's recording or failure diagnostic.
        if let diagnostic { Issue.record("\(diagnostic)") }
    }
}
```

**Important details for this project:**
- Use the resolved library's public API. `verifySnapshot` accepts `snapshotDirectory`; `assertSnapshot` does not.
- Match the requested device viewport, size class, theme, text size, and view state. The dimensions above are illustrative.
- Add fixtures for required alternate states. Increasing image height does not prove the content fits on the device.
- Record mode writes images and reports a diagnostic. It is capture evidence, not a passing regression comparison.
- Follow the owning view's design system and repository styling rules. Use `/verify` for navigation, live data, and hardware flows.

## Run: Execute Snapshot Tests

Use the `/simulator` skill approach to discover a booted simulator UDID.

Run only the snapshot tests for fast feedback. Select the module scheme when it owns the fixture;
use `WooCommerce` for app-target views:
```bash
set -o pipefail
xcodebuild test \
  -workspace WooCommerce.xcworkspace \
  -scheme '<scheme>' \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -only-testing:<TestTarget>/<SnapshotTestClass> \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee '<task-artifacts>/snapshot.log'
```

**Prefer module-level test targets** when they own the view and its dependencies.

Check the pipeline exit status and full log. Record mode can fail after writing a PNG;
confirm that the expected new image exists and inspect it. Other failures require diagnosis.
Use the new iteration directory and image paths reported by the library. An older PNG is not evidence
of the current render. Keep one log per iteration and report unrelated build or test failures.

## Compare: Read and Assess

After each run:
1. Read the generated PNG using the Read tool
2. If a design reference exists, read it side by side
3. Identify specific mismatches: layout, spacing, missing elements, text wrapping, colors
4. Copy PNGs to working directory with step labels for history:
```bash
cp '<reported-PNG-path>' '<task-artifacts>/step1.png'
```

## Fix: Iterate on Mismatches

Common issues caught by snapshots:
- **Text wrapping** — compare long and localized text at the required widths before changing layout
- **Navigation controls** — render the intended size class and navigation context
- **Content clipped** — verify scrolling and safe areas at the real viewport
- **Spacing mismatches** — check the owning design tokens against the reference
- **Wrong section order** — compare VStack children order with design

When fixing: edit the code and re-run snapshots to verify. Complete the loop when each requested state has a new, inspected image. Report the states reviewed and remaining runtime gaps.

## Cleanup: Remove Temporary Setup

Restore only dependency and lockfile edits introduced by this task, and remove only its temporary
fixture and generated source-tree images. Preserve pre-existing edits, tests, dependencies, and
snapshot baselines. Keep reviewed captures in the task artifact directory for the required retention
period. Inspect `git diff` and `git status` before committing; task artifacts stay out of commits.

## Quick Reference

| Action | Command/Tool |
|--------|-------------|
| Add dependency | Edit `Modules/Package.swift` |
| Run snapshots | `xcodebuild test -only-testing:<Target>/<Class>` |
| Find PNGs | Paths reported by the library under the selected iteration directory |
| View snapshot | Read tool on the PNG path |
| Compare | Read both snapshot PNG and design reference |
| Fix + re-run | Edit code, re-run xcodebuild, commit once verified |
| Clean up | Restore only task-owned setup; retain reviewed evidence |
