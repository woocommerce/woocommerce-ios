# Agent Verification Rules

Agents can verify their changes work from a user's perspective using two complementary loops: **snapshot-driven iteration** (fast inner loop) and **simulator-based E2E verification** (slower outer loop).

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

**Environment selection**: `/verify` reuses a suitable session, otherwise defaults to WireMock unless a live store is requested or required. Follow `.claude/skills/auto-login/SKILL.md` with `mocks` for WireMock or its default live-store flow.

**Feature map**: `.claude/references/feature-map.json` maps file path patterns to feature areas (orders, products, POS, dashboard, etc.) with navigation instructions and expected elements. To add a new feature, add an entry with `pathPatterns`, `tab`, and `verifyElements`.

## `/snapshot` — Snapshot-Driven UI Iteration

Uses `swift-snapshot-testing` to render SwiftUI views to PNG images. The agent reads the PNG, compares against design goals, makes changes, and repeats. ~25s per iteration cycle when scoped to a module.

```bash
/snapshot            # start snapshot iteration for current view work
```

**How it works**: Temporarily add `swift-snapshot-testing` to `Modules/Package.swift` -> create a snapshot test -> iterate (edit code -> run test -> read PNG -> compare -> fix) -> revert all temporary artifacts.

**Important**: The snapshot dependency, test files, and `__Snapshots__/` directories are always temporary and must never be committed.

## mobile-mcp Tools

Configured via `.mcp.json` at the project root. Provides:
Read the connected server's tool schemas for device discovery, UI elements, screenshots,
interaction, and app lifecycle. Tool names vary by server version.

## Key References

- **Screen identifiers and navigation flows**: `.claude/references/screen-identifiers.md`
- **Feature-to-path scope mapping**: `.claude/references/feature-map.json`
- **Mock server management**: `/mocks` skill
- **Simulator discovery**: `/simulator` skill
- **Launch arguments**: `WooCommerce/Classes/System/ProcessConfiguration.swift`
- **Mock API mappings**: `Modules/Sources/APIMocks/Resources/`
