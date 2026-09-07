# WooCommerce iOS Maestro smoke tests

This simulator-only suite complements XCUITest/WireMock with a production-like
release signal against developer- or CI-supplied live WooCommerce test stores.
It never requires Android's store, POS mocks, an eligibility bypass, REST
consumer keys for normal runs, a Linear issue, or a notification channel.

## Local setup

1. Install the repository toolchain pin (Maestro 2.9.0 on Java 21):

```bash
source .maestro/scripts/configure-toolchain.sh
```

Source the setup script from Bash or Zsh so its `JAVA_HOME` and `PATH` exports
remain active in the current shell.

The script selects an installed JDK 21, downloads the immutable Maestro 2.9.0
release archive into the workspace, verifies the SHA-256 in
`toolchain.properties`, and runs the checker. Buildkite uses the same path.

2. Build or locate a Debug or Alpha/prototype `.app`.
3. Copy `env.example` to `.env.local` and fill it locally.
   WordPress.com-hosted not-Woo fixtures require the dedicated WP.com pair.
   Jurassic Ninja `/wp-admin` or `/wp-admin/` URLs are normalized to the site root.

   The lab store can be provisioned instead of filled in by hand. See
   [Provisioning a lab store](#provisioning-a-lab-store) below.
4. Run the linter and side-effect-free doctor without printing values or
   booting a simulator:

```bash
.maestro/scripts/lint-env.py
.maestro/scripts/doctor.sh --app /path/to/WooCommerce.app --profile core
```

The runner derives `APP_ID` from the supplied app, prefers an already booted
compatible simulator, installs the app, generates a unique `SUITE_RUN_ID`, and
stores artifacts under `~/woocommerce-maestro-output/` by default.
When exactly one built `WooCommerce.app` exists in the repository or Xcode
DerivedData, `--app` is optional; multiple candidates fail with an explicit list.

## Provisioning a lab store

`.maestro/scripts/setup-jn-store.sh` turns a Jurassic Ninja site into the lab store:
it connects Jetpack to your own WordPress.com test account, creates WooCommerce REST
API keys, and writes the matching `.env.local` entries. Everything site-side runs over
SSH and wp-cli; only the two WordPress.com calls go over HTTP. No Jetpack partner
credentials are involved.

The quickest path is the `/setup-test-stores` skill, which creates the site through the
`jurassic-ninja` ContextA8C MCP and then runs the script. To do it by hand instead,
create a site at
`https://jurassic.ninja/create/?woocommerce&woocommerce-import-sample-data`, take the
admin password from the notice the site shows in `/wp-admin`, and run:

```bash
.maestro/scripts/setup-jn-store.sh --site your-site.jurassic.ninja
```

The script prompts for anything it cannot find in `.env.local`, so a later run against a
new site needs only `--site`. Passwords are prompted rather than passed as flags, because
command-line arguments are written to shell history and are visible in `ps` output. For
non-interactive use, supply the site password via the `JN_SSH_PASS` environment variable.

Requirements: `expect` (ships with macOS), app credentials at
`~/.configure/woocommerce-ios/secrets/woo_app_credentials.json` (`rake dependencies`), and
a **WordPress.com test account with two-factor authentication disabled** — the OAuth
password grant cannot answer a 2FA challenge non-interactively. Use test accounts only.

### What a provisioned store covers

It ships with the WooCommerce sample products and is known-good for the products flows
and the basic dashboard flows.

It has no orders, customers, or coupons, and an unset onboarding profile, so
`orders_list_and_search`, `dashboard_view_all_analytics`, `orders_create` and the coupon
flows are expected to fail against it until that data is seeded, which is not yet
automated. The negative-login fixtures (`MAESTRO_WOO_NO_JETPACK_*`,
`MAESTRO_WOO_NOT_A_WOO_STORE_*`, `MAESTRO_WOO_WRONG_ACCOUNT_STORE_URL`) are not
provisioned either and still need to be supplied by hand.

Jurassic Ninja sites expire after 7 days of inactivity. Re-run the script or the skill
against a new site when that happens; the WordPress.com account already in `.env.local`
is reused.

## Profiles

```bash
.maestro/scripts/run-smoke-tests.sh --plan --profile phone-full
.maestro/scripts/run-smoke-tests.sh --profile core
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile core
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile phone-full --seed
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile release
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile burst
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile pos-ipad
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile ios-system
```

Run one flow or rerun failures:

```bash
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app .maestro/flows/dashboard_stats.yaml
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --rerun-failed ~/woocommerce-maestro-output/SUITE-.../report.xml
```

Each failed non-destructive flow is retried once; destructive mutation failures
remain failed and proceed to cleanup without a blind retry. The final directory contains combined JUnit,
HTML with direct artifact links and a faithful rerun command, per-attempt logs,
screenshots, hierarchy/debug evidence, and a redacted JSON summary with final
status and durations. Credential values are passed in a minimal subprocess
environment and are never written to the summary or echoed in commands.

The CI wrapper accepts `phone-full`; the scheduled
`phone-full` lane is non-gating and feeds its JUnit to Test Analytics. The
four-flow `release` profile remains unchanged while quarantined flows mature.

## State and destructive data

Login failures run before successful login. Non-login flows reuse the session
through `ensure_logged_in`; flows requiring a genuinely fresh account state
also clear Keychain. Created entities include `SUITE_RUN_ID` wherever the UI
allows and later mutations target only that run-owned data. Leftovers on the
configured destructive store are not accepted: a destructive runtime selection
requires `--seed`, which initializes a cleanup journal before UI mutation,
discovers only products/orders carrying the exact `SUITE_RUN_ID`, and records
each successful REST deletion. A partial cleanup remains retryable from the
manifest. This mode is the only one requiring consumer credentials.

POS runs require a real-eligible store/account and an iPad simulator. System
surface flows are quarantined separately. Neither profile turns an ineligible
device/store into a passing no-op.

The destructive order-creation flow additionally requires an exact synthetic
existing-customer email. Configure `MAESTRO_WOO_EXISTING_CUSTOMER_SEARCH` as
documented in `env.example`; the runner fails preflight rather than capturing
or persisting a live customer's address.

The lab store used by `phone-full` must be eligible for Inbox. The P2 lists
Inbox as required hub coverage, so an absent `menu-inbox` fails the extended
flow instead of being reported as a feature-gated skip.

Validate traceability and static files with:

```bash
python3 .maestro/scripts/check-smoke-coverage.py
python3 -m unittest discover .maestro/scripts/tests
bash -n .maestro/scripts/*.sh
```

The coverage checker reports full, partial, and manual item counts separately.
A flow-backed partial item must document its exact gap in
`smoke-coverage.yaml`; its existence is not treated as complete P2 coverage.
