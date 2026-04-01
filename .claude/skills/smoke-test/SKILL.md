---
name: smoke-test
description: Run manual smoke tests on a real WooCommerce store via iOS simulator and mobile-mcp. Use when verifying app quality before a release, after major changes, or when asked to smoke test.
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob, Agent, AskUserQuestion, mcp__mobile-mcp__*, mcp__woo-credentials__*"
argument-hint: "[--skip-login] [--section <name>] [--phase <1|2>] [--device]"
hooks:
  PostToolUse:
    - matcher: "TaskUpdate"
      hooks:
        - type: command
          command: ".claude/skills/smoke-test/hooks/smoke-test-section-check.sh"
          timeout: 10
  Stop:
    - matcher: ""
      hooks:
        - type: command
          command: ".claude/skills/smoke-test/hooks/smoke-test-stop-check.sh"
          timeout: 10
---

# Smoke Test

Run the WooCommerce iOS smoke test flows against a real store, using mobile-mcp to navigate the UI and verify behavior. Works on both simulator and physical device.

Based on the team's manual smoke testing checklist (https://woomobilep2.wordpress.com/flows-for-app-features-smoke-testing/). Covers: installation, login (including error states, passwordless, social, 2FA), dashboard, orders (including create, pay, refund, shipping labels), products (including create, variations, media upload), hub menu (all items), POS, push notifications, payments (card reader, TTP), locale, widgets, and quick actions.

Read these before starting:
- `.claude/references/screen-identifiers.md` for accessibility identifiers and navigation flows
- `.claude/skills/smoke-test/references/checklist.md` for the section-by-section smoke test checklist

Mobile-mcp interaction patterns (tap strategy, text entry, screenshots, triage) are defined in `.claude/rules/mobile-interaction.md` and are always loaded. Follow them throughout the run.

## Arguments

- `--skip-login` — Skip login, reuse existing session on the device/simulator
- `--section <name>` — Run only one section. Valid names: `installation`, `user-assisted-login`, `user-assisted-orders`, `push-notifications`, `payments-hardware`, `media-camera`, `login`, `dashboard`, `orders`, `products`, `hub-menu`, `pos`, `other`
- `--phase <1|2>` — Run only Phase 1 (user-assisted) or Phase 2 (automated)
- `--device` — Target a physical device instead of a simulator. Enables device-only tests (installation, push notifications, card reader, TTP, camera).
- `--parallel` — Force parallel Phase 2 execution even if only 2 simulators are available. Default: auto (parallel if 2+ simulators, sequential otherwise).
- `--sequential` — Force sequential execution on a single simulator, even if multiple are available.

## Test Phases

The checklist is split into two phases:

- **Phase 1 — User-assisted**: Tests requiring user interaction (auth sheets, hardware, barcodes, push notifications). Run first while the user is present. After completing Phase 1, tell the user they can step away.
- **Phase 2 — Fully automated**: Tests the agent runs independently without user input.

When running all tests, execute Phase 1 first, then Phase 2. The `--phase` argument lets the user run only one phase.

## Interaction Types

Steps in the checklist are marked with labels:

- **(auto)** — Fully automated, no user input needed.
- **(user-assisted)** — Agent drives UI but pauses for user input via `AskUserQuestion`.
- **(device-only)** — Requires a physical device. Skip on simulator, mark as "not tested (simulator)".
- **(conditional)** — Only run if a prerequisite is met. Skip gracefully if not available.

## System Sheets and Uncontrollable UI

Some screens are presented by the system, not the app, and cannot be inspected or interacted with via mobile-mcp. These include:
- **Sign in with Apple** (SIWA) sheets
- **Tap to Pay** proximity card prompts and Apple ID terms
- **Google sign-in** web views
- **Save Password** system prompts
- **Biometric/Face ID** prompts

When you reach a step that triggers one of these and `list_elements_on_screen` returns an empty or unrecognizable element list, **do not try to read a screenshot to figure out what's on screen**. Instead:
1. Assume the system UI has appeared as expected
2. Ask the user via `AskUserQuestion` to complete the interaction
3. After the user confirms, call `list_elements_on_screen` to verify the app has returned to a state you can interact with

## Credential Security

- **Never tap a "Show password" button** on any login screen. Passwords must remain redacted at all times — in the UI, in screenshots, and in element listings.
- Never read credentials via Bash — no `security`, `cat`, `echo`, or any command that would expose values.
- Never ask the user to provide credentials in the chat — they are already in the keychain.

## Safety

This skill creates and refunds real orders when running the `orders` or `pos` sections against a live store.

- Prefer the team smoke-test store: `inpersonpayments.wpcomstaging.com`
- If the user provides a different store, explicitly confirm they want real smoke-test mutations on that store before creating orders or refunds
- If the user does not confirm, limit execution to non-mutating sections: `login`, `dashboard`, `products`, `hub-menu`

## What This Skill Does NOT Cover

These must be tested manually:
- Watch app (separate target, paired Apple Watch required)

## Tool Usage

- **Write files** (progress.json, report.html) with the **Write tool**, not Bash heredocs.
- **Never chain Bash commands with `&&`** — it triggers permission prompts. Use separate Bash calls for each command, or use `;` if you must combine them.
- **Read files** with the Read tool, not `cat`.
- **Search** with Grep/Glob, not `grep`/`find`.

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

## Screenshots

**Take screenshots liberally.** The goal is a visual record of every step as it happened, not just success states. Take a screenshot:
- At every `> SCREENSHOT:` checkpoint in the checklist (required)
- Before and after every significant action (tap, navigation, form fill, scroll)
- When an expected screen loads
- When anything unexpected happens (double-take with a `FAIL-` prefix)

The checklist defines **required** screenshot checkpoints marked with `> SCREENSHOT: <filename> — <label>`. These are the minimum. Take additional screenshots between them to capture the journey. Name additional screenshots sequentially within the section (e.g. `login-01-prologue.png`, `login-02-site-url-entered.png`, `login-03-email-screen.png`).

Create the run folder at the start and write a `run.json` marker with the session ID (used by the stop hook to verify completion). Use a location inside the project directory to avoid sandbox permission issues:
```bash
RUN_DIR="$(pwd)/.smoke-test-runs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR/screenshots"
echo "{\"session_id\": \"$SESSION_ID\", \"started\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$RUN_DIR/run.json"
```
The `$SESSION_ID` value comes from the current session context. If unavailable, use the conversation/session identifier.

The `.smoke-test-runs/` directory is gitignored. Run folders persist across sessions for reference but can be cleaned up manually.

### Progress tracking (progress.json)

The completion hooks use `$RUN_DIR/progress.json` to structurally verify that sections are completed in order with evidence. **You must maintain this file throughout the run.** The hooks will block task completion if progress.json shows gaps.

**Initialize** `progress.json` after creating the run folder, listing all sections that will be tested. Use the section names from the checklist, filtered by `--phase`, `--section`, and device type. Sections excluded by flags or device type should not appear at all (they aren't "skipped" — they were never in scope).

```json
{
  "expected_order": ["user-assisted-login", "user-assisted-orders", "payments-hardware", "media-camera", "installation", "push-notifications", "login", "dashboard", "orders", "products", "hub-menu", "pos", "other"],
  "sections": {
    "login": { "status": "pending", "screenshots": [] },
    "dashboard": { "status": "pending", "screenshots": [] },
    "orders": { "status": "pending", "screenshots": [] }
  }
}
```

`expected_order` is the full canonical ordering (used by hooks to detect out-of-order completion). `sections` contains only the sections in scope for this run.

**Section lifecycle** — update progress.json at each transition:
- **Starting a section**: set `"status": "in_progress"` and `"started_at": "<ISO timestamp>"`
- **Taking a screenshot**: append the filename to the section's `"screenshots"` array
- **Completing a section**: set `"status": "completed"` and `"completed_at": "<ISO timestamp>"`. Do this BEFORE calling `TaskUpdate` to mark the task complete.
- **Skipping a section**: set `"status": "skipped"` and `"skip_reason": "<reason>"`. Do this BEFORE calling `TaskUpdate`. Valid skip reasons are **exhaustive** — if your reason isn't on this list, it's not valid:
  - `"device-only on simulator"` — section is marked `(device-only)` and you're on simulator
  - `"user chose to skip"` — user explicitly said to skip via `AskUserQuestion`
  - `"connection lost after retries"` — WDA/mobile-mcp connection failed after retry protocol

  **These are NOT valid skip reasons** (complete the section instead):
  - Time constraints, time efficiency, or running long
  - Difficulty or complexity
  - "Requires iPad rebuild" — boot an iPad simulator and build for it
  - "Already tested on another device" — each device class gets its own test
  - Prior section failure (unless the app crashed and won't relaunch)
  - "Conditional prerequisite not met" for things you can set up (JN sites, locale changes, widgets)
  - Any justification you invented that isn't in the valid list above

**Always use the Write tool** (not Bash with heredoc/cat) to update progress.json. Bash commands with heredocs and `&&` chaining trigger permission prompts. The Write tool writes the file directly without shell interpretation.

**The hooks enforce this**: if you call `TaskUpdate(status=completed)` for a section task but progress.json shows no screenshots or the section is still pending, the hook will block the update.

**Parallel mode:** In parallel execution, each worker writes to `$RUN_DIR/progress-<worker-name>.json` instead of `progress.json`. The schema is identical. The coordinator merges these files when generating the report. The completion hook automatically scans all `progress*.json` files in the run folder.

Compact each screenshot immediately after saving:
```bash
sips -Z 1200 <file.png> --out <file.png>
```

Keep a running list of `{ file, label }` pairs as you go — these feed directly into the HTML report flipbook at the end.

Use a `FAIL-` prefix for failure triage screenshots (e.g. `FAIL-05-unexpected-error.png`).

## Credentials

Credentials are stored in the macOS Keychain and accessed via a local MCP server (`woo-credentials`). **The agent never sees credential values** — not even at runtime. The MCP server reads from keychain and types into device fields or makes API calls on the agent's behalf.

**First-time setup:** Run the setup script once per machine:
```bash
.claude/skills/smoke-test/scripts/setup-keychain.sh
```

The script prompts for each credential and stores it securely. For details on where to find each credential, see the credential setup wiki: `P91TBi-dNC-p2`

**Checking stored entries:**
```bash
.claude/skills/smoke-test/scripts/setup-keychain.sh --check
```

### Credentials MCP Server

The `woo-credentials` MCP server (configured in `.mcp.json`) provides these tools:

- **`check_credentials`** — check which keychain entries exist for a store. Returns missing entry names.
- **`type_credential`** — type a keychain value into the focused field on a device. Returns only `{ status: "typed" }`.
- **`create_order`** — create a WooCommerce order using keychain API credentials. Returns only order ID/status.
- **`list_products`** — list published products from a store using keychain API credentials. Returns product IDs, names, types, and prices. Use this to get a real product ID for `create_order`.
- **`list_stores`** — list configured store aliases and their credential types.

**CRITICAL — credential security rules:**
- **Never call `security find-generic-password` directly** — not even as a fallback if `type_credential` fails.
- **Never read credentials via Bash** — no `security`, `cat`, `echo`, or any other command that would expose credential values.
- **Never ask the user to provide credentials** in the chat — they are already in the keychain.
- If `type_credential` fails, **ask the user to fix the MCP server connection** (restart WDA/mobile-mcp), then retry. Do not work around it by reading credentials yourself.
- After calling `type_credential`, verify the typed value by calling `list_elements_on_screen` and checking the field value.

### Stores

- `primary` — Main smoke test store. Store URL + WP.com creds + WordPress application password (for REST API).
- `apple` — Apple sign-in test store. Store URL only (auth handled by user in Apple sheet).
- `google` — Google sign-in test store. Store URL only (auth handled by user in Google sheet).
- `passwordless` — Passwordless login test store. Mailosaur-routed WP.com email only.
- `twofactor` — 2FA login test. Store URL + WP.com creds (account has 2FA enabled). The user provides the TOTP code via `AskUserQuestion`.
- `not-woo` — Not-a-WooCommerce store error test. WP.com creds only.
- `wrong-account` — Wrong-account error test. WP.com creds only.
- `mailosaur` — Mailosaur API key for magic link retrieval.

## Jurassic Ninja Site Creation

For tests that need a throwaway WooCommerce site (no-Jetpack, Jetpack-disconnected), the skill can create one automatically:

1. If Playwright is available (`npx playwright --version`), run:
   ```bash
   node .claude/skills/smoke-test/scripts/create-jn-site.js
   ```
   This launches a browser, creates the site, and outputs credentials as JSON. WordPress.com login may be required on first use.

2. If Playwright is not available, open the JN create URL in the user's browser and ask them to paste the resulting site URL and credentials.

Credentials from JN sites are ephemeral (sites self-destruct after 7 days) and can be used directly by the agent without keychain storage.

## Step 1: Check Prerequisites and Credentials

### Parallel mode prerequisites

If running a full test (not `--section` or `--sequential`), check that parallel execution dependencies are available:

```bash
command -v tmux   # needed for visible worker terminals
command -v claude # needed for worker sessions
```

If either is missing, **offer to install** before falling back:

- **tmux missing**: Ask the user: "tmux is needed for parallel mode (visible worker terminals). Install it now with `brew install tmux`?" If they agree, run `brew install tmux`. If they decline or it fails, fall back to sequential.
- **claude CLI missing**: Tell the user: "The `claude` CLI is needed for parallel worker sessions. Install from https://claude.ai/claude-code" — this can't be auto-installed, so fall back to sequential if unavailable.

Only fall back to sequential mode after offering installation and being declined or hitting a failure.

### Credentials

At startup, use the `woo-credentials` MCP server to check that the required keychain entries exist:

```
woo-credentials: check_credentials({ store: "primary" })
→ { status: "ok", missing: [] }
```

If any entries are missing:
1. Tell the user which entries are missing
2. Show the wiki page link (`P91TBi-dNC-p2`) for credential details
3. Offer to run the setup script: `.claude/skills/smoke-test/scripts/setup-keychain.sh --store <alias>`
4. Re-check via `check_credentials` after setup

**To type credentials into device fields**, use `type_credential`:
```
woo-credentials: type_credential({ account: "primary.wpcom-email" })
→ { status: "typed" }
```

Then verify via `list_elements_on_screen` that the field value updated. **Never use `security find-generic-password` directly.**

Also ask (unless already specified via arguments):
1. **Which devices are available?** Options: simulator only, physical device only, or both. When both are available, use the physical device for device-only sections (installation, push notifications, payments, camera) and simulators for everything else. This is the recommended setup for maximum coverage.
2. **Run Phase 1, Phase 2, or both?** (unless specified via `--phase`)
3. **Test across multiple iOS versions?** List the installed simulator runtimes:
   ```bash
   xcrun simctl list runtimes available
   ```
   If multiple iOS versions are installed, offer to run Phase 2 across all of them for broader coverage. Each iOS version gets its own set of workers (e.g. 2 iPhones + 1 iPad per version). This multiplies the worker count but catches version-specific regressions.

   If the user opts in, boot simulators for each iOS version and add them to the worker pool. Workers are tagged by iOS version in their progress file (`progress-worker-a-ios18.json`) and the report groups results by version.

## Step 2: Boot Simulator / Connect Device

### Simulator

**Single-simulator mode** (when `--section` is specified or only one simulator available):
```bash
UDID=$(Scripts/find-simulator.sh iphone)
# For POS section only:
UDID=$(Scripts/find-simulator.sh ipad)
```

**Parallel mode** (default for full Phase 2 runs on simulator):
Boot multiple simulators for parallel Phase 2 execution. **Do not rely on already-booted simulators** — boot all the ones you need.

**Single iOS version** (default):
```bash
# List available simulators (not just booted ones)
xcrun simctl list devices available | grep -E "iPhone|iPad"

# Pick two different iPhone models and one iPad from the available list
# Boot each one explicitly
xcrun simctl boot <IPHONE_A_UDID>
xcrun simctl boot <IPHONE_B_UDID>
xcrun simctl boot <IPAD_UDID>
```

Use `find-simulator.sh` to get the first iPhone and iPad, then find a second iPhone model from the available list:
```bash
IPHONE_A=$(Scripts/find-simulator.sh iphone)
IPAD=$(Scripts/find-simulator.sh ipad)

# Find a second iPhone — different model from IPHONE_A
IPHONE_B=$(xcrun simctl list devices available | grep "iPhone" | grep -v "$(xcrun simctl list devices | grep "$IPHONE_A" | sed 's/ (.*//' | xargs)" | head -1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
if [ -n "$IPHONE_B" ]; then
  xcrun simctl boot "$IPHONE_B" 2>/dev/null || true  # may already be booted
fi
```

**Multi-iOS-version** (when user opted in at Step 1):
Boot a set of simulators for each iOS version. Each version gets its own workers running the same test sections — this catches version-specific regressions.

```bash
# List available runtimes
xcrun simctl list runtimes available
# e.g. iOS 17.5, iOS 18.0, iOS 18.4

# For each runtime, find an iPhone and iPad device, boot them
# The simctl output groups devices by runtime — pick from each group
xcrun simctl list devices available
```

For each iOS version, boot 1 iPhone + 1 iPad (or 2 iPhones + 1 iPad if models are available). Name workers by version: `worker-a-ios17`, `worker-b-ios18`, etc. Each worker's progress file is tagged: `progress-worker-a-ios17.json`.

The section assignment is the same per version — each version's workers run the full Phase 2 section set independently. The report groups results by iOS version, showing pass/fail per section per version.

If only one iPhone model is available per version, fall back to 1 iPhone + 1 iPad (2 workers per version). If only one simulator is available total, fall back to sequential mode.

### Physical device
If `--device` is set:

1. Start the device tunnel and port forwarding:
   ```bash
   # Detect device
   DEVICE_UDID=$(ios list 2>/dev/null | grep -oE '[0-9a-f]{40}' | head -1)

   # Start go-ios tunnel (required for iOS 17+). Run in background.
   ios tunnel start --userspace &
   TUNNEL_PID=$!
   sleep 3  # Wait for tunnel to establish

   # Forward WDA port from device to localhost
   ios forward 8100 8100 --udid=$DEVICE_UDID &
   FORWARD_PID=$!
   ```
   If the tunnel fails with a permission error, tell the user to run `sudo ios tunnel start` manually.

2. Verify WDA is reachable: `curl -sf http://localhost:8100/status`
3. Use mobile-mcp to discover connected devices — list available devices and confirm the target device with the user
4. If no physical device appears, guide the user through `.claude/skills/smoke-test/references/device-setup.md`
5. Device-only tests (installation, push notifications, card reader, TTP, camera) are enabled

**If the tunnel drops during the run**, check and restart:
```bash
# Check if processes are still alive
kill -0 $TUNNEL_PID 2>/dev/null || echo "Tunnel died"
kill -0 $FORWARD_PID 2>/dev/null || echo "Forward died"
curl -sf http://localhost:8100/status || echo "WDA unreachable"

# Restart if needed
ios tunnel start --userspace &
TUNNEL_PID=$!
sleep 3
ios forward 8100 8100 --udid=$DEVICE_UDID &
FORWARD_PID=$!
```

**When done with the physical device**, stop the tunnel and port forwarding:
```bash
kill $FORWARD_PID 2>/dev/null
kill $TUNNEL_PID 2>/dev/null
```

## Step 3: Build the App

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=$UDID" -sdk iphonesimulator \
  build 2>&1 | tail -30
```

For physical device, adjust the destination accordingly.

If the build fails, report the error and stop. If the app is already installed from a previous build, the user may choose to skip the build step and test the installed version.

In parallel mode, install the built app on all simulators after building:
```bash
xcrun simctl install $IPHONE_A com.automattic.woocommerce
xcrun simctl install $IPHONE_B com.automattic.woocommerce
xcrun simctl install $IPAD com.automattic.woocommerce
```

The build only needs to happen once — `simctl install` copies the built product to each simulator.

## Step 4: Launch and Login

Unless `--skip-login` is set, always test the login flow from a logged-out state. If the app is already logged in:
1. Navigate to Hub Menu (`tab-bar-menu-item`) → Settings (`dashboard-settings-button`)
2. Scroll to the bottom and tap `settings-log-out-button`
3. Confirm logout

Then launch the app:
```bash
xcrun simctl launch $UDID com.automattic.woocommerce disable-animations
```

Wait for the app to settle: sleep 2s, then call `list_elements_on_screen`. If the expected screen isn't showing, back off (3s, then 5s) and recheck. Max 3 attempts.

**Login flow** (from `screen-identifiers.md`):
1. Tap `Prologue Self Hosted Button`
2. Enter store URL in `Site address` field, tap `Site Address Next Button`
3. Enter email, tap continue
4. Enter password, tap continue
5. If 2FA screen appears, enter `123456`, tap `Continue Button`
6. Tap `login-epilogue-continue-button`
7. Verify dashboard loads (`revenue-value` visible)

## Connection Drops and WDA Instability

mobile-mcp / WDA connections occasionally drop during a run. This is normal and not a reason to skip tests.

**Rules:**
- **Never skip a section preemptively** because of a prior connection drop. A drop in section A does not predict a drop in section B.
- **Never batch-skip remaining sections** after a connection issue. Each section gets its own chance.
- When a mobile-mcp tool call fails with a connection/timeout error:
  1. Wait 2 seconds, then retry the same call. If it fails again, wait 4 seconds and retry once more.
  2. If on a physical device, check if the tunnel and forward are still alive (`kill -0 $TUNNEL_PID`, `curl -sf http://localhost:8100/status`). If either died, restart them and retry.
  3. If it still fails, tell the user the connection dropped and ask them to restart WDA / mobile-mcp. Wait for confirmation, then resume from the step that failed.
  3. If the user restarts successfully, **continue the run from where you left off** — do not restart the current section from the beginning unless you lost app state (e.g. the app crashed or returned to the home screen).
- If the user cannot restore the connection after two attempts, mark only the **current section** as "not tested (connection lost)" and move on to the next section. The next section starts with a fresh connection check.
- Record every connection drop as a low-concern observation. If the same section requires 3+ retries, escalate to medium concern.

**The goal is maximum coverage.** A smoke test that skips sections due to hypothetical instability is worse than one that hits a real drop mid-section and recovers.

## Step 5: Run Test Sections

Run the selected sections from `.claude/skills/smoke-test/references/checklist.md`.

Execution rules:
- If `--phase` is specified, run only sections from that phase
- If `--section` is specified, run only that section
- Otherwise run Phase 1 first (user-assisted), then Phase 2 (automated)
- Within each phase, run sections in the order they appear in the checklist
- Continue after a section failure when the app is still usable, and mark that section failed in the report
- Stop only for blockers such as build failure, launch failure, inability to log in, or a crash that prevents further testing
- On simulator, skip all `(device-only)` sections and mark them as "not tested (simulator)"

**Section lifecycle** — for EVERY section, follow this sequence:
1. Update `progress.json`: set section status to `"in_progress"`
2. Run the section's test steps from the checklist
3. Update `progress.json`: append screenshot filenames as you take them
4. Update `progress.json`: set section status to `"completed"` (or `"skipped"` with `skip_reason`)
5. THEN call `TaskUpdate` to mark the section's task complete

The completion hook reads `progress.json` and will block `TaskUpdate` if evidence is missing. You cannot mark a section complete without screenshots, and you cannot skip ahead past pending sections without explicitly marking them skipped with a valid reason.

In parallel mode, tell the user: **"Phase 2 workers are running in the background on separate simulators. Let's do Phase 1 together — once we're done, I'll check on the workers."**

In sequential mode, after Phase 1 completes, tell the user: **"Phase 1 (user-assisted tests) is complete. You can step away — Phase 2 runs fully automated."**

Record evidence as you go:
- Capture the device/simulator name and UDID used for each device class
- Keep the created order number for the `orders` section
- Save checkpoint screenshots at each `> SCREENSHOT:` directive in the checklist
- Keep a running list of observations (see `.claude/rules/mobile-interaction.md`)

### Parallel Phase 2 execution

When running in parallel mode (multiple simulators booted, not `--section` or `--phase 1`):

**Dispatch Phase 2 workers BEFORE starting Phase 1.** Phase 2 sections are fully automated and don't depend on Phase 1. By dispatching workers immediately after build/install, they run in the background while the coordinator handles Phase 1 with the user. This significantly reduces total run time.

**Prerequisites** (checked in Step 1): tmux and claude CLI must be available. If not, the run falls back to sequential mode automatically.

**Execution order:**
1. Build app, install on all simulators (Step 3)
2. Set up tmux session and dispatch workers (see below)
3. Run Phase 1 (user-assisted) in the current terminal
4. After Phase 1, monitor worker progress files until all workers finish
5. Validate all worker results, generate report

**Section assignment:**
- **Worker A** (iPhone A): `login`, `dashboard`, `orders` — gets login because it validates the login flow. Each worker logs in independently on its own simulator.
- **Worker B** (iPhone B): `products`, `hub-menu`, `other` — logs in using stored credentials, then runs its sections.
- **Worker C** (iPad): `pos` — iPad required for POS

If only 2 simulators are available (1 iPhone + 1 iPad), merge Worker A and B assignments onto the single iPhone.

**Setting up the tmux session:**

Each worker runs as a separate `claude` CLI session in its own tmux pane, so the user can watch all workers in real time.

1. Read the worker prompt template from `.claude/skills/smoke-test/references/worker-prompt.md`
2. For each worker, fill in the template placeholders: `{{UDID}}`, `{{DEVICE_TYPE}}`, `{{WORKER_NAME}}`, `{{SECTIONS}}`, `{{RUN_DIR}}`, `{{EXPECTED_ORDER}}`, `{{SECTION_ENTRIES}}`, `{{LOGIN_INSTRUCTION}}`
3. Set `{{LOGIN_INSTRUCTION}}` to the full login flow for all workers (each logs in independently on its own simulator).
4. Write each worker's filled prompt to `$RUN_DIR/worker-<name>-prompt.txt`
5. Create a tmux session and launch workers:

```bash
# Create the tmux session for smoke test workers
tmux new-session -d -s smoke-test-workers -n worker-a

# Worker A in first pane
tmux send-keys -t smoke-test-workers:worker-a \
  "cd $(pwd) && claude -p \"$(cat $RUN_DIR/worker-a-prompt.txt)\" --allowedTools 'Bash,Read,Grep,Glob,mcp__mobile-mcp__*,mcp__woo-credentials__*'" Enter

# Worker B in second pane
tmux new-window -t smoke-test-workers -n worker-b
tmux send-keys -t smoke-test-workers:worker-b \
  "cd $(pwd) && claude -p \"$(cat $RUN_DIR/worker-b-prompt.txt)\" --allowedTools 'Bash,Read,Grep,Glob,mcp__mobile-mcp__*,mcp__woo-credentials__*'" Enter

# Worker C (iPad) in third pane
tmux new-window -t smoke-test-workers -n worker-c
tmux send-keys -t smoke-test-workers:worker-c \
  "cd $(pwd) && claude -p \"$(cat $RUN_DIR/worker-c-prompt.txt)\" --allowedTools 'Bash,Read,Grep,Glob,mcp__mobile-mcp__*,mcp__woo-credentials__*'" Enter
```

6. Open the tmux session so the user can watch workers. Ask the user: "Want me to open the worker terminals so you can watch them?" If they agree (or don't decline), open them:
   ```bash
   # Prefer iTerm2 if available, fall back to Terminal.app
   if [ -d "/Applications/iTerm.app" ]; then
     osascript <<'APPLESCRIPT'
   tell application "iTerm"
     activate
     tell current window
       tell current session
         split vertically with default profile command "tmux attach -t smoke-test-workers"
       end tell
     end tell
   end tell
   APPLESCRIPT
   else
     osascript <<'APPLESCRIPT'
   tell application "Terminal"
     activate
     do script "tmux attach -t smoke-test-workers"
   end tell
   APPLESCRIPT
   fi
   ```

   If the user is unfamiliar with tmux, briefly explain: **"Switch between workers with `Ctrl-b n`/`Ctrl-b p`, or `Ctrl-b w` for the window list. `Ctrl-b d` detaches back to your terminal."**
7. Immediately proceed to Phase 1 in the current terminal — do not wait for workers.

**Monitoring workers:**

After Phase 1 completes, poll worker progress files until all are done:

```bash
# Check if all workers have finished (no "pending" or "in_progress" sections remain)
for f in $RUN_DIR/progress-worker-*.json; do
  REMAINING=$(jq '[.sections | to_entries[] | select(.value.status == "pending" or .value.status == "in_progress")] | length' "$f" 2>/dev/null)
  if [ "$REMAINING" -gt 0 ]; then
    echo "$(basename $f): $REMAINING sections remaining"
  fi
done
```

Poll every 30 seconds until all workers report zero remaining sections. Also check if the tmux panes are still alive — if a worker's pane has exited, read its progress file to determine whether it completed or crashed.

**Coordinator validation:**

After all workers finish:
1. Read each worker's progress file (`$RUN_DIR/progress-<worker>.json`)
2. Verify every assigned section is `"completed"` or `"skipped"` (with a valid `skip_reason`)
3. Verify every completed section has at least one screenshot
4. If any section is incomplete or missing evidence, launch a new `claude -p` session in the tmux to finish the remaining sections
5. Clean up: `tmux kill-session -t smoke-test-workers`

**Merging results:**

After all workers complete and pass validation:
1. Read all `progress-*.json` files from the run folder
2. Merge into a combined section map for report generation
3. Generate the HTML report as normal (Step 6), covering all sections from all workers

## Step 6: Generate HTML Report

After all sections complete, generate a self-contained HTML report file in the run folder and open it in the browser.

**Use the Write tool** to create the report file — do not use Bash with heredoc or `&&` chaining (triggers permission prompts). Similarly, use individual Bash calls for any file operations like copying screenshots — never chain commands with `&&`.

The report file should be saved as `$RUN_DIR/report.html` and include:

1. **Summary table** — section name, PASS/FAIL/SKIPPED badge, and notes for each section tested. Clicking a section name scrolls to that section's detail. Group sections by phase.
2. **Section details** — one collapsible section per test, each containing:
   - PASS/FAIL/SKIPPED badge and section title
   - A screenshot flipbook for that section's screenshots only (Previous/Next buttons, arrow keys navigate within the section's flipbook)
   - Any observations from that section, shown inline below the flipbook. Each observation shows the step, description, concern level (color-coded: grey for low, amber for medium, red for high), and any `FAIL-` screenshot.
3. **Observations summary** — a collected list of all observations across all sections, for quick scanning. Each entry links back to the relevant section. Only include this if there are observations to report.
4. **Not tested** — list of skipped items (device-only on simulator, conditional steps that didn't apply, manual-only items)

### HTML report structure

Generate a single HTML file with inline CSS and JS (no external dependencies). Key features:

- Screenshots referenced via relative paths (e.g. `screenshots/01-prologue.png`) so the report works from the run folder
- PASS sections get a green badge, FAIL sections get a red badge, SKIPPED sections get a grey badge
- Each section has its own independent flipbook — arrow keys and buttons navigate within the currently visible/focused flipbook only
- Sections are collapsible (expanded by default for FAIL sections, collapsed for PASS sections)
- Responsive layout that works at reasonable browser widths
- Dark header with the Woo purple (`#7F54B3`) as accent color

After writing the file, open it:
```bash
open $RUN_DIR/report.html
```

### Console summary

Also print a brief text summary to the console so the user sees results without needing the browser:

```
Smoke Test: 8/11 sections passed, 2 skipped (simulator), 1 failed, 3 observations
Report: $RUN_DIR/report.html (opened in browser)
Failed: Orders (refund button not found)
Skipped: Installation (simulator), Push Notifications (simulator)
Observations: Login password entry needed 3 retries (medium), WDA timed out during orders (low), Blaze webview slow to load (low)
```
