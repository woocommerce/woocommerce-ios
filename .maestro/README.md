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

The selected simulator's first Preferred Language must be English (`en`, with
any region). The doctor and runner fail before app installation or Maestro
execution when another language is primary; they never change simulator
settings automatically. The side-effect-free doctor does not boot a simulator,
so boot the selected device before using it to validate language settings.

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

Each failed non-destructive flow is retried once. A pass on retry is reported as
a passing flaky result: it does not fail the runner or JUnit, but remains visible
in reports and selectable through `--rerun-failed`. Destructive mutation failures
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
