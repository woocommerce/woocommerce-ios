---
name: simulator
description: Discover and boot an iOS simulator. Use before any command that needs a simulator UDID.
user-invocable: true
allowed-tools: "Bash"
argument-hint: "[iphone|ipad]"
---

# Discover and Boot iOS Simulator

Find a booted simulator or boot one. Returns the UDID for use in subsequent commands. Defaults to iPhone; pass `ipad` to use an iPad instead.

**Never hardcode a simulator name** (e.g., `iPhone 16`). Available simulators change across Xcode versions — always discover dynamically.

## Step 1: Check for a Booted Device

```bash
# For iPhone (default):
xcrun simctl list devices booted | grep -E "iPhone"

# For iPad (when requested):
xcrun simctl list devices booted | grep -E "iPad"
```

If a matching booted device is found, extract its UDID (the UUID in parentheses) and report it. Done.

## Step 2: Find and Boot an Available Device

If no matching device is booted:

```bash
# For iPhone (default):
xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5

# For iPad (when requested):
xcrun simctl list devices available | grep -E "iPad" | tail -5
```

Pick the first available device. Extract its UDID. Boot it:

```bash
xcrun simctl boot <UDID>
```

Wait a few seconds for the simulator to finish booting, then report the UDID.

## Output

Report the simulator name and UDID so the caller can use it:
```
Simulator ready: iPhone 17 (93E9F784-2B91-4D83-BFA5-F1682C28180B)
```
