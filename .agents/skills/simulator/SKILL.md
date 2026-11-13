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

## Usage

Run the script:

```bash
# iPhone (default):
UDID=$(Scripts/find-simulator.sh iphone)

# iPad:
UDID=$(Scripts/find-simulator.sh ipad)
```

The script prints the UDID to stdout and status messages to stderr. It will boot a simulator if none is already running.

## Output

Report the simulator name and UDID so the caller can use it:
```
Simulator ready: iPhone 17 (93E9F784-2B91-4D83-BFA5-F1682C28180B)
```

## Watch

Watch app verification is not supported — the Watch app runs on a separate watchOS simulator with a different build destination (`watchOS Simulator`). It cannot be tested via the iPhone/iPad iOS simulator used for app verification.
