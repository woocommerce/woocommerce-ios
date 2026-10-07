---
name: auto-login
description: "Log the simulator into a live WooCommerce store through the DEBUG shortcut. Use WireMock UI login when mocks are requested. Jurassic Ninja is one option when no site is specified."
user-invocable: true
allowed-tools: "Bash, Read, mcp__mobile-mcp__*"
argument-hint: "[mocks|site] [UDID] [site-address] [credential-file]"
---

# Auto-Login

Use **live site** by default for `auto-login`, preserving the existing DEBUG login shortcut.
Use **WireMock UI login** only for `auto-login with mocks` or the `mocks` skill argument.
Use **live site** for `auto-login with a test site`, `auto-login with a real site`,
`auto-login with a live site`, or `auto-login with my site`, even when no URL is supplied.
Reuse a session only when its site and data fit the task.
Preserve unrelated sessions: use a separate simulator. Erase or uninstall only for an explicit clean test.
For authentication tests, start logged out and test the required login UI instead of the DEBUG shortcut.
Skill arguments `mocks` and `site` select the flow; they are not `launch.sh` flags.

## Prepare the Simulator

Use `/simulator` to select a device and `/build` to build the current DEBUG app.
Install it with `xcrun simctl install <UDID> <path-to-.app>` before launch.
Use Xcode's standard signed simulator build. Simulator Keychain entitlements can be embedded in
the executable; empty `codesign` entitlement output alone does not justify re-signing the app.
For a missing mobile-mcp device helper, follow `.claude/rules/verification.md`.

## WireMock UI Login

This flow uses mocked authentication, simulated 2FA, and fixture data.

1. Start this checkout's fixtures with `/mocks`. Confirm that the server serves this checkout.
   If another server owns port 8282, leave it unchanged and use a separate port.
2. Launch with the mocked arguments in `/verify`. For a separate API port, follow its override guidance.
3. Use mobile-mcp to complete “Login (from prologue)” in `.claude/references/screen-identifiers.md`,
   including the mocked 2FA step. Refresh UI elements after typing before selecting Continue.
4. Confirm the tab bar and expected fixture data. Relaunch without `logout-at-launch` to check persistence.

## Live Site

### Select a Site

For `my site`, use the site identified in the task context. Ask for its URL or authorized access
when missing; do not substitute a provisioned site. For other live requests, use the supplied site first,
then a suitable existing test store. If neither is available,
read the full descriptions of available MCP tools, including generic provider loaders,
before asking for credentials. If a loader advertises Jurassic Ninja, load that provider
and read its schemas. A missing standalone tool does not establish provider unavailability.

Jurassic Ninja is one option alongside other providers or a user-supplied site.
Offer available options. If temporary site creation is already authorized, use a suitable provider
without asking for credentials that provisioning supplies. A request to create a temporary test site
includes creating its test login credential. A provisioned site is a real test store.
Install and activate WooCommerce, wait for readiness, and prepare the required plugins and data.
Get the actual WordPress username from site configuration or a user lookup.
A returned password does not identify its username. Report provider failures and offer another option.

### Prepare Credentials

For a clean simulator, use a normal WordPress password (`wporg`). The app performs the cookie/nonce
handshake and stores its API password; the normal password also remains in the simulator Keychain.
For a new temporary site, use provisioning access to create a temporary user with a generated password.
Use `shop_manager` for product/order checks; use administrator only when the feature requires it.
Prefer an authenticated admin/API tool or authorized admin session with a REST nonce over retrieving
an existing administrator password. Request only the provisioning fields needed for that access.
For a supplied site, keep test-user creation within the user's authorization; preserve existing users.

Ask for a protected credential-file path or local setup, never a password in chat. If credentials were
already supplied, transfer them to the protected file without repeating them in output or messages.
Create the credential file outside the repository with `umask 077` before writing.
Capture the HTTPS site URL, actual username, and WordPress password directly into the entries below.

Use an absolute path to a regular file owned by the current user, with mode `600`.
Write these three raw `KEY=value` entries without shell quotes or `export`:

```text
SITE_URL=https://test-site.example
USERNAME=actual-wordpress-login
WP_PASSWORD=normal-wordpress-password
```

Keep secrets and one-click login URLs out of output, task messages, and repository files.
Keep shell tracing off. Retain task-created credentials through review. At task completion, delete
temporary users (which revokes their API passwords), or revoke task-created API passwords separately
for existing users; preserve existing accounts and credentials. End only task-created admin sessions before
removing local cookies and credential files. Report any remote cleanup that could not be confirmed.

### Launch and Verify

Use the protected-file interface (requires Python 3). `WP_PASSWORD` selects `wporg`:

```bash
bash .claude/skills/auto-login/Scripts/launch.sh --from-environment <UDID> <site-address> <absolute-credential-file>
```

The existing positional interface remains supported:

```text
launch.sh <UDID> <site-address> <username> <secret> [auth-type] [store-id]
```

The legacy positional `applicationPassword` mode uses an API password already stored by the app.
It does not install the supplied secret as the stored API password; use `WP_PASSWORD` for a clean simulator.
Use `wpcom` for a token and real store ID. Positional secrets can be visible in process arguments;
prefer the protected-file interface. If the site's cookie/nonce handshake fails, report that failure
and use an authorized login UI for the same store or request working access. Offer another test site
only when the task permits a different store; keep the specified store for `my site`.

The script seeds credentials, then relaunches without debug login variables. Keep those variables
out of Xcode schemes and omit `logout-at-launch` from this flow.
After launch and a plain relaunch, confirm the tab bar, target store, and loaded data through mobile-mcp.
Script success means launch succeeded, not login. Report verified, failed, or unverified from UI evidence.
If the outcome is unclear, inspect the current UI before another login attempt; avoid concurrent attempts.
