# WooCommerce iOS Maestro smoke tests

This simulator-only suite complements XCUITest/WireMock with a production-like
release signal against developer- or CI-supplied live WooCommerce test stores.
It never requires Android's store, POS mocks, an eligibility bypass, REST
consumer keys, a Linear issue, Test Analytics, or a notification channel.

## Local setup

1. Build or locate a Debug or Alpha/prototype `.app`.
2. Copy `env.example` to `.env.local` and fill it locally.
3. Run the linter and doctor without printing values:

```bash
.maestro/scripts/lint-env.py
.maestro/scripts/doctor.sh --app /path/to/WooCommerce.app --profile core
```

The runner derives `APP_ID` from the supplied app, prefers an already booted
compatible simulator, installs the app, generates a unique `SUITE_RUN_ID`, and
stores artifacts under `~/woocommerce-maestro-output/` by default.

## Profiles

```bash
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile core
.maestro/scripts/run-smoke-tests.sh --app /path/to/WooCommerce.app --profile phone-full
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

Each failed flow is retried once. The final directory contains combined JUnit,
self-contained HTML, per-attempt logs, screenshots, hierarchy/debug evidence,
and a redacted JSON summary. Credential values are passed directly to Maestro
and are never written to the summary or echoed in commands.

## State and destructive data

Login failures run before successful login. Non-login flows reuse the session
through `ensure_logged_in`; flows requiring a genuinely fresh account state
also clear Keychain. Created entities include `SUITE_RUN_ID` wherever the UI
allows and later mutations target only that run-owned data. Leftovers on the
configured destructive store are allowed. `--seed` is explicit and is the only
mode that requires optional consumer credentials.

POS runs require a real-eligible store/account and an iPad simulator. System
surface flows are quarantined separately. Neither profile turns an ineligible
device/store into a passing no-op.

The lab store used by `phone-full` must be eligible for Inbox. The P2 lists
Inbox as required hub coverage, so an absent `menu-inbox` fails the extended
flow instead of being reported as a feature-gated skip.

Validate traceability and static files with:

```bash
python3 .maestro/scripts/check-smoke-coverage.py
python3 -m unittest discover .maestro/scripts/tests
bash -n .maestro/scripts/*.sh
```
