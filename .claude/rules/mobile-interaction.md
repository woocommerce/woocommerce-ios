# Mobile Interaction Rules

Rules for driving the iOS simulator via mobile-mcp. Apply these whenever using mobile-mcp tools (`list_elements_on_screen`, `click_on_screen_at_coordinates`, `save_screenshot`, `take_screenshot`, `type_keys`, etc.).

## Primary Feedback Tool

`list_elements_on_screen` is the primary tool for verifying screen state. Use it to:
- Confirm which screen is displayed
- Find element coordinates before tapping
- Verify taps worked (screen changed)
- Verify text was entered (field `value` updated)
- Check for overlays or error messages

**Never use screenshots for routine verification.** Do not take a screenshot to check whether a tap worked, whether text was entered, or whether a screen transition happened.

## Screenshot Policy

**Always use `save_screenshot` (saves to disk). Never use `take_screenshot` (loads into context).**

`take_screenshot` puts the full image into the conversation context, consuming tokens and slowing down the run. The only acceptable use is failure triage when `list_elements_on_screen` is genuinely ambiguous — and even then, prefer `save_screenshot` + reading the saved file after compacting.

Compact screenshots immediately after saving:
```bash
sips -Z 1200 <file.png> --out <file.png>
```

## Tap Strategy

**Always call `list_elements_on_screen` before tapping** — coordinates change between screens.

### Retry with variance
When a tap does not produce the expected result, do NOT retry at the same coordinates. Use a tight loop:

1. **Tap** at the element coordinates reported by `list_elements_on_screen`
2. **Immediately call `list_elements_on_screen`** to check whether the screen state changed
3. If unchanged, **vary the tap position**: try the center of the element's bounding rect (`x + width/2`, `y + height/2`), then offsets of ~10-20px in each direction
4. Repeat up to 3 times with different coordinates before considering the tap a failure

### Known coordinate quirks
- **UIMenu buttons** (e.g. `performance-time-range-menu`) often need a slight right/down offset from the reported coordinates.
- **Navigation bar buttons** (e.g. search, `+`) often need a tap ~15px below the reported y coordinate because of safe area insets.
- **Tab bar buttons** may need tapping slightly above or below their reported coordinates.

## Text Field Interaction

1. **Tap to focus**: The reported `y` coordinate is the top edge of the field. Tap at `y + height/2` (the vertical center) to reliably activate the field.
2. **Verify focus before typing**: After tapping, call `list_elements_on_screen`. If keyboard buttons (`shift`, `continue`, `Emoji`) appear in the listing, the field is focused. If not, re-tap with adjusted coordinates.
3. **Type and verify**: After calling `type_keys`, call `list_elements_on_screen` and check the field's `value` property. If it still shows the placeholder, the text did not land — re-tap and retype.
4. **Secure fields**: Password fields won't show their value in the element listing. Tap "Show password" if available to verify, or proceed and check for errors after submitting.

## Dismiss Overlays

If `top-banner-view-dismiss-button` or `feedback-banner-popover-close-button` appears in the element listing, tap it before proceeding with the test step.

## General Principle

Prefer tight `tap -> list_elements -> adjust` loops over `tap -> sleep -> screenshot -> inspect` loops. The element listing is the primary feedback mechanism. Screenshots are for human review and failure diagnosis, not for the agent's own verification.

## Unexpected Behavior and Triage

When something doesn't work on the first attempt, **don't just retry silently**. Reason about what happened and record an observation.

### Classify the problem

Before retrying, consider which category the issue falls into:

| Category | Signals | Action |
|----------|---------|--------|
| **Test framework flake** | WDA timeout, `context deadline exceeded`, home screen appeared, tap didn't register but elements are correct | Retry. Note it as a framework issue in observations. |
| **Transient app/network issue** | "Something went wrong", spinner that doesn't resolve, empty data that loads on retry | Retry. Flag it as an observation — transient errors can mask real bugs if they happen consistently. |
| **Possible app bug** | Wrong screen shown, unexpected error message, element missing that should be there, data looks wrong | Save a `FAIL-` screenshot. Record a detailed observation. Continue if possible but flag the concern. |
| **Definite app bug** | Crash, data loss, wrong amounts, broken navigation that doesn't recover | Save a `FAIL-` screenshot. Record the bug in detail. |

### Record observations

Keep a running list of observations. Each observation should include:
- **What happened**: the unexpected behavior
- **Category**: framework flake, transient issue, possible bug, or definite bug
- **What you did**: how you worked around it (retried, adjusted coordinates, relaunched, etc.)
- **Concern level**: low (framework noise), medium (worth a second look), high (likely a real bug)

Even if a step eventually passes after retries, record the observation. A step that consistently needs 3 retries is a signal, not just noise.
