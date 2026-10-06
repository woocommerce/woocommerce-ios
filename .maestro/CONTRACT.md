# Maestro iOS implementation contract

This contract freezes the shared interfaces for the eight-PR Maestro integration
stack. Flow owners may reference these interfaces but must not redefine them.

## App and simulator

- Every flow uses `appId: ${APP_ID}`.
- `run-smoke-tests.sh` takes `--app PATH_TO_APP`, found automatically when exactly
  one built app exists, reads `CFBundleIdentifier` from that bundle, installs that
  exact app, and exports the derived value as
  `APP_ID`. Debug is the default build input; Alpha/prototype bundles work
  without a hard-coded identifier.
- `--device` accepts a simulator name or UDID. With no device argument, the
  runner prefers an already booted compatible simulator. `pos-ipad` requires an
  iPad and never degrades to a phone no-op.
- Flows launch the app with `-ui_testing`, which turns off analytics and skips the
  privacy banner and login onboarding. No Maestro invocation passes XCUITest mock
  arguments.
- The runner passes `NOTIFICATIONS=deny`, and `login.yaml` has Maestro answer the
  app's notification prompt with it, so no notification banner can take a tap.
  Before the notification flow, the runner signs in again with
  `NOTIFICATIONS=allow`.
- From iOS 26 the app asks the system for the user's age range at every launch
  while signed in, which on the simulator drops taps for about a second. On those
  runtimes the runner passes `AGE_RANGE_CHECK=true`, and
  `wait_for_age_range_check.yaml` waits for the request after each launch.

## Environment

Normal profiles require only the credentials needed by their selected flows:

```text
MAESTRO_WOO_LAB_JETPACK_STORE_URL
MAESTRO_WOO_LAB_WPCOM_EMAIL
MAESTRO_WOO_LAB_WPCOM_PASSWORD
MAESTRO_WOO_SHARED_JETPACK_STORE_URL
MAESTRO_WOO_SHARED_WPCOM_EMAIL
MAESTRO_WOO_SHARED_WPCOM_PASSWORD
MAESTRO_WOO_NO_JETPACK_SITE_URL
MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_USERNAME
MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_PASSWORD
MAESTRO_WOO_NOT_A_WOO_STORE_URL
MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_USERNAME
MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_PASSWORD
MAESTRO_WOO_WRONG_ACCOUNT_STORE_URL
```

`MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL` and
`MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_PASSWORD` are required for wordpress.com-hosted
fixtures and optional for self-hosted fixtures. Set both or leave both blank.
The runner removes a trailing `/wp-admin` or `/wp-admin/` from the no-Jetpack
site URL before passing it to the app.

Variables written by store-setup tooling (`MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_USERNAME`
and `MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_PASSWORD`) are never required by a flow and are
never forwarded to Maestro; they exist so a provisioned store can be reconfigured later.

`MAESTRO_WOO_LAB_CONSUMER_KEY`, `MAESTRO_WOO_LAB_CONSUMER_SECRET`,
`MAESTRO_WOO_LAB_JETPACK_SITE_ADMIN_USERNAME` and `MAESTRO_WOO_LAB_APPLICATION_PASSWORD`
are required with `--seed`, which destructive flows need, and are checked before
any flow runs. Runs
may load `.maestro/.env.local`. iOS does not require Android's store or account.

The runner generates `SUITE_RUN_ID=SUITE-<UTC timestamp>-<random suffix>` and
passes it to every flow. Created entities use this value wherever the UI permits.

## Runner CLI and profiles

```text
.maestro/scripts/run-smoke-tests.sh --app APP [--profile PROFILE]
  [--device NAME_OR_UDID] [--store lab|shared] [--include-tags CSV]
  [--exclude-tags CSV] [--repeat N] [--rerun-failed JUNIT_XML] [--seed] [FLOW ...]
.maestro/scripts/doctor.sh --app APP [the same profile/device selection]
```

Profiles:

| Profile | Included tags | Excluded tags | Device |
| --- | --- | --- | --- |
| `core` | `smoke_core` | `flaky_quarantine,pos_ipad,ios_system` | iPhone |
| `phone-full` | `smoke_core,smoke_extended,destructive` | `pos_ipad,ios_system` | iPhone |
| `pos-ipad` | `pos_ipad` | none | iPad |
| `ios-system` | `ios_system` | none | iPhone |

Explicit `--include-tags` and `--exclude-tags` override profile tag defaults.
Each failed non-destructive flow is retried once; both attempts remain in the
evidence. Reports
contain JUnit XML, self-contained HTML, screenshots, diagnostics, and a redacted
summary outside the repository.

## Shared files and flow ownership

Only the Core owner edits `.maestro/subflows/`. Shared names are:

- `paste_into_focused_field.yaml`
- `open_site_address_login.yaml`
- `dismiss_save_password_prompt.yaml`
- `login.yaml`
- `ensure_logged_in.yaml`
- `navigate_to_dashboard.yaml`
- `navigate_to_orders.yaml`
- `navigate_to_products.yaml`
- `navigate_to_more_menu.yaml`
- `wait_for_age_range_check.yaml`

Flow filenames use the Android-equivalent names in the implementation plan.
iOS-only system files are `ios_quick_actions.yaml`,
`ios_notification_long_press.yaml`, `orders_qr_payment.yaml`,
`orders_share_payment_link.yaml`, and `orders_barcode_scanner.yaml`.

Tags are limited to `smoke_core`, `smoke_extended`, `flaky_quarantine`,
`destructive`, `login`, `dashboard`, `orders`, `products`, `hub_menu`,
`pos_ipad`, `ios_system`, and `store_shared`. A `store_shared` flow runs against
the shared store and is never `destructive`.

Coverage IDs come from the committed 98-item P2 snapshot. Flow-backed items
default to `fidelity: full`. A partial or entry-point-only implementation uses
`fidelity: partial` plus a concrete `gap:` and is counted separately from full
automation. Unsupported hardware, watchOS, migration, real push delivery,
external account completion, and camera decoding remain explicit `manual:`
entries.

## Assertion and state rules

- Prefer existing iOS accessibility identifiers; add production identifiers
  only after hierarchy inspection proves a stable selector is absent.
- `point:` selectors require an inline YAML comment explaining why no
  identifier or text selector exists.
- Main assertions are mandatory, specific, and never wildcard-only.
- A feature-gated item maps to P2 coverage only when the selected profile's
  fixture guarantees eligibility. `hub.inbox`, `hub.blaze.create`,
  `hub.google-for-woo` and the `hub.payments` card-reader rows are mandatory
  for `phone-full`; an ineligible store fails the flow instead of emitting a
  passing skip.
- Login-reset flows clear application state and Keychain. Non-login flows call
  `ensure_logged_in` and preserve authenticated state.
- Flows share one session, so a flow restores any shared state it changes,
  such as a product filter or sort order, before it ends.
- Credentials and long values use `paste_into_focused_field.yaml`; sensitive
  clipboard contents are cleared immediately.
- Destructive flows create or identify only run-owned entities, verify persisted
  state, and run with `--seed`, whose cleanup deletes those entities afterwards.
