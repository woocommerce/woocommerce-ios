#!/bin/bash
set +x
set -euo pipefail

# Launches the already-installed WooCommerce app on a simulator, pre-authenticated into a store.
# Usage: launch.sh <udid> <site-address> <username> <secret> [auth-type] [store-id]

usage() {
  echo "Usage: $0 --from-environment <udid> <site-address> <credential-file>" >&2
  echo "Usage: $0 <udid> <site-address> <username> <secret> [auth-type: wporg|applicationPassword|wpcom] [store-id]" >&2
  exit 1
}

read_credential_file() {
  python3 - "$@" <<'PY'
import os
import stat
import sys
from urllib.parse import urlsplit

try:
    credential_path, requested_site, repository_path = sys.argv[1:]
    if not os.path.isabs(credential_path):
        raise ValueError("Credential file path must be absolute")
    resolved_file = os.path.realpath(credential_path)
    resolved_repository = os.path.realpath(repository_path)
    if os.path.commonpath([resolved_file, resolved_repository]) == resolved_repository:
        raise ValueError("Credential file must be outside the repository")
    descriptor = os.open(credential_path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "r", encoding="utf-8") as credential_file:
        metadata = os.fstat(credential_file.fileno())
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
            raise ValueError("Credential file must be a regular file owned by the current user")
        if stat.S_IMODE(metadata.st_mode) & 0o077:
            raise ValueError("Credential file must allow access only to its owner")
        content = credential_file.read(65537)
    if len(content) > 65536 or "\0" in content:
        raise ValueError("Invalid credential file")
    credentials = {}
    for line in content.splitlines():
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if not separator or key not in {"SITE_URL", "USERNAME", "WP_PASSWORD"} or key in credentials:
            raise ValueError("Expected one SITE_URL, USERNAME, and WP_PASSWORD entry")
        if not value:
            raise ValueError("Credential entries must be non-empty")
        credentials[key] = value
    if set(credentials) != {"SITE_URL", "USERNAME", "WP_PASSWORD"}:
        raise ValueError("Expected SITE_URL, USERNAME, and WP_PASSWORD entries")
    if credentials["SITE_URL"].rstrip("/") != requested_site.rstrip("/"):
        raise ValueError("Credential file does not match the requested site")
    try:
        site = urlsplit(credentials["SITE_URL"])
    except ValueError:
        raise ValueError("Invalid HTTPS site URL") from None
    if (site.scheme != "https" or not site.hostname or site.username is not None
            or site.password is not None or site.query or site.fragment
            or any(character.isspace() or character == "\\" for character in credentials["SITE_URL"])):
        raise ValueError("Use an HTTPS site URL without embedded credentials, query, or fragment")
    for key in ("USERNAME", "WP_PASSWORD"):
        sys.stdout.buffer.write(credentials[key].encode("utf-8") + b"\0")
except (OSError, UnicodeError):
    print("Cannot read a protected credential file", file=sys.stderr)
    sys.exit(1)
except ValueError as error:
    print(str(error), file=sys.stderr)
    sys.exit(1)
PY
}

if [ "${1:-}" = "--from-environment" ]; then
  [ "$#" -eq 4 ] || usage
  UDID="$2"
  SITE_ADDRESS="$3"
  SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  CREDENTIAL_VALUES=()
  # Parse data without sourcing it or putting the secret in this command's arguments.
  while IFS= read -r -d '' credential_value; do
    CREDENTIAL_VALUES+=("$credential_value")
  done < <(read_credential_file "$4" "$SITE_ADDRESS" "$SCRIPT_DIRECTORY/../../../..")
  [ "${#CREDENTIAL_VALUES[@]}" -eq 2 ] || exit 1
  USERNAME="${CREDENTIAL_VALUES[0]}"
  SECRET="${CREDENTIAL_VALUES[1]}"
  AUTH_TYPE="wporg"
  STORE_ID=""
  unset CREDENTIAL_VALUES credential_value
else
  [ "$#" -ge 4 ] || usage
  UDID="$1"
  SITE_ADDRESS="$2"
  USERNAME="$3"
  SECRET="$4"
  AUTH_TYPE="${5:-wporg}"
  STORE_ID="${6:-}"
fi

BUNDLE_ID="com.automattic.woocommerce"

if [ "$AUTH_TYPE" != "wporg" ] && [ "$AUTH_TYPE" != "applicationPassword" ] && [ "$AUTH_TYPE" != "wpcom" ]; then
  echo "Unrecognized auth-type '$AUTH_TYPE' — must be exactly 'wporg', 'applicationPassword', or 'wpcom'" >&2
  exit 1
fi

if [ "$AUTH_TYPE" = "wpcom" ] && [ -z "$STORE_ID" ]; then
  echo "auth-type 'wpcom' requires a store-id argument" >&2
  exit 1
fi

# Keep inherited debug settings out of the plain relaunch.
unset SIMCTL_CHILD_DEBUG_LOGIN_SITE_ADDRESS SIMCTL_CHILD_DEBUG_LOGIN_USERNAME \
  SIMCTL_CHILD_DEBUG_LOGIN_SECRET SIMCTL_CHILD_DEBUG_LOGIN_AUTH_TYPE SIMCTL_CHILD_DEBUG_LOGIN_STORE_ID

# Force a fresh cold launch — simctl launch on an already-running process just
# foregrounds it without re-invoking willFinishLaunchingWithOptions, which would
# silently ignore these env vars and keep whatever session was already active.
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

# Seeding launch: this is the one that reads the temporary env vars and persists
# credentials + store ID to Keychain/UserDefaults.
(
  export SIMCTL_CHILD_DEBUG_LOGIN_SITE_ADDRESS="$SITE_ADDRESS"
  export SIMCTL_CHILD_DEBUG_LOGIN_USERNAME="$USERNAME"
  export SIMCTL_CHILD_DEBUG_LOGIN_SECRET="$SECRET"
  export SIMCTL_CHILD_DEBUG_LOGIN_AUTH_TYPE="$AUTH_TYPE"
  if [ -n "$STORE_ID" ]; then
    export SIMCTL_CHILD_DEBUG_LOGIN_STORE_ID="$STORE_ID"
  fi
  xcrun simctl launch "$UDID" "$BUNDLE_ID"
)
unset SECRET USERNAME

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
