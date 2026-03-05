---
name: simulator
description: Discover and boot an iOS simulator. Use before any command that needs a simulator UDID.
user-invocable: true
allowed-tools: "Bash"
---

# Discover and Boot iOS Simulator

Find a booted iPhone simulator or boot one. Returns the UDID for use in subsequent commands.

**Never hardcode a simulator name** (e.g., `iPhone 16`). Available simulators change across Xcode versions — always discover dynamically.

## Step 1: Check for a Booted iPhone

```bash
xcrun simctl list devices booted | grep -E "iPhone"
```

If a booted iPhone is found, extract its UDID (the UUID in parentheses) and report it. Done.

## Step 2: Find and Boot an Available iPhone

If no iPhone is booted:

```bash
xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5
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
