# QR Login — Decision Log

Running log of non-obvious choices made while implementing the QR-login feature
on `feature/qr-login`. Reviewable by the maintainer before splitting into PRs.
Updated as each layer lands.

This file is on the feature branch only and **must not** be merged into `trunk`.
It's a temporary aid for the PR-splitting phase; delete it before the final
merge.

---

## Layer 2 — Networking layer

### URLSession-direct Remotes (vs. `Network` abstraction)

The QR-login Remotes don't extend `Remote` and don't go through
`AlamofireNetwork`. They take a `URLSession` directly and call
`session.data(for:)`.

**Why:** The spec error tables branch on HTTP status (`401` vs `403` vs `404`
vs `412` vs `426` vs `429`), and `Network.responseData(for:completion:)` doesn't
expose `HTTPURLResponse.statusCode` to the caller. Alamofire validates and
discards the raw response.

**Precedent:** Same pattern is used by `SiteCredentialLoginUseCase`,
`OneTimeApplicationPasswordUseCase`, and the vendored
`WordPressComRestApi`. So this matches the codebase, not a new invention.

**Tested via:** `QRLoginStubURLProtocol` — a small `URLProtocol` subclass that
stubs status code + body + transport failures. Mirrors the existing
`MockURLProtocol` shape but adds raw `Data` bodies + simulated `URLError`s
(needed for the 4-strike polling threshold tests).

### `QRLoginStore` is a `DeauthenticatedStore`

QR-login is a logged-out flow, so the store joins `AccountCreationStore` /
`WordPressSiteStore` in `DeauthenticatedState` instead of `AuthenticatedState`.
WP.com OAuth credentials come from `ApiCredentials` at registration time,
matching how `AccountCreationStore` already gets them.

### Body-code-aware error type

`QRLoginNetworkError` carries optional `code: String?` for `.preconditionFailed`,
`.internalServerError`, and `.badRequest` so the mapper can disambiguate:
- 412 `qr_login_not_approved` → "Sign-in timed out"
- 412 `invalid_exchange_grant` → "Sign-in interrupted"
- 500 `already_consumed` → "Already signed in elsewhere" (wp.com only)
- 400 `no_number_matching` → captured but should be unreachable per §5.2.1

Body parsing uses the WordPress REST envelope (`{ "code": "...", "message":
"..." }`) — same shape `WordPressApiValidator` already handles.

### WP.com poll 404 → expired (handled in the Remote, not the mapper)

Per spec §5.2.2 the wp.com poll's 404 is coerced to a `.expired` terminal
state rather than surfaced as an error. `WPComQRLoginRemote.pollSessionStatus`
catches `.notFound` and returns a synthetic `QRLoginSessionStatus(state:
.expired, exchangeGrant: nil)`. The mapper doesn't need to know about it.

### Polling loop is in Yosemite, not Networking

`QRLoginPollingLoop` lives under `Modules/Sources/Yosemite/Tools/QRLogin/`
because it composes a Remote method call with phase + protocol-aware error
mapping. The Networking layer stays focused on raw HTTP shape.

---

## Layer 3 — Strategy + orchestration view model

### Two protocol-specific strategies under one protocol

`QRLoginStrategy` is the seam between the view model and the protocols. Two
implementations: `SelfHostedQRLoginStrategy` and `WPComQRLoginStrategy`. Each
caches `sessionID` / `tokenHash` after a successful scan and (for wp.com)
`exchangeResponse` after a successful exchange — so the retry-at-each-phase
semantics from §6.1 don't re-run earlier work.

### Strategy holds `protocol_` for error mapping

Rather than embedding protocol awareness in the view model or pushing it
through the polling loop, the strategy carries `protocol_` and the loop
forwards it to `QRLoginErrorMapper`. Keeps protocol identity in exactly one
place.

### Magic-link opener as injected closure (Layer 3 default is a logging stub)

`WPComQRLoginStrategy` takes a `QRLoginMagicLinkOpener` closure at
construction. The default opener just logs — Layer 6 (the coordinator)
provides the real `SFSafariViewController` implementation. Keeps the strategy
free of `UIApplication` / UIKit imports.

### Polling-loop sleeper indirection wins us deterministic tests

`QRLoginPollingLoop` already accepted an injected sleeper; the view model
just passes the configured `pollIntervalSeconds`. Tests in Layer 3 pass `0`
which makes scenarios run in microseconds, including the 4-strike threshold
scenario.

### Analytics façade pins `flow = login_qr` in one place

`QRLoginAnalyticsTracking` is a thin façade around
`AuthenticatorAnalyticsTracker`. The view model's init calls `setFlow(.loginQR)`
once. `failureString(for:)` (in QRLoginAnalyticsFailure) maps a
`QRLoginUserFacingError` to the spec §9.3 string (e.g. `Network:Scan`,
`UserNotEligible:Auth`) so iOS and Android emit identical values.

---

## Layer 4 — Self-hosted post-exchange

### Reuses existing primitives instead of `PostSiteCredentialLoginChecker`

`PostSiteCredentialLoginChecker` is too UI-coupled (presents alerts, pushes
view controllers, handles AP generation via password sniffing). The QR-login
post-exchange is in pure data territory — AP comes from the network, not
from user input. We build our own `QRLoginPostExchangeService` that reuses
the same lower-level primitives:

  - `Credentials.applicationPassword(...)` + `stores.authenticate(...)` —
    sets the session to AP-authenticated.
  - `WordPressSiteAction.fetchSiteInfo` — same site-fetch path
    `PostSiteCredentialLoginChecker.checkWooInstallation` uses (lines 132–155).
  - `RoleEligibilityUseCase` — invoked with `WooConstants.placeholderStoreID`,
    matching `PostSiteCredentialLoginChecker.checkRoleEligibility` (line 87).
  - `OneTimeApplicationPasswordUseCase` — already the right shape: takes an
    `ApplicationPassword` + `siteAddress`, persists locally on init, and
    `deletePassword(locally: true)` revokes server-side AND clears storage.
    UUID it accepts is a placeholder — the use case looks up the real one
    on delete via the introspection endpoint.

### AP UUID is a generated UUID, not from server

The QR-login exchange response carries the AP password but **not** the AP
UUID. `OneTimeApplicationPasswordUseCase` accepts the AP at construction
without a real UUID and looks it up on revoke via the WP `application-passwords/introspect`
endpoint. We pass a fresh `UUID()` to satisfy the struct contract; it's
never used.

### `.signedIn` analytics event fires on success path only

Matches `AuthenticationManager.checkSiteCredentialLogin` (line 838) —
`.signedIn` is tracked only after all post-exchange checks pass so dashboards
measure users who can actually use the app. Failures (woo-missing,
eligibility-failed, site-auth) don't emit `.signedIn`.

### Failure path always revokes AP + deauthenticates

Per spec §6.3: "Any post-exchange failure — both the 'not a WooCommerce
store' check and the eligibility check (including cancellation during
eligibility) — MUST revoke the just-minted AP server-side and run a full
logout before the error screen is shown." A single private `fail(_:useCase:)`
helper does both, returning the user-facing variant. `deletePassword(locally:
true)` is wrapped in `try?` so the UI still surfaces the original error if
revoke itself fails — leaving an orphan AP is recoverable, leaving the user
in a confusing UI state is not.

---

## Layer 5 — UI surface

### Prologue intercept lives inside `authenticationUI()`, not WPA

I considered modifying the vendored `LoginPrologueViewController` to ask the
delegate for an override view controller on the primary CTA tap. Switched to
intercepting at `AuthenticationManager.authenticationUI()` because:

  - It's outside the WPA module — fewer files touched, smaller blast radius.
  - The full QR experience replaces the WPA prologue entirely when the
    feature is on, matching the spec §4.1 wireframe more closely than a
    "WPA prologue with a third button" approach.
  - The fallback CTA ("No computer? Log in with site address") pushes
    `SiteAddressViewController` onto the same nav stack via
    `NavigateToEnterSite`, so the user never sees the WPA prologue. Matches
    the spec.

### Sync availability check uses debug override only

`QRLoginAvailability.isAvailableForPrologueSync()` returns `true` only when
the debug override is on. The cached-remote-flag path is async (Yosemite
`FeatureFlagAction.isRemoteFeatureFlagEnabled`) and `authenticationUI()` is
sync. For the verification phase the debug override is enough; the
production async-cache path is a polish-phase follow-up — the spec already
mandates "null / not-yet-loaded → off" so the worst case is the QR prologue
is hidden until the cache is warmed and the app restarts.

### `QRLoginViewModel` is `@Observable` (Swift 5.9+)

Matches `.claude/rules/architecture.md` ("Prefer Observation framework with
@Observable for new view models"). Tests use `await waitForState(...)` with
a small poll loop instead of `withObservationTracking` for the lifecycle
tests — the SUT runs through several state transitions in a single test, so
checking inside `onChange` would create a re-entrancy hazard. The 1ms poll
yields immediately if the predicate already matches.

### Help & Support hookup

The Help button routes through a new `onShowHelp` coordinator callback to
`AuthenticationManager.presentSupport(from:sourceTag:siteURL:)`. A
dedicated `WordPressSupportSourceTag.loginWithQRCode`
(`origin:login-with-qr-code`) was added for origin parity with Android's
`LOGIN_WITH_QR_CODE` (spec §4.1).

### `Color(.accent)` / `Color(uiColor: .brand)` for tinting

Uses the existing semantic colors from `WooFoundation/Colors/`
(`UIColor+SemanticColors.swift`) — accent for the primary CTA, brand for
the prologue's qrcode icon. Matches how other SwiftUI views in the app
tint controls.

---

## Layer 6 — WP.com magic-link, non-protocol payloads, deep link

### Magic-link handoff via `WebviewHelper.launch`

`WPComQRLoginStrategy` injects a `QRLoginMagicLinkOpener` closure provided
by `QRLoginCoordinator.openMagicLink`. The opener uses
`WebviewHelper.launch(url, with: topVC)` — same `SFSafariViewController`
plumbing the existing magic-link UI uses. WP.com 3xx-redirects to
`woocommerce://magic-login`, picked up by the existing handler in
`AuthenticationManager.handleAuthenticationUrl`.

### Non-protocol payloads land at the coordinator's payload handler

`QRLoginCoordinator.handleScanned(payload:)` switches on every
`QRLoginPayload` variant:
  - `.selfHosted`, `.wpCom` → live flow
  - `.magicLink(url)` → in-app browser handoff (same as wp.com success edge)
  - `.siteURLOnly(url)` → push WPA site-address screen
  - `.appLoginWPCom(siteURL, email)` → push WPA WP.com email/password screen
  - `.appLoginUsername(siteURL, username)` → push WPA site-credentials screen
  - `.installQR` → "That's the install QR" error variant
  - `.invalid` → "Not a WooCommerce code" error variant

Site-address prefill (§10.2): `.siteURLOnly` pushes WPA's site-address
screen via `NavigateToEnterSite(loginFields:autoSubmitsPrefilledSiteAddress:)`
— the screen is pre-filled and auto-submits once on first appearance.
`NavigateToEnterSite` also gained a `(from as? UINavigationController)`
fallback so it works when handed a navigation controller directly; it
previously no-op'd, which had quietly broken the QR-login "Enter site
URL" fallbacks.

### `woocommerce://qr-login` deep-link entry handled in `AuthenticationManager`

`isQRLoginUrl(_:)` matches the deep link by lowercased URL prefix
(`WooConstants.qrLoginURLPrefix`) rather than `URL.host`, which is
unreliable for custom-scheme URLs across Foundation versions. The
deep-link sync check uses `QRLoginAvailability.deepLinkSyncOverride()`
which only checks the override — no camera, no bucket — matching spec
§2.2. The URL is parsed via `QRLoginPayloadParser`.

**Coordinator reuse (not a second coordinator).** Displaying the
authenticator (`displayAuthenticatorIfLoggedOut`) can itself start a
`QRLoginCoordinator`: when the QR-login prologue is available,
`authenticationUI()` returns `makeQRLoginUI()`, which builds and starts
a `.camera` coordinator. So `handleQRLoginUrl` must **not** start a
second one — it reuses that coordinator via `presentDeepLink(payload:)`,
and only starts a standalone `.deepLink` coordinator when the legacy
login UI is the root (the prologue isn't available). Starting two
coordinators orphaned the first (its `qrLoginCoordinator` reference was
overwritten) and left a dead prologue underneath the number-match
screen. The shared construction lives in
`makeQRLoginCoordinator(mode:navigationController:)`.

This surfaced during simulator verification once the prologue became
reachable on the simulator — see the camera-availability change in
`QRLoginAvailability.defaultCameraAvailability()`.

### Session-replace warning

Spec §4.4: a `woocommerce://qr-login` deep link arriving while signed in
now presents a "You're already signed in" warning
(`QRLoginSessionReplaceView`), reached via
`AuthenticationManager.handleSignedInQRLoginDeepLink` from the
`AppDelegate.handleAuthenticationUrl` signed-in branch. Confirming runs
`ServiceLocator.stores.deauthenticate()` and resumes the deep link on the
logged-out path; cancelling keeps the current session.

The resume is deferred one run-loop tick (`DispatchQueue.main.async`)
rather than run synchronously: `deauthenticate()` triggers `AppCoordinator`'s
Combine sink to swap in the logged-out login UI, and re-handling the URL
synchronously would race that swap. iOS `deauthenticate()` is best-effort
local teardown with no failure path, so the resume is unconditional.

---

## Simulator verification — partial

The verification phase ran into a pre-existing build issue on this
checkout: `WatchWidgetsExtension` fails to compile because two `Color(.brand)`
/ `Color(.accent)` references in `WooCommerce/StoreWidgets/Homescreen/View+ContainerBackground.swift`
and `WooCommerce/StoreWidgets/StoreWidgetTheme.swift` reference
`ColorResource` values that the `WatchWidgetsExtension` asset catalog
doesn't generate. The files are unchanged on this branch (`git diff trunk
-- ...` is empty), so this is environment-specific. I attempted to add
the missing `brand` / `accent` colorsets to both `WatchWidgetsExtension/Assets.xcassets`
and `StoreWidgets/Assets.xcassets` but `actool` for `WatchWidgetsExtension`
didn't generate the matching `GeneratedAssetSymbols.swift` — likely a
target-level `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
setting issue, or stale DerivedData. Investigating further would have
been more useful as a separate change.

The screenshots in `screenshots/` are from the binary built earlier in
this session (timestamp May 19 13:45) which **predates Layer 5 and 6** —
it has the parser, networking, and Yosemite store but neither the QR
prologue UI nor the deep-link handler. The screenshots show what the app
looks like *without* QR-login active (existing onboarding + WPA prologue
+ standard "Log In" site-address screen), plus one screenshot of the iOS
"Open in Woo (Dev)?" confirmation dialog when sending the deep link.

To run the live verification, the maintainer should:
1. Fix the WatchWidgets asset issue (or do a clean DerivedData rebuild on
   a fresh machine — the issue may be cache corruption local to this
   environment).
2. Build the WooCommerce target.
3. Install on the simulator: `xcrun simctl install booted <path>/WooCommerce.app`.
4. Enable the override: `xcrun simctl spawn booted defaults write com.automattic.woocommerce "com.woocommerce.featureflag.override.remote.qrCodeLogin" -bool YES`.
5. To unblock the camera check on simulator (the spec gates the prologue
   on `AVCaptureDevice.default(for: .video) != nil` which is `nil` on
   simulator), either edit `QRLoginAvailability.defaultCameraAvailability()`
   to return `true` on `#if targetEnvironment(simulator)`, or use the
   deep-link entry which bypasses the camera check.
6. Launch the app and either tap "Log In" (for the prologue) or send
   `xcrun simctl openurl booted 'woocommerce://qr-login?token=<64+a's>&siteUrl=https://example.com'`.

Mock server fixtures for the QR endpoints would land in
`Modules/Sources/APIMocks/Resources/` alongside the existing WireMock
mappings — those are also a polish-phase follow-up.
