---
name: verify
description: Build the app with mock data, launch on simulator, and verify feature behavior via mobile-mcp interaction. Use after making changes to visually confirm they work from a user's perspective.
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob, mcp__mobile-mcp__*"
---

# E2E Simulator Verification

Build the app, launch it on the iOS simulator with mocked data, and verify the affected feature areas work correctly by navigating the UI and checking for expected elements.

Read `.claude/references/screen-identifiers.md` to understand how to identify screens and navigate between them.

## Step 1: Detect Feature Scope

Determine which features were changed:

```bash
git diff --name-only trunk...HEAD
```

If no diff against trunk, fall back to `git diff --name-only HEAD~1`.

Read `.claude/feature-map.json` and match changed file paths against `pathPatterns` for each feature. Collect all matched features. If no features match, default to `"dashboard"`.

## Step 2: Discover Simulator

Use the `/simulator` skill approach: find a booted iPhone first, otherwise find an available one and boot it. Store the UDID for all subsequent commands.

## Step 3: Start Mock Server

Use the `/mocks` skill approach: start WireMock on port 8282 in the background. Verify it's running before proceeding.

## Step 4: Build the App

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination "platform=iOS Simulator,id=<UDID>" -sdk iphonesimulator \
  build 2>&1 | tail -30
```

If the build fails, analyze errors and report. The build must succeed — verification requires the current code.

## Step 5: Launch App

Collect launch arguments. Start with the base set:
- `logout-at-launch`
- `disable-animations`
- `mocked-wpcom-api`
- `-ui_testing`
- `-mocks-port`
- `8282`

For each matched feature, check if `feature-map.json` defines additional `launchArgs` and append them.

Launch using `xcrun simctl launch` to pass arguments (mobile-mcp's `launch_app` does not support launch arguments):
```bash
xcrun simctl launch <UDID> com.automattic.woocommerce <all-args-space-separated>
```

Wait 5 seconds for the app to settle.

## Step 6: Navigate and Verify

Use mobile-mcp tools (`list_elements_on_screen`, `click_on_screen_at_coordinates`, `take_screenshot`) to interact with the app.

Consult `.claude/references/screen-identifiers.md` for:
- How to identify which screen you're on (primary identifiers)
- Which elements to look for on each screen
- Step-by-step navigation flows to reach any screen

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

Stop the mock server using the `/mocks` skill approach (kill by port).
