# Agent Verification Rules

Agents can verify their changes work from a user's perspective using two complementary loops: **snapshot-driven iteration** (fast inner loop) and **simulator-based E2E verification** (slower outer loop).

## Prerequisites
- **Node.js** (see `.nvmrc` for version) — required by mobile-mcp for simulator interaction
- **Java** — required by WireMock mock server (`brew install openjdk` if missing)
- **Booted iOS simulator** — `xcrun simctl boot <UDID>`
- **mobile-mcp** — auto-configured via `.mcp.json` (project-scoped, no manual setup needed)

### Clean Simulator Setup

If mobile-mcp reports `Agent is not installed on the device` on a fresh simulator, run:

```bash
npx -y mobilecli@1.0.17 agent install --device <UDID>
```

Confirm that mobile-mcp can read the target simulator's UI elements before continuing.

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
- `screenshot` — capture current simulator screen
- `list_ui_elements` — get accessibility tree with element positions
- `tap` / `swipe` / `type_text` — interact with UI elements
- `launch_app` / `terminate_app` — manage app lifecycle
- `list_devices` — discover available simulators

## Key References

- **Screen identifiers and navigation flows**: `.claude/references/screen-identifiers.md`
- **Feature-to-path scope mapping**: `.claude/references/feature-map.json`
- **Mock server management**: `/mocks` skill
- **Simulator discovery**: `/simulator` skill
- **Launch arguments**: `WooCommerce/Classes/System/ProcessConfiguration.swift`
- **Mock API mappings**: `Modules/Sources/APIMocks/Resources/`
