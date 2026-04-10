---
name: verify
description: Build the app, launch on simulator, and verify feature behavior via mobile-mcp interaction. Use after making changes to visually confirm they work from a user's perspective.
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob, mcp__mobile-mcp__*"
---

# E2E Simulator Verification

Build the app, launch it on the iOS simulator, and verify the affected feature areas work correctly by navigating the UI and checking for expected elements.

Read `.claude/references/screen-identifiers.md` to understand how to identify screens and navigate between them.

## Step 1: Assess the Environment

Before setting up anything, determine what's already available:

1. **Simulator**: is an iPhone simulator already booted? (`xcrun simctl list devices booted | grep iPhone`)
2. **App state**: is the app already installed? (`xcrun simctl listapps <UDID> 2>/dev/null | grep com.automattic.woocommerce`)
3. **Session state**: launch the app and check the current screen — is the user already logged in (tab bar visible) or on the login screen?

**Most verification happens during development** where the simulator has a current build and an active session. In this case, you only need to build your changes and re-launch — no mock server or login flow needed.

**Use the mocked environment** (WireMock + `logout-at-launch`) only when:
- There is no existing session / data on the simulator
- You need deterministic mock data (e.g., verifying specific order states)
- The user explicitly requests mocked verification

If a mocked environment is not needed, skip Steps 3 and the mock-specific launch args in Step 5.

## Step 2: Detect Feature Scope

Determine which features were changed:

```bash
git diff --name-only trunk...HEAD
```

If no diff against trunk, fall back to `git diff --name-only HEAD~1`.

Read `.claude/references/feature-map.json` and match changed file paths against `pathPatterns` for each feature. Collect all matched features. If no features match, **skip verification entirely** — report which files changed, note that none matched any feature path pattern, and stop (do not proceed to Steps 3-8).

## Step 3: Start Mock Server (only if needed)

Use the `/mocks` skill approach: start WireMock on port 8282 in the background. Verify it's running before proceeding.

## Step 4: Build the App

Use the `/simulator` skill approach to discover a booted simulator UDID.

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=<UDID>" -sdk iphonesimulator \
  build 2>&1 | tail -30
```

If the build fails, analyze errors and report. The build must succeed — verification requires the current code.

## Step 5: Launch App

**If using mocked environment**, collect launch arguments:
- `logout-at-launch`, `disable-animations`, `mocked-wpcom-api`, `-ui_testing`, `-mocks-port`, `8282`
- Append any feature-specific `launchArgs` from `feature-map.json`
- **Mock credentials** (for login flow): site `http://yourwoosite.com`, email `t@wp.com`, password `pw`

Launch using `xcrun simctl launch` (supports launch arguments, unlike mobile-mcp's `launch_app`):
```bash
xcrun simctl launch <UDID> com.automattic.woocommerce <all-args-space-separated>
```

**If using existing environment**, launch without mock args:
```bash
xcrun simctl launch <UDID> com.automattic.woocommerce
```

Wait 5 seconds for the app to settle.

## Step 6: Navigate and Verify

Use mobile-mcp tools (`list_elements_on_screen`, `click_on_screen_at_coordinates`, `take_screenshot`) to interact with the app.

Consult `.claude/references/screen-identifiers.md` for screen identification, element lookup, and navigation flows (including login flow when using mocked environment).

For each matched feature from the feature map:

1. **Navigate** to the feature's screen following the navigation flows in screen-identifiers.md
2. **List elements** to confirm you arrived at the right screen (match primary identifier)
3. **Screenshot** and visually assess the screen
4. **Verify** the feature's `verifyElements` from feature-map.json are present
5. **Interact** if the feature defines `interactions` — execute each action

### Verification Criteria
- The screen loaded (not blank/empty/error)
- Expected accessibility elements are present
- No crash or unexpected error state visible

## Step 7: Report Results

Summarize:
- **Features verified**: list each feature and pass/fail
- **Screenshots taken**: file paths
- **Missing elements**: any expected elements not found
- **Visual assessment**: brief description of what the UI looks like
- **Issues found**: crashes, error states, unexpected behavior

## Step 8: Cleanup

```bash
xcrun simctl terminate <UDID> com.automattic.woocommerce
```

If mock server was started, stop it using the `/mocks` skill approach (kill by port).
