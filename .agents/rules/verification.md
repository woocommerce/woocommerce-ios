# Agent Verification Rules

Agents can verify their changes work from a user's perspective using two complementary loops: **snapshot-driven iteration** (fast inner loop) and **simulator-based E2E verification** (slower outer loop).

## Local output paths

Run agent commands from the task's checkout root. For direct `xcodebuild` commands, pass
`-derivedDataPath "$PWD/DerivedData"` to builds, tests, and matching `-showBuildSettings` queries.
Fastlane already selects this checkout-local build folder. Reuse compatible output; use a fresh
child such as `DerivedData/strict-before/` when a diagnostic requires a clean configuration.
Keep one build writer per output folder and separate output folders between worktrees.

Save agent-created console logs, screenshots, traces, and test results in a unique directory
under `.agent-artifacts/`, which is gitignored. Keep evidence until the task's retention requirements
are met. Existing tool-owned paths, including `fastlane/logs`, `fastlane/test_output`, and package
`.build` folders, remain valid.
For Fastlane's local `test` lane, set `SCAN_BUILDLOG_PATH` for that invocation to keep its raw log local.
For SnapshotTesting comparisons, prefix `xcodebuild` with
`TEST_RUNNER_SNAPSHOT_ARTIFACTS="$TASK_ARTIFACTS/mismatch"` to keep failure images local too;
`snapshotDirectory` selects reference images, not comparison failure artifacts.

Explicit task/CI output paths and specialized helper contracts take precedence over these defaults.
Credential staging follows `/auto-login` and stays outside the repository. Shared package/compiler
caches and simulator devices remain system-managed. These defaults require no personal skill,
Xcode preference change, cleanup service, or fixed simulator provider.

## Prerequisites
- **Node.js** (see `.nvmrc` for version) — required by mobile-mcp for simulator interaction
- **Java** — required by WireMock mock server (`brew install openjdk` if missing)
- **Booted iOS simulator** — `xcrun simctl boot <UDID>`
- **mobile-mcp** — auto-configured via `.mcp.json` (project-scoped, no manual setup needed)

### Clean Simulator Setup

A timeout or connection error does not prove that the device helper is missing.
Check daemon health and client/server versions through installed CLI help or exposed MCP schemas;
report unavailable diagnostics. Then retry a read-only device query.
Install the device helper only after a missing-helper response is confirmed.
If the device helper is missing, check the installed mobilecli version and its `agent install --help`.
If the CLI is absent, use `npx -y mobilecli@<matching-version> agent install --help` after verifying
compatibility with the running daemon. If its version is unknown, report that gap before installation.
Use the version compatible with the running daemon and the device option shown by that CLI.
Preserve a daemon used by other tasks; report a version conflict instead of restarting it.

Capture `xcrun simctl io <UDID> screenshot <task-image-path>` and compare it with the MCP
screenshot. Confirm the device, app foreground, and screen before tapping. Refresh elements after typing.
If the MCP result shows another device, stop interaction and report the mismatch.

### Simulator app dependencies

Use the app and runtime frameworks from the same successful build. If launch reports a
missing framework, inspect that build's products and `PackageFrameworks` directory.
Pass their paths as `SIMCTL_CHILD_DYLD_FRAMEWORK_PATH` on each launch when needed.
An installed app bundle alone may be insufficient. If matching products are unavailable,
build again instead of combining artifacts from different builds.
Keep the framework environment on relaunch while removing login-only variables.

## `/verify` — E2E Simulator Verification

Builds the app, launches on the simulator, and uses mobile-mcp to navigate the UI and verify features work. Auto-detects which features changed via `git diff` and the feature map.

```bash
/verify              # auto-detect scope from git diff
```

**Environment selection**: `/verify` reuses a suitable session, otherwise defaults to WireMock unless a live store is requested or required. Follow `.agents/skills/auto-login/SKILL.md` with `mocks` for WireMock or its default live-store flow.

**Feature map**: `.agents/references/feature-map.json` maps file path patterns to feature areas (orders, products, POS, dashboard, etc.) with navigation instructions and expected elements. To add a new feature, add an entry with `pathPatterns`, `tab`, and `verifyElements`.

## `/snapshot` — Snapshot-Driven UI Iteration

Uses `swift-snapshot-testing` to render SwiftUI views to PNG images. The agent reads the PNG, compares against design goals, makes changes, and repeats.

```bash
/snapshot            # start snapshot iteration for current view work
```

**How it works**: Reuse existing coverage or add temporary setup -> render each requested state -> inspect new images against the design -> fix and repeat. Follow `/snapshot` for capture diagnostics and selective cleanup.

Remove only temporary setup introduced by the snapshot task. Preserve existing dependencies, tests,
and baselines; keep reviewed captures in the task artifact directory for its required retention period.

## mobile-mcp Tools

Configured via `.mcp.json` at the project root. Provides:
Read the connected server's tool schemas for device discovery, UI elements, screenshots,
interaction, and app lifecycle. Tool names vary by server version.

## Key References

- **Screen identifiers and navigation flows**: `.agents/references/screen-identifiers.md`
- **Feature-to-path scope mapping**: `.agents/references/feature-map.json`
- **Mock server management**: `/mocks` skill
- **Simulator discovery**: `/simulator` skill
- **Launch arguments**: `WooCommerce/Classes/System/ProcessConfiguration.swift`
- **Mock API mappings**: `Modules/Sources/APIMocks/Resources/`
