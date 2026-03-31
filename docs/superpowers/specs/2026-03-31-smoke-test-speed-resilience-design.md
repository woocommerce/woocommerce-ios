# Smoke Test: Speed & Resilience Improvements

**Date:** 2026-03-31
**Status:** Approved

## Problem

The smoke test skill has three performance and reliability issues:

1. **Fixed 5-second sleeps** waste time when the app is ready sooner (common case) and aren't long enough when it isn't (rare case).
2. **Agent stalling** — the agent pauses mid-section to think/deliberate, producing no tool calls. Hitting `esc` and saying "carry on" makes it resume immediately, proving it knows what to do.
3. **Sequential execution** — Phase 2 sections run one after another on a single simulator, taking longer than necessary when sections are independent.

## Design

### 1. Adaptive Sleep & Backoff

Replace all fixed-duration waits with a poll-then-backoff pattern.

**General rule** (added to SKILL.md): "Never use `sleep` longer than 2 seconds without checking for the expected state first. Prefer a poll loop: sleep 1–2s → check for expected element via `list_elements_on_screen` → back off if not ready."

**Specific replacements:**

| Current | New |
|---------|-----|
| "Wait 5 seconds for the app to settle" (Step 4) | Sleep 2s → check for expected screen element → back off to 3s, then 5s. Max 3 attempts. |
| "Wait 5 seconds, then retry" (Connection Drops) | Sleep 2s → retry → back off to 4s, then 8s (exponential). Max 3 attempts before escalating to user. |

### 2. Anti-Stalling

Two instruction-based changes in SKILL.md. No new hooks or watchdog processes.

**Pacing rules** (new section):
- Between steps, proceed immediately to the next tool call. Do not pause to summarize, reflect, or plan unless genuinely unsure what to do next.
- If unsure, call `list_elements_on_screen` to re-orient — do not stop to think.
- Never output more than 2 sentences of commentary between tool calls during a test section.

**Step execution guidance** (added to Step 5):
- Each checklist step may contain multiple actions. Execute all actions in a step as a single burst of tool calls without pausing between them.

### 3. Parallel Agent Teams

Phase 2 (automated) sections run in parallel across multiple simulators using subagents.

#### Topology

```
Coordinator (main agent — the skill session)
  ├── Phase 1: runs user-assisted sections sequentially
  ├── Boot simulators: iPhone A, iPhone B, iPad C
  ├── Build app once, install on all simulators
  └── Phase 2: dispatch worker subagents
       ├── Worker A (iPhone A): login, dashboard, orders
       ├── Worker B (iPhone B): products, hub-menu, other
       └── Worker C (iPad C): pos
```

#### Coordinator responsibilities

- Runs Phase 1 itself (user-assisted sections need `AskUserQuestion`)
- Boots N simulators before dispatching workers (default: 2 iPhones + 1 iPad)
- Builds the app once, installs on all simulators via `xcrun simctl install`
- Splits Phase 2 sections across workers, balancing by estimated duration
- Dispatches workers via the `Agent` tool (not worktrees — no code changes)
- Waits for all workers to return
- **Validates each worker's progress file** before accepting the result — if assigned sections are incomplete or lack screenshot evidence, sends the worker back via `SendMessage`: "Sections X, Y are still pending. Continue from where you left off."
- Merges per-worker progress files into a combined progress for report generation
- Generates the combined HTML report and opens it

#### Worker responsibilities

Each worker receives via its prompt:
- Simulator UDID and device type
- List of assigned sections (in order)
- Run folder path (`$RUN_DIR`)
- Progress file path (`$RUN_DIR/progress-<worker-name>.json`)
- Screenshot filename prefix (section name, to avoid collisions)
- All skill rules (pacing, backoff, mobile interaction, credential security)

Each worker:
- Launches the app on its assigned simulator
- Logs in using `woo-credentials` MCP (first worker runs login section, others use `--skip-login` equivalent)
- Runs assigned sections sequentially following the section lifecycle (progress.json updates, screenshots, evidence)
- Returns a result summary to the coordinator

Worker prompt includes enforcement: "You must complete ALL assigned sections. Do not return until every section in your list is completed or explicitly skipped in progress.json with a valid reason. Your progress file will be audited by the coordinator."

#### Section splitting

- **POS** always gets its own iPad worker (iPad required)
- Remaining Phase 2 sections split across N iPhone workers (default N=2)
- **`orders`** stays as a single block on one worker (internal step dependencies — creates an order that later steps reference)
- **`login`** goes on the first iPhone worker (validates the login flow; other workers skip login and reuse an existing session)
- Split remaining sections (`dashboard`, `products`, `hub-menu`, `other`) to roughly balance duration across workers

#### Progress files and hooks

- Each worker writes to `$RUN_DIR/progress-<worker-name>.json` with the same schema as `progress.json`
- The section-check hook scans for all `progress*.json` files in the run folder matching the session (workers have their own sessions, so the hook naturally scopes to the right file per agent)
- The stop hook remains on the coordinator only — checks for `report.html`
- Real enforcement for workers comes from coordinator validation of their progress files, not hooks

#### Fallback for single-simulator mode

If only one simulator is available (or `--section`/`--phase 1` is specified), skip parallel dispatch and run sequentially as today. The parallel mode is an optimization, not a requirement.

## Files Affected

| Change | Files |
|--------|-------|
| Adaptive backoff | `SKILL.md` — replace 2 hardcoded waits, add general backoff pattern |
| Anti-stalling | `SKILL.md` — add Pacing section, update Step 5 step-execution guidance |
| Parallel agents | `SKILL.md` — new parallel dispatch flow in Step 5, worker prompt template, coordinator validation logic |
| Hook update | `hooks/smoke-test-section-check.sh` — scan `progress*.json` instead of single `progress.json` |

## Out of Scope

- Checklist step rewriting for finer granularity (future improvement if stalling persists)
- Watchdog process for idle detection (reconsider if instruction-based pacing is insufficient)
- Parallel Phase 1 (user-assisted sections require sequential user interaction)
