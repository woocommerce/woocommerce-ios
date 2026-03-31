#!/usr/bin/env bash
#
# Find a booted iOS simulator or boot one. Returns the UDID.
# Usage: find-simulator.sh [iphone|ipad] [--second]
# Default: iphone
# --second: return the second matching simulator instead of the first

set -euo pipefail

DEVICE_TYPE="${1:-iphone}"

case "$DEVICE_TYPE" in
    iphone) PATTERN="iPhone" ;;
    ipad)   PATTERN="iPad" ;;
    *)
        echo "Usage: $0 [iphone|ipad] [--second]" >&2
        exit 1
        ;;
esac

SKIP_FIRST=false
if [ "${2:-}" = "--second" ]; then
    SKIP_FIRST=true
fi

if [ "$SKIP_FIRST" = true ]; then
    SELECT_LINE="sed -n '2p'"
else
    SELECT_LINE="head -1"
fi

# Check for an already booted device
BOOTED=$(xcrun simctl list devices booted | grep -E "$PATTERN" | eval "$SELECT_LINE" || true)

if [ -n "$BOOTED" ]; then
    UDID=$(echo "$BOOTED" | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
    NAME=$(echo "$BOOTED" | sed -E 's/^[[:space:]]*//' | sed -E 's/ \(.*//')
    echo "$UDID"
    echo "Simulator ready: $NAME ($UDID)" >&2
    exit 0
fi

# Find an available device and boot it
AVAILABLE=$(xcrun simctl list devices available | grep -E "$PATTERN" | eval "$SELECT_LINE" || true)

if [ -z "$AVAILABLE" ]; then
    if [ "$SKIP_FIRST" = true ]; then
        echo "No second available $DEVICE_TYPE simulator found." >&2
    else
        echo "No available $DEVICE_TYPE simulator found." >&2
    fi
    exit 1
fi

UDID=$(echo "$AVAILABLE" | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
NAME=$(echo "$AVAILABLE" | sed -E 's/^[[:space:]]*//' | sed -E 's/ \(.*//')

echo "Booting $NAME ($UDID)..." >&2
xcrun simctl boot "$UDID"
sleep 3

echo "$UDID"
echo "Simulator ready: $NAME ($UDID)" >&2
