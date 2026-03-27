---
name: smoke-test
description: Run manual smoke tests on a real WooCommerce store via iOS simulator and mobile-mcp. Use when verifying app quality before a release, after major changes, or when asked to smoke test.
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob, Agent, AskUserQuestion, mcp__mobile-mcp__*"
argument-hint: "[--skip-login] [--section <name>]"
---

# Smoke Test

Run the WooCommerce iOS smoke test flows against a real store on the iOS simulator, using mobile-mcp to navigate the UI and verify behavior.

Based on the team's manual smoke testing checklist. Covers: login (including error states), dashboard, orders (including create, pay via cash, and refund), products, hub menu, and POS.

Read these before starting:
- `.claude/references/screen-identifiers.md` for accessibility identifiers and navigation flows
- `.claude/skills/smoke-test/references/checklist.md` for the section-by-section smoke test checklist

Mobile-mcp interaction patterns (tap strategy, text entry, screenshots, triage) are defined in `.claude/rules/mobile-interaction.md` and are always loaded. Follow them throughout the run.

## Arguments

- `--skip-login` — Skip login, reuse existing session on the simulator
- `--section <name>` — Run only one section. Valid names: `login`, `dashboard`, `orders`, `products`, `hub-menu`, `pos`

## Safety

This skill creates and refunds real orders when running the `orders` or `pos` sections against a live store.

- Prefer the team smoke-test store: `inpersonpayments.wpcomstaging.com`
- If the user provides a different store, explicitly confirm they want real smoke-test mutations on that store before creating orders or refunds
- If the user does not confirm, limit execution to non-mutating sections: `login`, `dashboard`, `products`, `hub-menu`

## What This Skill Does NOT Cover

These require hardware, external auth, or out-of-app interaction and must be tested manually:
- Card reader / Tap to Pay (physical hardware)
- Push notifications (APNs)
- Barcode scanning (camera)
- Watch app (separate target)
- Social login — Apple/Google (system auth sheets)
- 2FA login (authenticator app)
- Passwordless login (email inbox)
- Widgets / Quick Actions (home screen)
- Blaze campaign creation (real payment)
- Locale / language changes

## Screenshots

The checklist (`references/checklist.md`) defines **required** screenshot checkpoints inline with the test steps, marked with `> SCREENSHOT: <filename> — <label>`. Take each one using `save_screenshot` when you reach that step.

Create the run folder at the start:
```bash
mkdir -p /tmp/woo-smoke-test-<timestamp>/screenshots
```

Compact each screenshot immediately after saving:
```bash
sips -Z 1200 <file.png> --out <file.png>
```

Keep a running list of `{ file, label }` pairs as you go — these feed directly into the HTML report flipbook at the end.

You may take **additional** screenshots beyond the required checkpoints — especially for error states or unexpected behavior. Use a `FAIL-` prefix for failure triage screenshots (e.g. `FAIL-05-unexpected-error.png`).

## Step 1: Get Credentials

Unless `--skip-login` is set, ask the user for:
1. **Store URL** (e.g. `https://inpersonpayments.wpcomstaging.com/`)
2. **Username/email**
3. **Password**

Suggest the test store from the smoke test doc: `inpersonpayments.wpcomstaging.com` with username `appstestadmin`. Credentials are in the Automattic secret store (https://mc.a8c.com/secret-store/?secret_id=8326).

## Step 2: Boot Simulator

Use the `/simulator` skill approach:

```bash
# iPhone for most sections:
UDID=$(Scripts/find-simulator.sh iphone)

# iPad for POS section:
UDID=$(Scripts/find-simulator.sh ipad)
```

If running all sections including POS, start with iPhone for everything else, then switch to iPad for POS.

## Step 3: Build the App

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=$UDID" -sdk iphonesimulator \
  build 2>&1 | tail -30
```

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

Wait 5 seconds for the app to settle.

**Login flow** (from `screen-identifiers.md`):
1. Tap `Prologue Self Hosted Button`
2. Enter store URL in `Site address` field, tap `Site Address Next Button`
3. Enter email, tap continue
4. Enter password, tap continue
5. If 2FA screen appears, enter `123456`, tap `Continue Button`
6. Tap `login-epilogue-continue-button`
7. Verify dashboard loads (`revenue-value` visible)

## Step 5: Run Test Sections

Run the selected sections from `.claude/skills/smoke-test/references/checklist.md`.

Execution rules:
- If `--section` is specified, run only that section
- Otherwise run sections in this order: `login`, `dashboard`, `orders`, `products`, `hub-menu`, `pos`
- Continue after a section failure when the app is still usable, and mark that section failed in the report
- Stop only for blockers such as build failure, launch failure, inability to log in, or a crash that prevents further testing

Record evidence as you go:
- Capture the simulator name and UDID used for each device class
- Keep the created order number for the `orders` section
- Save checkpoint screenshots at each `> SCREENSHOT:` directive in the checklist
- Keep a running list of observations (see `.claude/rules/mobile-interaction.md`)

## Step 6: Generate HTML Report

After all sections complete, generate a self-contained HTML report file in the run folder and open it in the browser.

The report file should be saved as `/tmp/woo-smoke-test-<timestamp>/report.html` and include:

1. **Summary table** — section name, PASS/FAIL badge, and notes for each section tested. Clicking a section name scrolls to that section's detail.
2. **Section details** — one collapsible section per test (Login, Dashboard, Orders, Products, Hub Menu, POS), each containing:
   - PASS/FAIL badge and section title
   - A screenshot flipbook for that section's screenshots only (Previous/Next buttons, arrow keys navigate within the section's flipbook)
   - Any observations from that section, shown inline below the flipbook. Each observation shows the step, description, concern level (color-coded: grey for low, amber for medium, red for high), and any `FAIL-` screenshot.
3. **Observations summary** — a collected list of all observations across all sections, for quick scanning. Each entry links back to the relevant section. Only include this if there are observations to report.
4. **Not tested** — list of manual-only items

### HTML report structure

Generate a single HTML file with inline CSS and JS (no external dependencies). Key features:

- Screenshots referenced via relative paths (e.g. `screenshots/01-prologue.png`) so the report works from the run folder
- PASS sections get a green badge, FAIL sections get a red badge
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
Smoke Test: 5/7 sections passed, 2 observations
Report: /tmp/woo-smoke-test-<timestamp>/report.html (opened in browser)
Failed: Orders (refund button not found), POS (crash on checkout)
Observations: Login password entry needed 3 retries (medium), WDA timed out during orders (low)
```
