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

## Safety

This skill creates and refunds real orders when running the `orders` or `pos` sections against a live store.

- Prefer the team smoke-test store: `inpersonpayments.wpcomstaging.com`
- If the user provides a different store, explicitly confirm they want real smoke-test mutations on that store before creating orders or refunds
- If the user does not confirm, limit execution to non-mutating sections: `login`, `dashboard`, `products`, `hub-menu`

## What This Skill Does NOT Cover

These must be tested manually:
- Watch app (separate target, paired Apple Watch required)

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

The checklist (`references/checklist.md`) defines **required** screenshot checkpoints inline with the test steps, marked with `> SCREENSHOT: <filename> — <label>`. Take each one using `save_screenshot` when you reach that step.

Create the run folder at the start and write a `run.json` marker with the session ID (used by the stop hook to verify completion):
```bash
RUN_DIR=/tmp/woo-smoke-test-$(date +%Y%m%d-%H%M%S)
mkdir -p "$RUN_DIR/screenshots"
echo "{\"session_id\": \"$SESSION_ID\", \"started\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$RUN_DIR/run.json"
```
The `$SESSION_ID` value comes from the current session context. If unavailable, use the conversation/session identifier.

### Progress tracking (progress.json)

The completion hooks use `$RUN_DIR/progress.json` to structurally verify that sections are completed in order with evidence. **You must maintain this file throughout the run.** The hooks will block task completion if progress.json shows gaps.

**Initialize** `progress.json` after creating the run folder, listing all sections that will be tested. Use the section names from the checklist, filtered by `--phase`, `--section`, and device type. Sections excluded by flags or device type should not appear at all (they aren't "skipped" — they were never in scope).

```json
{
  "expected_order": ["installation", "user-assisted-login", "user-assisted-orders", "push-notifications", "payments-hardware", "media-camera", "login", "dashboard", "orders", "products", "hub-menu", "pos", "other"],
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
- **Skipping a section**: set `"status": "skipped"` and `"skip_reason": "<reason>"`. Valid reasons: `"device-only on simulator"`, `"conditional prerequisite not met"`, `"user chose to skip"`, `"connection lost after retries"`. Do this BEFORE calling `TaskUpdate`.

**The hooks enforce this**: if you call `TaskUpdate(status=completed)` for a section task but progress.json shows no screenshots or the section is still pending, the hook will block the update.

Compact each screenshot immediately after saving:
```bash
sips -Z 1200 <file.png> --out <file.png>
```

Keep a running list of `{ file, label }` pairs as you go — these feed directly into the HTML report flipbook at the end.

You may take **additional** screenshots beyond the required checkpoints — especially for error states or unexpected behavior. Use a `FAIL-` prefix for failure triage screenshots (e.g. `FAIL-05-unexpected-error.png`).

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
- **`list_stores`** — list configured store aliases and their credential types.

**CRITICAL — credential security rules:**
- **Never call `security find-generic-password` directly** — not even as a fallback if `type_credential` fails.
- **Never read credentials via Bash** — no `security`, `cat`, `echo`, or any other command that would expose credential values.
- **Never ask the user to provide credentials** in the chat — they are already in the keychain.
- If `type_credential` fails, **ask the user to fix the MCP server connection** (restart WDA/mobile-mcp), then retry. Do not work around it by reading credentials yourself.
- After calling `type_credential`, verify the typed value by calling `list_elements_on_screen` and checking the field value.

### Stores

- `primary` — Main smoke test store. Store URL + WP.com creds + WC REST API keys.
- `apple` — Apple sign-in test store. Store URL only (auth handled by user in Apple sheet).
- `google` — Google sign-in test store. Store URL only (auth handled by user in Google sheet).
- `passwordless` — Passwordless login test store. Mailosaur-routed WP.com email only.
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

## Step 1: Check Credentials

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

Also ask:
1. **Running on device or simulator?** (determines which tests to run)
2. **Run Phase 1, Phase 2, or both?** (unless specified via `--phase`)

## Step 2: Boot Simulator / Connect Device

### Simulator
Use the `/simulator` skill approach:

```bash
# iPhone for most sections:
UDID=$(Scripts/find-simulator.sh iphone)

# iPad for POS section:
UDID=$(Scripts/find-simulator.sh ipad)
```

If running all sections including POS, start with iPhone for everything else, then switch to iPad for POS.

### Physical device
If `--device` is set, use mobile-mcp to discover connected devices:
- List available devices and confirm the target device with the user
- If no physical device appears, guide the user through `.claude/skills/smoke-test/references/device-setup.md`
- Device-only tests (installation, push notifications, card reader, TTP, camera) are enabled

## Step 3: Build the App

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=$UDID" -sdk iphonesimulator \
  build 2>&1 | tail -30
```

For physical device, adjust the destination accordingly.

If the build fails, report the error and stop. If the app is already installed from a previous build, the user may choose to skip the build step and test the installed version.

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
  2. If it fails again, tell the user the connection dropped and ask them to restart WDA / mobile-mcp. Wait for confirmation, then resume from the step that failed.
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

After Phase 1 completes, tell the user: **"Phase 1 (user-assisted tests) is complete. You can step away — Phase 2 runs fully automated."**

Record evidence as you go:
- Capture the device/simulator name and UDID used for each device class
- Keep the created order number for the `orders` section
- Save checkpoint screenshots at each `> SCREENSHOT:` directive in the checklist
- Keep a running list of observations (see `.claude/rules/mobile-interaction.md`)

## Step 6: Generate HTML Report

After all sections complete, generate a self-contained HTML report file in the run folder and open it in the browser.

The report file should be saved as `/tmp/woo-smoke-test-<timestamp>/report.html` and include:

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
open /tmp/woo-smoke-test-<timestamp>/report.html
```

### Console summary

Also print a brief text summary to the console so the user sees results without needing the browser:

```
Smoke Test: 8/11 sections passed, 2 skipped (simulator), 1 failed, 3 observations
Report: /tmp/woo-smoke-test-<timestamp>/report.html (opened in browser)
Failed: Orders (refund button not found)
Skipped: Installation (simulator), Push Notifications (simulator)
Observations: Login password entry needed 3 retries (medium), WDA timed out during orders (low), Blaze webview slow to load (low)
```
