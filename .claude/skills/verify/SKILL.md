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

Reuse a suitable session. When setup is needed, use WireMock unless the task requests or requires a live store.
Follow `/auto-login mocks` for mocked setup or `/auto-login` for live-store setup.
For authentication tests, use `logout-at-launch` and the login UI; skip session reuse and the DEBUG shortcut.

Before setting up anything, determine what's already available:

1. **Simulator**: is an iPhone simulator already booted? (`xcrun simctl list devices booted | grep iPhone`)
2. **App state**: is the app already installed? (`xcrun simctl listapps <UDID> 2>/dev/null | grep com.automattic.woocommerce`)
3. **Session state** (except authentication tests): if the app is installed, launch it and check the current screen — is the user already logged in (tab bar visible) or on the login screen? Confirm that the store and data match the test requirements.

**Most verification happens during development** where the simulator has a current build and an active session. In this case, you only need to build your changes and re-launch — no mock server or login flow needed.

For an existing suitable session, skip Step 3. Use mock-specific launch arguments only for WireMock.

## Step 2: Detect Feature Scope

Determine which features were changed:

```bash
git diff --name-only trunk...HEAD
```

If no diff against trunk, fall back to `git diff --name-only HEAD~1`.

Read `.claude/references/feature-map.json` and match changed file paths against `pathPatterns` for each feature. Collect all matched features. If no features match, **skip verification entirely** — report which files changed, note that none matched any feature path pattern, and stop (do not proceed to Steps 3-8).

## Step 3: Prepare the Selected Environment

**New live session**: prepare the selected site's plugins, data, and protected credentials through `/auto-login`.

**Mocked environment**: use `/mocks` to start this checkout's WireMock fixtures. Confirm the fixture
root before reusing a server. If another checkout owns port 8282, use a separate port and the API
override below. Preserve servers started by other tasks.

## Step 4: Build the App

Use the `/simulator` skill approach to discover a booted simulator UDID.

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=<UDID>" \
  build 2>&1 | tail -30
```

If the build fails, analyze errors and report. The build must succeed — verification requires the current code.

## Step 5: Launch App

Install the built app on the selected simulator with `xcrun simctl install <UDID> <path-to-.app>`.
Locate that build's app using the WooCommerce target's `TARGET_BUILD_DIR` and `FULL_PRODUCT_NAME`
from `xcodebuild -showBuildSettings` with the same workspace, scheme, and destination.

**For a new live session outside authentication tests**, follow `/auto-login` to launch and confirm
loaded data.

**If using mocked environment**, collect launch arguments:
- `logout-at-launch`, `disable-animations`, `mocked-wpcom-api`, `-ui_testing`, `-mocks-port`, `8282`
- Append any feature-specific `launchArgs` from `feature-map.json`
- **Mock credentials**: site `https://yourwoosite.com`, email `t@wp.com`, password `pw`.
- Complete “Login (from prologue)” in `.claude/references/screen-identifiers.md`.

For a separate port, omit `mocked-wpcom-api` (it fixes the API port at 8282), set
`SIMCTL_CHILD_wpcom-api-base-url=http://localhost:<port>/` for each launch, and set `-mocks-port <port>`.
Pass the hyphenated API variable through `env` when invoking `xcrun`.
`-mocks-port` alone changes resource URLs, not the WordPress.com API endpoint.

Launch using `xcrun simctl launch` (supports launch arguments, unlike mobile-mcp's `launch_app`):
```bash
xcrun simctl launch <UDID> com.automattic.woocommerce <all-args-space-separated>
```

**If reusing a live session**, launch without mock args. For a mocked session, retain its mock flags
and API override, but omit `logout-at-launch`:
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

Stop only the mock server started by this task, using `/mocks` with its selected port.
