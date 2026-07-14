# Maestro iOS implementation contract

This contract freezes the shared interfaces for the seven-branch Maestro stack.
Flow owners may reference these interfaces but must not redefine them.

## App and simulator

- Every flow uses `appId: ${APP_ID}`.
- `run-smoke-tests.sh` requires `--app PATH_TO_APP`, reads `CFBundleIdentifier`
  from that bundle, installs that exact app, and exports the derived value as
  `APP_ID`. Debug is the default build input; Alpha/prototype bundles work
  without a hard-coded identifier.
- `--device` accepts a simulator name or UDID. With no device argument, the
  runner prefers an already booted compatible simulator. `pos-ipad` requires an
  iPad and never degrades to a phone no-op.
- No Maestro invocation passes XCUITest mock or eligibility-bypass launch
  arguments.

## Environment

Normal profiles require only the credentials needed by their selected flows:

```text
MAESTRO_WOO_LAB_JETPACK_STORE_URL
MAESTRO_WOO_LAB_WPCOM_EMAIL
MAESTRO_WOO_LAB_WPCOM_PASSWORD
MAESTRO_WOO_NO_JETPACK_SITE_URL
MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_USERNAME
MAESTRO_WOO_NO_JETPACK_SITE_ADMIN_PASSWORD
MAESTRO_WOO_NOT_A_WOO_STORE_URL
MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_USERNAME
MAESTRO_WOO_NOT_A_WOO_STORE_SITE_ADMIN_PASSWORD
MAESTRO_WOO_WRONG_ACCOUNT_STORE_URL
```

`MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_EMAIL` and
`MAESTRO_WOO_NOT_A_WOO_STORE_WPCOM_PASSWORD` are an optional fallback pair.
Set both when the fixture can route through WP.com, or leave both blank.

`MAESTRO_WOO_CONSUMER_KEY` and `MAESTRO_WOO_CONSUMER_SECRET` are optional and
are validated only when explicit REST seeding or cleanup is requested. Local
runs may load `.maestro/.env.local`; CI injects protected environment variables
and never creates that file. iOS does not require Android's store or account.

The runner generates `SUITE_RUN_ID=SUITE-<UTC timestamp>-<random suffix>` and
passes it to every flow. Created entities use this value wherever the UI permits.

## Runner CLI and profiles

```text
.maestro/scripts/run-smoke-tests.sh --app APP [--profile PROFILE]
  [--device NAME_OR_UDID] [--include-tags CSV] [--exclude-tags CSV]
  [--repeat N] [--rerun-failed JUNIT_XML] [--seed] [FLOW ...]
.maestro/scripts/doctor.sh --app APP [the same profile/device selection]
```

Profiles:

| Profile | Included tags | Excluded tags | Device |
| --- | --- | --- | --- |
| `core` | `smoke_core` | `flaky_quarantine,pos_ipad,ios_system` | iPhone |
| `phone-full` | `smoke_core,smoke_extended,destructive` | `pos_ipad,ios_system` | iPhone |
| `release` | promoted non-quarantined phone flows | `flaky_quarantine,pos_ipad,ios_system` | iPhone |
| `burst` | release, repeated three times | same as release | iPhone |
| `pos-ipad` | `pos_ipad` | none | iPad |
| `ios-system` | `ios_system` | none | iPhone |

Explicit `--include-tags` and `--exclude-tags` override profile tag defaults.
Each failed flow is retried once; both attempts remain in the evidence. Reports
contain JUnit XML, self-contained HTML, screenshots, diagnostics, and a redacted
summary outside the repository.

## Shared files and flow ownership

Only the Core owner edits `.maestro/subflows/`. Shared names are:

- `paste_into_focused_field.yaml`
- `login.yaml`
- `ensure_logged_in.yaml`
- `navigate_to_dashboard.yaml`
- `navigate_to_orders.yaml`
- `navigate_to_products.yaml`
- `navigate_to_more_menu.yaml`

Flow filenames use the Android-equivalent names in the implementation plan.
iOS-only system files are `ios_quick_actions.yaml`,
`ios_notification_long_press.yaml`, `orders_qr_payment.yaml`,
`orders_share_payment_link.yaml`, and `orders_barcode_scanner.yaml`.

Tags are limited to `smoke_core`, `smoke_extended`, `flaky_quarantine`,
`destructive`, `login`, `dashboard`, `orders`, `products`, `hub_menu`,
`pos_ipad`, and `ios_system`.

Coverage IDs come from the committed 88-item P2 snapshot. An ID maps to a flow
only when that flow asserts the complete behavior. Unsupported hardware,
watchOS, migration, real push delivery, external account completion, and camera
decoding remain explicit `manual:` entries. Entry-point-only coverage is not
promoted to a complete mapping.

## Assertion and state rules

- Prefer existing iOS accessibility identifiers; add production identifiers
  only after hierarchy inspection proves a stable selector is absent.
- Main assertions are mandatory, specific, and never wildcard-only.
- A feature-gated item maps to P2 coverage only when the selected profile's
  fixture guarantees eligibility. `hub.inbox` is mandatory for `phone-full`;
  an ineligible store fails the flow instead of emitting a passing skip.
- Login-reset flows clear application state and Keychain. Non-login flows call
  `ensure_logged_in` and preserve authenticated state.
- Credentials and long values use `paste_into_focused_field.yaml`; sensitive
  clipboard contents are cleared immediately.
- Destructive flows create or identify only run-owned entities, verify persisted
  state, and permit documented leftovers. Cleanup is optional.
