# Smoke Test Speed & Resilience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the smoke test skill faster (adaptive sleeps, anti-stalling), more resilient (backoff retries), and parallelizable (agent teams for Phase 2).

**Architecture:** Three independent improvements to SKILL.md and one hook update. The parallel execution adds a coordinator/worker topology where the main agent runs Phase 1, then dispatches subagents with their own simulators for Phase 2 sections. Workers write per-worker progress files; the coordinator validates and merges results.

**Tech Stack:** Bash (hooks), Markdown (skill instructions), jq (progress file queries)

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `.claude/skills/smoke-test/SKILL.md` | Modify | Add backoff pattern, pacing rules, parallel dispatch flow |
| `.claude/skills/smoke-test/hooks/smoke-test-section-check.sh` | Modify | Support per-worker `progress-*.json` files |
| `.claude/skills/smoke-test/references/worker-prompt.md` | Create | Worker subagent prompt template |

---

### Task 1: Adaptive Sleep & Backoff

Replace hardcoded 5-second waits with poll-then-backoff patterns.

**Files:**
- Modify: `.claude/skills/smoke-test/SKILL.md:248` (app launch wait)
- Modify: `.claude/skills/smoke-test/SKILL.md:266-267` (connection retry wait)

- [ ] **Step 1: Add general backoff rule**

Insert a new section `## Pacing and Timing` after the `## What This Skill Does NOT Cover` section (after line 70) in SKILL.md:

```markdown
## Pacing and Timing

### Adaptive backoff

Never use `sleep` longer than 2 seconds without checking for the expected state afterward. Use a poll loop:

1. Sleep 1–2 seconds
2. Check for the expected element via `list_elements_on_screen`
3. If not ready, double the wait (2s → 4s → 8s), max 3 attempts
4. If still not ready after 3 attempts, treat as a failure and follow the relevant error handling (connection drops, app crash, etc.)

This applies to all waits: app launch settling, screen transitions, network responses, and connection retries.

### Execution pacing

Between test steps, proceed immediately to the next tool call. Do not pause to summarize, reflect, or plan unless genuinely unsure what to do next.

- If unsure what to do next, call `list_elements_on_screen` to re-orient — do not stop to think.
- Never output more than 2 sentences of commentary between tool calls during a test section.
- Each checklist step may contain multiple actions. Execute all actions in a step as a single burst of tool calls without pausing between them.
```

- [ ] **Step 2: Replace the app launch wait**

In SKILL.md Step 4 (line 248), replace:

```markdown
Wait 5 seconds for the app to settle.
```

with:

```markdown
Wait for the app to settle: sleep 2s, then call `list_elements_on_screen`. If the expected screen isn't showing, back off (3s, then 5s) and recheck. Max 3 attempts.
```

- [ ] **Step 3: Replace the connection retry wait**

In the Connection Drops section (line 267), replace:

```markdown
  1. Wait 5 seconds, then retry the same call once.
```

with:

```markdown
  1. Wait 2 seconds, then retry the same call. If it fails again, wait 4 seconds and retry once more.
```

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/smoke-test/SKILL.md
git commit -m "Add adaptive backoff and execution pacing rules to smoke test skill"
```

---

### Task 2: Update Hook for Parallel Progress Files

Update the section-check hook to scan all `progress*.json` files in the run folder, supporting both single-agent mode (`progress.json`) and parallel mode (`progress-worker-a.json`, etc.).

**Files:**
- Modify: `.claude/skills/smoke-test/hooks/smoke-test-section-check.sh:49-53`

- [ ] **Step 1: Replace single progress.json lookup with glob scan**

Replace the current progress file discovery (lines 49–53):

```bash
# No progress.json yet — run hasn't started test sections.
PROGRESS="$RUN_DIR/progress.json"
if [ ! -f "$PROGRESS" ]; then
  exit 0
fi
```

with a scan that finds all progress files and picks the one relevant to this agent:

```bash
# Find progress files in the run folder.
# Single-agent mode: progress.json
# Parallel mode: progress-<worker>.json (one per worker)
# The hook runs in the context of the agent that called TaskUpdate.
# In parallel mode, each worker writes its own file. We check all of them
# since we don't know which worker triggered this hook.
PROGRESS_FILES=()
for f in "$RUN_DIR"/progress*.json; do
  [ -f "$f" ] && PROGRESS_FILES+=("$f")
done

if [ ${#PROGRESS_FILES[@]} -eq 0 ]; then
  exit 0  # No progress files yet — run hasn't started test sections.
fi

# Find the progress file that has an in_progress section (that's the active worker).
# If none has in_progress, use the first file that has any sections.
PROGRESS=""
for f in "${PROGRESS_FILES[@]}"; do
  HAS_IN_PROGRESS=$(jq -r '[.sections | to_entries[] | select(.value.status == "in_progress")] | length' "$f" 2>/dev/null || echo "0")
  if [ "$HAS_IN_PROGRESS" -gt 0 ]; then
    PROGRESS="$f"
    break
  fi
done

# Fallback: use the first file with sections
if [ -z "$PROGRESS" ]; then
  for f in "${PROGRESS_FILES[@]}"; do
    HAS_SECTIONS=$(jq -r '.sections | length' "$f" 2>/dev/null || echo "0")
    if [ "$HAS_SECTIONS" -gt 0 ]; then
      PROGRESS="$f"
      break
    fi
  done
fi

if [ -z "$PROGRESS" ]; then
  exit 0  # No progress files with sections yet.
fi
```

- [ ] **Step 2: Test with single progress.json (backward compat)**

Create a test run folder with a single `progress.json` and verify the hook still works:

```bash
TEST_DIR=/tmp/woo-smoke-test-hooktest
rm -rf "$TEST_DIR" && mkdir -p "$TEST_DIR/screenshots"
echo '{"session_id": "test-session"}' > "$TEST_DIR/run.json"
cat > "$TEST_DIR/progress.json" << 'EOF'
{
  "expected_order": ["login", "dashboard"],
  "sections": {
    "login": { "status": "in_progress", "screenshots": ["01.png"] },
    "dashboard": { "status": "pending", "screenshots": [] }
  }
}
EOF

# Should pass (login has screenshots, no earlier pending)
echo '{"tool_input":{"status":"completed","taskId":"1"},"session_id":"test-session"}' \
  | .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
echo "Exit: $?"
```

Expected: no output, exit 0.

- [ ] **Step 3: Test with parallel progress files**

```bash
# Add a worker progress file alongside the main one
cat > "$TEST_DIR/progress-worker-b.json" << 'EOF'
{
  "expected_order": ["products", "hub-menu"],
  "sections": {
    "products": { "status": "in_progress", "screenshots": [] },
    "hub-menu": { "status": "pending", "screenshots": [] }
  }
}
EOF

# Should block (products has no screenshots)
echo '{"tool_input":{"status":"completed","taskId":"2"},"session_id":"test-session"}' \
  | .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
```

Expected: block with "No screenshots recorded for section 'products'".

- [ ] **Step 4: Clean up test folder and commit**

```bash
rm -rf /tmp/woo-smoke-test-hooktest
git add .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
git commit -m "Support per-worker progress files in section-check hook"
```

---

### Task 3: Create Worker Prompt Template

Create a reference file that the coordinator uses to build worker subagent prompts. Contains the full instructions a worker needs to run its assigned sections independently.

**Files:**
- Create: `.claude/skills/smoke-test/references/worker-prompt.md`

- [ ] **Step 1: Write the worker prompt template**

Create `.claude/skills/smoke-test/references/worker-prompt.md`:

```markdown
# Smoke Test Worker

You are a smoke test worker agent. You have been assigned a subset of Phase 2 test sections to run on a dedicated simulator.

## Your Assignment

- **Simulator UDID**: {{UDID}}
- **Device type**: {{DEVICE_TYPE}}
- **Assigned sections**: {{SECTIONS}}
- **Run folder**: {{RUN_DIR}}
- **Progress file**: {{RUN_DIR}}/progress-{{WORKER_NAME}}.json
- **Screenshot prefix**: Use section name as prefix (e.g. `dashboard-01-revenue.png`)

## Setup

1. The app is already installed on your simulator. Launch it:
   ```bash
   xcrun simctl launch {{UDID}} com.automattic.woocommerce disable-animations
   ```
2. Wait for app to settle: sleep 2s, check with `list_elements_on_screen`, back off if needed (max 3 attempts).
3. {{LOGIN_INSTRUCTION}}

## Rules

Follow these rules from the smoke test skill:

### Progress tracking
Initialize your progress file with your assigned sections, all set to `"pending"`. Use the same schema as the main skill's `progress.json`:

```json
{
  "expected_order": {{EXPECTED_ORDER}},
  "sections": {
    {{SECTION_ENTRIES}}
  }
}
```

For EVERY section, follow this lifecycle:
1. Update progress file: set section status to `"in_progress"`
2. Run the section's test steps from the checklist
3. Update progress file: append screenshot filenames as you take them
4. Update progress file: set section status to `"completed"` (or `"skipped"` with `skip_reason`)
5. THEN call `TaskUpdate` to mark the section's task complete

### Pacing
- Proceed immediately to the next tool call between steps. Do not pause to summarize or reflect.
- If unsure, call `list_elements_on_screen` to re-orient.
- Never output more than 2 sentences between tool calls.
- Execute all actions in a checklist step as a single burst.

### Adaptive backoff
Never sleep longer than 2 seconds without checking for expected state. Poll loop: sleep 1–2s → check → double wait if not ready → max 3 attempts.

### Screenshots
- Save to `{{RUN_DIR}}/screenshots/` with section-name prefix
- Compact immediately: `sips -Z 1200 <file.png> --out <file.png>`
- Use `save_screenshot`, never `take_screenshot`

### Mobile interaction
- `list_elements_on_screen` is the primary feedback tool, not screenshots
- Always call `list_elements_on_screen` before tapping — coordinates change between screens
- Retry taps with varied coordinates (up to 3 times) before considering a failure
- See `.claude/rules/mobile-interaction.md` for full details

### Credentials
- Use `woo-credentials` MCP tools for credential entry — never read keychain directly
- See the main skill's credential security rules

### Connection drops
- Wait 2s, retry. If still failing, wait 4s, retry once more.
- If connection cannot be restored, mark the current section as "not tested (connection lost)" and move to the next.

## Completion

You MUST complete ALL assigned sections. Do not return until every section in your list is completed or explicitly skipped in your progress file with a valid reason.

Valid skip reasons: `"device-only on simulator"`, `"conditional prerequisite not met"`, `"connection lost after retries"`.

Invalid reasons: time efficiency, difficulty, prior section failure (unless app crashed).

Your progress file will be audited by the coordinator. If sections are missing evidence, you will be sent back to complete them.

## Checklist Reference

The test steps for each section are in `.claude/skills/smoke-test/references/checklist.md`. Read the section(s) assigned to you and follow the steps exactly.

## Return Format

When all assigned sections are complete, return a brief summary:

```
Worker: {{WORKER_NAME}}
Sections: N completed, M skipped
Observations: [list any observations]
```
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/smoke-test/references/worker-prompt.md
git commit -m "Add worker prompt template for parallel smoke test execution"
```

---

### Task 4: Add Parallel Dispatch Flow to SKILL.md

Update SKILL.md to add the parallel agent team dispatch logic for Phase 2. This modifies Step 2 (simulator boot), Step 3 (build/install), and Step 5 (section execution).

**Files:**
- Modify: `.claude/skills/smoke-test/SKILL.md:203-216` (Step 2)
- Modify: `.claude/skills/smoke-test/SKILL.md:224-234` (Step 3)
- Modify: `.claude/skills/smoke-test/SKILL.md:275-303` (Step 5)

- [ ] **Step 1: Update Step 2 to boot multiple simulators**

Replace the Step 2 Simulator subsection (lines 205–216):

```markdown
### Simulator
Use the `/simulator` skill approach:

\```bash
# iPhone for most sections:
UDID=$(Scripts/find-simulator.sh iphone)

# iPad for POS section:
UDID=$(Scripts/find-simulator.sh ipad)
\```

If running all sections including POS, start with iPhone for everything else, then switch to iPad for POS.
```

with:

```markdown
### Simulator

**Single-simulator mode** (when `--section` is specified or only one simulator available):
\```bash
UDID=$(Scripts/find-simulator.sh iphone)
# For POS section only:
UDID=$(Scripts/find-simulator.sh ipad)
\```

**Parallel mode** (default for full Phase 2 runs on simulator):
Boot multiple simulators for parallel Phase 2 execution. The coordinator uses the first iPhone for Phase 1, then dispatches workers across all simulators for Phase 2.

\```bash
# Boot 2 iPhones + 1 iPad
IPHONE_A=$(Scripts/find-simulator.sh iphone)
IPHONE_B=$(Scripts/find-simulator.sh iphone --second)
IPAD=$(Scripts/find-simulator.sh ipad)
\```

If the second iPhone simulator is not available (only one iPhone model installed), fall back to 1 iPhone + 1 iPad (2 workers instead of 3). If only one simulator is available total, fall back to single-simulator sequential mode.
```

- [ ] **Step 2: Update Step 3 to install on all simulators**

After the existing build command in Step 3 (line 229), add:

```markdown
In parallel mode, install the built app on all simulators after building:
\```bash
xcrun simctl install $IPHONE_A com.automattic.woocommerce
xcrun simctl install $IPHONE_B com.automattic.woocommerce
xcrun simctl install $IPAD com.automattic.woocommerce
\```

The build only needs to happen once — `simctl install` copies the built product to each simulator.
```

- [ ] **Step 3: Update Step 5 with parallel dispatch flow**

After the existing Step 5 execution rules and section lifecycle (after line 303), add a new subsection:

```markdown
### Parallel Phase 2 execution

When running in parallel mode (multiple simulators booted, not `--section` or `--phase 1`):

**After Phase 1 completes**, tell the user: "Phase 1 (user-assisted tests) is complete. You can step away — Phase 2 runs fully automated across multiple simulators."

**Section assignment:**
- **Worker A** (iPhone A): `login`, `dashboard`, `orders` — gets login because it validates the login flow
- **Worker B** (iPhone B): `products`, `hub-menu`, `other` — skips login, reuses existing session
- **Worker C** (iPad): `pos` — iPad required for POS

If only 2 simulators are available (1 iPhone + 1 iPad), merge Worker A and B assignments onto the single iPhone.

**Dispatching workers:**
1. Read the worker prompt template from `.claude/skills/smoke-test/references/worker-prompt.md`
2. For each worker, fill in the template placeholders: `{{UDID}}`, `{{DEVICE_TYPE}}`, `{{WORKER_NAME}}`, `{{SECTIONS}}`, `{{RUN_DIR}}`, `{{EXPECTED_ORDER}}`, `{{SECTION_ENTRIES}}`, `{{LOGIN_INSTRUCTION}}`
3. Set `{{LOGIN_INSTRUCTION}}` to the full login flow for Worker A, and to "The app should already be logged in from the build/install step. Verify the dashboard is visible. If not, perform the login flow." for other workers.
4. Dispatch all workers simultaneously using the `Agent` tool. Each worker runs as a subagent (not a worktree).

**Coordinator validation:**
When each worker returns:
1. Read its progress file (`$RUN_DIR/progress-<worker>.json`)
2. Verify every assigned section is `"completed"` or `"skipped"` (with a valid `skip_reason`)
3. Verify every completed section has at least one screenshot
4. If any section is incomplete or missing evidence, send the worker back via `SendMessage`: "Sections X, Y are still pending/missing evidence. Continue from where you left off."
5. Accept the worker's result only after validation passes

**Merging results:**
After all workers complete and pass validation:
1. Read all `progress-*.json` files from the run folder
2. Merge into a combined section map for report generation
3. Generate the HTML report as normal (Step 6), covering all sections from all workers
```

- [ ] **Step 4: Update progress.json docs for parallel mode**

In the "Progress tracking (progress.json)" section (around line 84), add a note after the existing content:

```markdown
**Parallel mode:** In parallel execution, each worker writes to `$RUN_DIR/progress-<worker-name>.json` instead of `progress.json`. The schema is identical. The coordinator merges these files when generating the report. The completion hook automatically scans all `progress*.json` files in the run folder.
```

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/smoke-test/SKILL.md
git commit -m "Add parallel agent team dispatch flow for Phase 2 smoke tests"
```

---

### Task 5: Update allowed-tools and Arguments

The skill frontmatter and arguments section needs updating for the new parallel capabilities.

**Files:**
- Modify: `.claude/skills/smoke-test/SKILL.md:5-6` (frontmatter)
- Modify: `.claude/skills/smoke-test/SKILL.md:34-39` (arguments)

- [ ] **Step 1: Add SendMessage to allowed-tools**

The coordinator needs `SendMessage` to send workers back if validation fails. In the frontmatter (line 5), update:

```yaml
allowed-tools: "Bash, Read, Grep, Glob, Agent, SendMessage, AskUserQuestion, mcp__mobile-mcp__*, mcp__woo-credentials__*"
```

- [ ] **Step 2: Add --parallel and --workers arguments**

In the Arguments section (after line 39), add:

```markdown
- `--parallel` — Force parallel Phase 2 execution even if only 2 simulators are available. Default: auto (parallel if 2+ simulators, sequential otherwise).
- `--sequential` — Force sequential execution on a single simulator, even if multiple are available.
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/smoke-test/SKILL.md
git commit -m "Add SendMessage to allowed-tools and parallel execution arguments"
```

---

### Task 6: Verify find-simulator.sh supports multiple simulators

The parallel mode assumes `Scripts/find-simulator.sh iphone --second` can return a second iPhone simulator. Check if this works and fix if needed.

**Files:**
- Read: `Scripts/find-simulator.sh`

- [ ] **Step 1: Read find-simulator.sh and check for multi-device support**

```bash
cat Scripts/find-simulator.sh
```

Check whether the script supports a `--second` flag or similar mechanism to return a different simulator UDID for the same device type.

- [ ] **Step 2: If --second is not supported, add it**

If the script only returns the first matching simulator, add support for an optional second argument or `--second` flag that skips the first match and returns the next one. The implementation depends on the script's current structure — read it first.

If the script doesn't exist or uses a completely different approach, update the SKILL.md parallel mode instructions to use `xcrun simctl list devices available` directly to find two iPhone simulators.

- [ ] **Step 3: Test that two different UDIDs are returned**

```bash
UDID_A=$(Scripts/find-simulator.sh iphone)
UDID_B=$(Scripts/find-simulator.sh iphone --second)
echo "A: $UDID_A"
echo "B: $UDID_B"
[ "$UDID_A" != "$UDID_B" ] && echo "OK: different UDIDs" || echo "FAIL: same UDID"
```

- [ ] **Step 4: Commit if changes were made**

```bash
git add Scripts/find-simulator.sh
git commit -m "Support --second flag in find-simulator.sh for parallel smoke tests"
```

---

### Task 7: End-to-End Hook Test

Verify the full hook chain works in both single and parallel modes after all changes.

**Files:**
- Test only (no files modified)

- [ ] **Step 1: Test single-agent mode (backward compat)**

```bash
TEST_DIR=/tmp/woo-smoke-test-hooktest
rm -rf "$TEST_DIR" && mkdir -p "$TEST_DIR/screenshots"
echo '{"session_id": "test-session"}' > "$TEST_DIR/run.json"
cat > "$TEST_DIR/progress.json" << 'EOF'
{
  "expected_order": ["login", "dashboard", "orders"],
  "sections": {
    "login": { "status": "completed", "screenshots": ["01.png"] },
    "dashboard": { "status": "in_progress", "screenshots": ["02.png"] },
    "orders": { "status": "pending", "screenshots": [] }
  }
}
EOF

# Should pass
echo '{"tool_input":{"status":"completed","taskId":"1"},"session_id":"test-session"}' \
  | .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
echo "Single-agent pass: exit $?"
```

Expected: no output, exit 0.

- [ ] **Step 2: Test parallel mode — worker with evidence**

```bash
cat > "$TEST_DIR/progress-worker-b.json" << 'EOF'
{
  "expected_order": ["products", "hub-menu"],
  "sections": {
    "products": { "status": "in_progress", "screenshots": ["products-01.png"] },
    "hub-menu": { "status": "pending", "screenshots": [] }
  }
}
EOF

# Should pass (products has screenshots, hub-menu is after products)
echo '{"tool_input":{"status":"completed","taskId":"2"},"session_id":"test-session"}' \
  | .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
echo "Parallel pass: exit $?"
```

Expected: no output, exit 0.

- [ ] **Step 3: Test parallel mode — worker without evidence**

```bash
cat > "$TEST_DIR/progress-worker-c.json" << 'EOF'
{
  "expected_order": ["pos"],
  "sections": {
    "pos": { "status": "in_progress", "screenshots": [] }
  }
}
EOF

# Should block (pos has no screenshots)
echo '{"tool_input":{"status":"completed","taskId":"3"},"session_id":"test-session"}' \
  | .claude/skills/smoke-test/hooks/smoke-test-section-check.sh
echo "Parallel block: exit $?"
```

Expected: block with "No screenshots recorded for section 'pos'".

- [ ] **Step 4: Clean up**

```bash
rm -rf /tmp/woo-smoke-test-hooktest
```

No commit needed — test-only task.
