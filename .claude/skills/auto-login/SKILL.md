---
name: auto-login
description: Launch the WooCommerce app on a simulator already authenticated into a given store (application password or WPCom), skipping the manual login UI. Meant to be referenced by other skills/workflows that need a logged-in session fast, but also directly runnable.
user-invocable: true
allowed-tools: "Bash"
argument-hint: "<UDID> <site-address> <username> <secret> [auth-type: applicationPassword|wpcom] [store-id]"
---

# Auto-Login

Launch the app already authenticated into a store, skipping the manual login UI. Backed by a `DEBUG`-only
shortcut in `ProcessConfiguration.swift` that seeds `SessionManager` credentials + store ID at launch, before
`AppCoordinator` decides whether to show the login screen or the tab bar.

**Scope**: this skill only launches. It does not build the app, install it, or provision a site — those are
the caller's responsibility (see `/build`, `/simulator`, and JN site provisioning tools/skills).

## Prerequisites

- A booted simulator (use the `/simulator` skill approach if none is booted)
- The app already built **and installed** for that simulator, from a `DEBUG` configuration (the default for
  simulator builds). If not installed yet, build first and `xcrun simctl install <UDID> <path-to-.app>`.
- Credentials for the target store:
  - `applicationPassword` (default) — a wp-admin username + an application password created on that site.
    This is the right choice for a self-hosted/Jurassic Ninja site with no Jetpack connection.
  - `wpcom` — a WordPress.com username + auth token, plus the store's real numeric site ID (`store-id`).

## Usage

```bash
bash .claude/skills/auto-login/Scripts/launch.sh <UDID> <site-address> <username> <secret> [auth-type] [store-id]
```

Examples:
```bash
# Self-hosted / JN site via application password (auth-type defaults to applicationPassword)
bash .claude/skills/auto-login/Scripts/launch.sh "$UDID" https://example-jn-site.com admin "abcd 1234 efgh 5678"

# WPCom-connected site (needs the real site ID)
bash .claude/skills/auto-login/Scripts/launch.sh "$UDID" https://example.com someuser somewpcomtoken wpcom 123456789
```

The script launches twice: a seeding launch that reads the credentials and persists them to
Keychain/UserDefaults, then a second plain relaunch (no debug env vars) that boots already-authenticated
from the start — this is what makes launch-time steps gated on already-being-authenticated (push
notification registration, analytics identity refresh) run normally, since the seeding launch alone starts
out deauthenticated and misses that window. See the comments in `launch.sh` for details.

After it returns, wait ~3 seconds, then verify: screenshot the simulator or use `list_ui_elements` (if
mobile-mcp is available) and confirm the tab bar is visible (not the login screen), and that the store name
matches the target site.

## Never commit secrets

Credentials only ever exist as arguments to this one shell invocation and the resulting `SIMCTL_CHILD_*`
environment variables passed to `simctl launch` — never write them to a file in this repo, a scheme, or any
other persisted location.

## Known limitations

These stem from the app-side `DEBUG` shortcut itself and are accepted tradeoffs, not bugs in this script:

- **Don't persist these env vars on a personal Xcode scheme.** If set that way instead of via this script,
  every subsequent debug launch — not just the one you intended — silently re-authenticates and re-syncs.
  Always prefer invoking `launch.sh` fresh (it only sets them for that one `simctl launch` call).
- **`wpcom` requires a real `store-id`.** This script validates that, but if you ever set the env vars
  directly (bypassing this script), a missing/invalid store ID for `wpcom` credentials silently falls back
  to the self-hosted placeholder site ID, producing a broken/inconsistent session.
- **No error is surfaced on bad credentials.** Unlike the real login UI, this shortcut doesn't validate role
  eligibility, WooCommerce installation, or application-password validity. Bad credentials just produce a
  blank/broken dashboard — check the simulator's console log (`DDLogError`) if the store doesn't load.
- If you also pass `logout-at-launch` in the same launch, auto-login will silently re-authenticate right
  after it deauthenticates — the two aren't designed to be combined.
