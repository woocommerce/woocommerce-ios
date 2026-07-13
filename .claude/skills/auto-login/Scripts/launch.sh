#!/bin/bash
set -euo pipefail

# Launches the already-installed WooCommerce app on a simulator, pre-authenticated into a store.
# Usage: launch.sh <udid> <site-address> <username> <secret> [auth-type] [store-id]

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <udid> <site-address> <username> <secret> [auth-type: applicationPassword|wpcom] [store-id]" >&2
  exit 1
fi

UDID="$1"
SITE_ADDRESS="$2"
USERNAME="$3"
SECRET="$4"
AUTH_TYPE="${5:-applicationPassword}"
STORE_ID="${6:-}"

BUNDLE_ID="com.automattic.woocommerce"

if [ "$AUTH_TYPE" != "applicationPassword" ] && [ "$AUTH_TYPE" != "wpcom" ]; then
  echo "Unrecognized auth-type '$AUTH_TYPE' — must be exactly 'applicationPassword' or 'wpcom'" >&2
  exit 1
fi

if [ "$AUTH_TYPE" = "wpcom" ] && [ -z "$STORE_ID" ]; then
  echo "auth-type 'wpcom' requires a store-id argument" >&2
  exit 1
fi

ENV_ARGS=(
  "SIMCTL_CHILD_DEBUG_LOGIN_SITE_ADDRESS=$SITE_ADDRESS"
  "SIMCTL_CHILD_DEBUG_LOGIN_USERNAME=$USERNAME"
  "SIMCTL_CHILD_DEBUG_LOGIN_SECRET=$SECRET"
  "SIMCTL_CHILD_DEBUG_LOGIN_AUTH_TYPE=$AUTH_TYPE"
)
if [ -n "$STORE_ID" ]; then
  ENV_ARGS+=("SIMCTL_CHILD_DEBUG_LOGIN_STORE_ID=$STORE_ID")
fi

# Force a fresh cold launch — simctl launch on an already-running process just
# foregrounds it without re-invoking willFinishLaunchingWithOptions, which would
# silently ignore these env vars and keep whatever session was already active.
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

# Seeding launch: this is the one that reads the env vars above and persists
# credentials + store ID to Keychain/UserDefaults.
env "${ENV_ARGS[@]}" xcrun simctl launch "$UDID" "$BUNDLE_ID"

# The seeding launch starts out deauthenticated — credentials are only set partway
# through its willFinishLaunchingWithOptions — so launch-time steps that are gated on
# already-being-authenticated (push notification registration, analytics identity
# refresh) miss their window and never get a second chance during that same process.
# Now that credentials are persisted, relaunch once more WITHOUT the debug env vars:
# this second launch boots already-authenticated from its very first line, exercising
# the exact same cold-start path a real login would, so those steps run normally.
sleep 3
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$UDID" "$BUNDLE_ID"
