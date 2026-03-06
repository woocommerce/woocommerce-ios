#!/usr/bin/env bash
#
# Find a booted iOS simulator or boot one. Returns the UDID.
# Usage: find-simulator.sh [iphone|ipad]
# Default: iphone

set -euo pipefail

DEVICE_TYPE="${1:-iphone}"

case "$DEVICE_TYPE" in
    iphone) PATTERN="iPhone" ;;
    ipad)   PATTERN="iPad" ;;
    *)
        echo "Usage: $0 [iphone|ipad] (got '$DEVICE_TYPE')" >&2
        exit 1
        ;;
esac

# Check for an already booted device
BOOTED=$(xcrun simctl list devices booted | grep -E "$PATTERN" | head -1 || true)

if [ -n "$BOOTED" ]; then
    UDID=$(echo "$BOOTED" | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
    NAME=$(echo "$BOOTED" | sed -E 's/^[[:space:]]*//' | sed -E 's/ \(.*//')
    open -g -a Simulator
    echo "$UDID"
    echo "Simulator ready: $NAME ($UDID)" >&2
    exit 0
fi

# Find an available device and boot it
AVAILABLE=$(xcrun simctl list devices available | grep -E "$PATTERN" | head -1 || true)

if [ -z "$AVAILABLE" ]; then
    echo "No available $DEVICE_TYPE simulator found." >&2
    exit 1
fi

UDID=$(echo "$AVAILABLE" | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
NAME=$(echo "$AVAILABLE" | sed -E 's/^[[:space:]]*//' | sed -E 's/ \(.*//')

echo "Booting $NAME ($UDID)..." >&2
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
open -g -a Simulator

echo "$UDID"
echo "Simulator ready: $NAME ($UDID)" >&2
