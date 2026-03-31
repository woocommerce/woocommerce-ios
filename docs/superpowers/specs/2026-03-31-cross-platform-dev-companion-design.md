# Cross-Platform Dev Companion

**Date**: 2026-03-31
**Author**: Josh Heald (with Claude)
**Project**: AI Enablement Week 2

## Summary

Two composable Claude Code skills that integrate simulator/emulator interaction into the development loop and enable cross-platform feature implementation:

1. **`/iterate`** — Dev companion that brings mobile-mcp-driven simulator interaction into everyday development, both as an agent self-verification loop during coding and as an interactive exploration tool for developers.
2. **`/crossdev`** — Cross-platform feature skill that implements changes across iOS and Android in parallel, using each repo's conventions and verifying via `/iterate` where possible.

## Motivation

The WooCommerce mobile team has invested in mobile-mcp infrastructure for smoke testing and E2E verification, but this capability is locked behind purpose-built skills (`/smoke-test`, `/verify`). Meanwhile, developers frequently need to check their UI changes visually during development — currently requiring manual simulator interaction outside the editor.

The team also maintains two platform codebases (iOS and Android) that often need parallel feature work. Developers typically know one platform deeply but need agent assistance for the other. There's an opportunity to make "implement this on both platforms" a single operation.

## Skill 1: `/iterate`

### Purpose

Make simulator/emulator interaction a seamless part of the development loop. Two modes:

- **Agent-driven**: During implementation of UI changes, the agent automatically builds, launches, navigates to the affected screen, checks the result, and adjusts. This is an inner loop the agent uses while coding — no explicit invocation needed.
- **Interactive**: The developer invokes `/iterate` to explore the running app conversationally. The agent detects what's being worked on, builds, launches to the relevant screen, and responds to directions.

### How It Works

#### Scope Detection

Same approach as `/verify`: run `git diff --name-only` and match changed files against the feature map (`feature-map.json`). Each feature entry maps file path patterns to a tab, navigation steps, and expected elements.

If no features match, ask the developer which screen to navigate to.

#### Interactive Mode Flow

1. Developer invokes `/iterate`
2. Skill detects scope from git diff (or asks)
3. Build the app (using the repo's build command from AGENTS.md)
4. Launch on booted simulator/emulator
5. Navigate to the relevant screen using the feature map and screen identifiers
6. Report what's on screen via `list_elements_on_screen`
7. Wait for developer directions — they can ask the agent to tap, swipe, navigate, describe what it sees, or check specific elements
8. Loop until the developer is done

#### Agent-Driven Mode

When the agent is implementing UI changes (not explicitly invoked as `/iterate`), it should incorporate simulator verification into its coding loop:

1. Make code changes
2. Build
3. Launch and navigate to the affected screen
4. Check via `list_elements_on_screen` — does the screen show the expected state?
5. If not, adjust code and repeat
6. If yes, continue to the next change

This isn't a separate skill invocation — it's guidance in the skill that teaches the agent to treat "check the simulator" as a natural step, similar to how it runs tests. The `/iterate` skill content includes instructions for both modes.

#### Verification Strategy

- Primary feedback: `list_elements_on_screen` (fast, structured, no token cost)
- Screenshots: only via `save_screenshot` for developer review or failure triage, never `take_screenshot`
- Follows all existing mobile-mcp interaction rules (`.claude/rules/mobile-interaction.md`)

### Not Platform-Specific

The skill itself contains no iOS or Android-specific logic. It relies on:
- The repo's AGENTS.md for build commands
- The repo's feature map for scope detection and navigation
- mobile-mcp for simulator/emulator interaction (already supports both platforms)

This means it works in the Android repo too, as long as that repo has a feature map and AGENTS.md with build commands.

### Relationship to Existing Skills

- **`/verify`**: One-shot verification at the end of a change. `/iterate` is continuous and interactive. `/verify` could eventually delegate to `/iterate` for its navigation+checking logic, but that's not in scope for this week.
- **`/smoke-test`**: Follows a fixed checklist against a real store. `/iterate` is open-ended and developer-directed.
- **`/snapshot`**: Renders SwiftUI views to PNG without building the full app. `/iterate` builds and runs the full app. They're complementary — `/snapshot` for fast inner loop on a single view, `/iterate` for full-app verification.

### Prerequisites

- Booted simulator (iOS) or emulator (Android)
- mobile-mcp configured (already done via `.mcp.json` for iOS)
- Feature map in the repo (already exists for iOS at `.claude/references/feature-map.json`)

## Skill 2: `/crossdev`

### Purpose

Implement a feature or change across both iOS and Android from a single platform-neutral description. The developer describes what they want, and the agent handles both platforms in parallel.

### How It Works

#### Input

The developer provides:
- A description of the change in platform-neutral terms (e.g., "Add a 'Mark as Gift' toggle to the order creation screen")
- Optionally: a Linear ticket ID or P2 URL for additional context (fetched via ContextA8C)

#### Analysis Phase

1. Read both repos' AGENTS.md to understand architecture, patterns, and conventions
2. For each repo, identify which files need to change and what the implementation approach looks like
3. Present a plan for both platforms to the developer for approval before proceeding

#### Execution Phase

1. Spawn two parallel agents — one per platform — each working in their respective repo
2. Each agent follows its repo's AGENTS.md conventions
3. Each agent builds and runs tests
4. Each agent uses `/iterate` for visual verification where mobile-mcp works
5. If mobile-mcp doesn't work on one platform (e.g., Android emulator issues), that agent falls back to build + test only

#### Output

- Two branches, one per repo, each with idiomatic implementations
- Summary of what was done on each platform
- Note of any divergences (e.g., "Android doesn't have an equivalent screen for X")
- Ready for PRs (but does not create them automatically — the developer reviews first)

### Key Design Decisions

**Intent-driven, not port-driven**: The agent doesn't translate iOS code to Android or vice versa. It implements the same *intent* on each platform using that platform's idioms. An iOS SwiftUI view and an Android Compose screen will look completely different in code but achieve the same user-facing result.

**Parallel, not sequential**: Both platforms are implemented simultaneously by separate agents. This is faster and prevents one platform's implementation from biasing the other.

**Developer approval gate**: The agent presents its plan for both platforms before writing any code. The developer can adjust scope, exclude one platform, or redirect.

**Graceful degradation on Android verification**: If mobile-mcp has issues with the Android emulator, the agent doesn't spend time debugging it. It falls back to compile + test verification and notes that visual verification was skipped.

### Prerequisites

- Both repos cloned locally
- Both repos have AGENTS.md with build commands, architecture overview, and conventions
- Android repo has a feature map (nice-to-have, not required — agent can ask for navigation guidance)
- Both simulators/emulators available (visual verification is optional on Android)

### Configuration

The skill needs to know where both repos live. Options:
- Convention-based: expect sibling directories (`../woocommerce-ios`, `../woocommerce-android`)
- Explicit: developer provides paths on first use, stored in a config or memory

Start with convention-based and fall back to asking.

## Milestones

### Milestone 1 (Days 1-2): `/iterate` on iOS

- Skill file with both modes (agent-driven and interactive)
- Scope detection from git diff + feature map
- Build, launch, navigate, element listing loop
- Interactive direction-following
- Test by using it during real POS development work

**Success**: Working on a POS view, invoke `/iterate`, agent shows current state and responds to directions. Agent also self-verifies during its own coding loop.

### Milestone 2 (Days 3-4): `/crossdev`

- Skill file with analysis + parallel execution flow
- Reads both repos' AGENTS.md
- Spawns parallel agents per platform
- iOS agent uses `/iterate` for verification
- Android agent uses `/iterate` if mobile-mcp works, build + test if not

**Success**: Describe a change, both platforms get idiomatic implementations that build and pass tests.

### Milestone 3 (Day 5): Polish and stretch goals

- Refine based on what worked and what didn't during days 1-4
- Possible: Android mobile-mcp tuning (time-boxed)
- Possible: ContextA8C integration for pulling Linear ticket descriptions as `/crossdev` input
- Possible: Cross-platform visual comparison (side-by-side screenshots)
- Documentation and cleanup for team adoption

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Android mobile-mcp flaky | Medium | Fall back to build + test. Don't sink time fixing it. |
| Feature map missing in Android repo | Low | Agent asks for navigation guidance instead. Can bootstrap a feature map as stretch goal. |
| Parallel agent coordination issues | Medium | Keep agents independent — they don't communicate. Coordination happens before (planning) and after (summary). |
| Build times slow down the iteration loop | Medium | Use incremental builds. For `/iterate`, only rebuild when code changes. |
| Agent makes bad cross-platform decisions | Medium | Developer approval gate before any code is written. Plan review catches misunderstandings early. |

## Out of Scope

- Automated PR creation (developer reviews and creates PRs manually)
- Backend/API changes (focus is on mobile client code)
- Porting existing features retroactively (designed for new work)
- Perfecting Android mobile-mcp (use what works, move on)
- Modifying `/verify` or `/smoke-test` to use `/iterate` internally (future work)
