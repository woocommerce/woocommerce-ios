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

## Known mobile-mcp Quirks

- **Tap coordinates can be slightly off.** If a tap does not register on the exact coordinates reported by `list_elements_on_screen`, retry with a small offset from the reported center.
- **UIMenu buttons** such as `performance-time-range-menu` often need a slight right/down offset.
- **Navigation bar buttons** such as search or `+` often need a tap roughly 15px below the reported y coordinate because of safe area insets.

## Tap and Text Entry Strategy

### Retry with variance
When a tap does not produce the expected result, do NOT retry at the same coordinates. Instead, use a tight loop:

1. **Tap** at the element coordinates reported by `list_elements_on_screen`
2. **Immediately call `list_elements_on_screen`** to check whether the screen state changed
3. If unchanged, **vary the tap position**: try the center of the element's bounding rect (`x + width/2`, `y + height/2`), then offsets of ~10–20px in each direction
4. Repeat up to 3 times with different coordinates before considering the tap a failure

Do NOT take screenshots to check whether a tap worked — use `list_elements_on_screen` instead. It is faster and does not consume context window space.

### Text field interaction
Text fields in this app often require specific handling:

1. **Tap to focus**: The reported `y` coordinate is the top edge of the field. Tap at `y + height/2` (the vertical center) to reliably activate the field.
2. **Verify focus before typing**: After tapping, call `list_elements_on_screen`. If the keyboard is visible (keyboard buttons like `shift`, `continue`, `Emoji` appear in the listing), the field is focused. If no keyboard elements appear, re-tap with adjusted coordinates.
3. **Type and verify**: After calling `type_keys`, call `list_elements_on_screen` and check the field's `value` property. If it still shows the placeholder, the text did not land — re-tap and retype.
4. **Never use screenshots** to verify text entry — check the `value` property in the element listing.

### General principle
Prefer tight `tap → list_elements → adjust` loops over `tap → sleep → screenshot → inspect` loops. The element listing is the primary feedback mechanism. Screenshots are a last resort for visual diagnosis when the element listing is ambiguous.

## Screenshot Policy

**Always use `save_screenshot` (saves to disk). Never use `take_screenshot` (loads into context).**

`take_screenshot` puts the full image into the conversation context, consuming tokens and slowing down the run. The only acceptable use of `take_screenshot` is failure triage when `list_elements_on_screen` is genuinely ambiguous — and even then, prefer `save_screenshot` + reading the saved file after compacting.

### Audit screenshots
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

### Additional screenshots
You may take screenshots beyond the required checkpoints — especially for error states or unexpected behavior. Use a `FAIL-` prefix for failure triage screenshots (e.g. `FAIL-05-unexpected-error.png`).

### Failure triage
If a test step fails after 3 retries and `list_elements_on_screen` doesn't explain why:
1. Use `save_screenshot` to save to the run folder with a `FAIL-` prefix
2. Compact it: `sips -Z 1200 <file.png> --out <file.png>`
3. Only then read the compacted file if visual inspection is needed

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

Wait 5 seconds for the app to settle. Do not take a screenshot here unless login is already going off the rails and you need failure triage.

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

For each step, use mobile-mcp tools:
- `list_elements_on_screen` — find elements, verify screen state, and get coordinates. **This is the primary tool.**
- `click_on_screen_at_coordinates` — tap elements
- `save_screenshot` — save audit checkpoint screenshots to disk (**never use `take_screenshot`**)
- `type_keys` — enter text

**Always call `list_elements_on_screen` before tapping** — coordinates change between screens.

**Never use screenshots for routine verification.** Do not take a screenshot to check whether a tap worked, whether text was entered, or whether a screen transition happened. Use `list_elements_on_screen` for all of these.

**Dismiss overlays**: If `top-banner-view-dismiss-button` or `feedback-banner-popover-close-button` appears, tap it before proceeding.

Record evidence as you go:
- Capture the simulator name and UDID used for each device class
- Keep the created order number for the `orders` section
- Save checkpoint screenshots using `save_screenshot` at each recommended checkpoint (see Screenshot Policy)
- Compact each screenshot immediately after saving

## Step 6: Generate HTML Report

After all sections complete, generate a self-contained HTML report file in the run folder and open it in the browser.

The report file should be saved as `/tmp/woo-smoke-test-<timestamp>/report.html` and include:

1. **Summary table** — section name, PASS/FAIL badge, and notes for each section tested
2. **Screenshot flipbook** — all audit screenshots displayed in order with labels, navigable with Previous/Next buttons or arrow keys
3. **Issues found** — any crashes, errors, or unexpected behavior
4. **Not tested** — list of manual-only items

### HTML report structure

Generate a single HTML file with inline CSS and JS (no external dependencies). Key features:

- Screenshots embedded as `<img src="file:///tmp/woo-smoke-test-<timestamp>/screenshots/01-prologue.png">` using absolute `file://` paths
- PASS sections get a green badge, FAIL sections get a red badge
- Flipbook: show one screenshot at a time with the label below it. Arrow keys and buttons navigate between screenshots
- Responsive layout that works at reasonable browser widths
- Dark header with the Woo purple (`#7F54B3`) as accent color

After writing the file, open it:
```bash
open /tmp/woo-smoke-test-<timestamp>/report.html
```

### Console summary

Also print a brief text summary to the console so the user sees results without needing the browser:

```
Smoke Test: 5/7 sections passed
Report: /tmp/woo-smoke-test-<timestamp>/report.html (opened in browser)
Failed: Orders (refund button not found), POS (crash on checkout)
```
