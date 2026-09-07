# Age Verification

## Overview

The app complies with Texas SB2420 age-verification requirements using two Apple frameworks:

- **Declared Age Range** tells the app which age band the signed-in Apple Account falls into (relative to the age gates the app requests), and whether the account requires parental approval for significant app changes.
- **PermissionKit** delivers a consent question to the account's parent/guardian and streams their answer back, possibly much later or after a relaunch.

Two principles shape every decision below:

- **Zero geography.** The app hardcodes no regions or jurisdictions. Apple's per-account flags (`isComplianceRequired`, `significantAppChangeApprovalRequired`) decide whether any of this applies to a given account. The same binary behaves identically everywhere; only the account's flags differ.
- **Only affirmative signals restrict.** Access is restricted or denied only on a definitive signal: a declared age band below the minimum, or an explicit pending/denied consent. Anything transient or unavailable (SDK errors, declined sharing, unsupported OS, missing UI anchor, PermissionKit unavailable) fails open.

The flow runs after login, from `AppCoordinator`, and re-runs on every foreground while a consent blocker is on screen.

## File map

`WooCommerce/Classes/Tools/AgeVerification/`

| File | Role |
|---|---|
| `AgeRangeVerificationService.swift` | Fetches the regulatory requirements, requests the declared age range (two gates: 13 and 18) and maps the snapshot to an `AgeRangeVerificationResult`. |
| `AgeRangeProvider.swift` | Thin wrapper around the Declared Age Range framework. |
| `AgeRatingProvider.swift` / `AgeRatingChangeDetector.swift` / `AgeRatingChangeDetecting.swift` | Reads the app's current App Store age rating and reports an unacknowledged rating increase (non-consuming until explicitly acknowledged). |
| `SignificantChangeConsentProvider.swift` | PermissionKit wrapper: `requestConsent` sends the question, `responses()` streams answers. |
| `SignificantChangeConsentStore.swift` | `SignificantChangeIdentifier` (`.ageRatingChange(ratingCode:)` auto-detected, `.manual(id:)` developer-declared, plus the persisted cache key format) and the UserDefaults persistence of per-change statuses (`granted`/`denied`/`pending`) and the single pending-question slot. |
| `CurrentSignificantChange.swift` | The one well-known place to declare a real manual significant change for a release, with its parent-facing copy. |
| `DebugAgeVerificationOverrides.swift` | Debug Panel override (manual change id). Inert in release builds and while unit tests run. |

`WooCommerce/Classes/ViewRelated/AgeGate/`

| File | Role |
|---|---|
| `AgeRangeVerificationCoordinator.swift` | Runs the age gate post-login, serializes concurrent triggers and maps outcomes to an `AppAccessDecision` (`allow` / `allowConsentGranted` / `denyAndLogout` / `restrictConsentRequired` / `restrictPendingConsent` / `restrictDeniedConsent`). |
| `SignificantChangeConsentCoordinator.swift` | Consent state machine (`notRequired` / `required` / `granted` / `pending` / `denied` / `notAvailable`). `checkConsentIfNeeded` is read-only; `requestConsent` sends the question only on explicit user action and waits a 2 s grace window for instant answers; one long-lived listener resolves answers arriving later, matched by question UUID against the persisted pending request. |
| `SignificantChangeConsentBlockingView.swift` | Full-screen recoverable blocker with the `approvalNeeded` / `pendingApproval` / `approvalDenied` / `approvalGranted` contexts, one action button each. Presented, updated and dismissed by `AppCoordinator`. |

## Decision matrix

| # | Situation | Decision |
|---|---|---|
| 1 | Feature flag off | Allow |
| 2 | Account not under a covered regime (compliance not required) | Allow, no age prompt at all |
| 3 | Declared range below 13 (upper bound < 13) | Log out + "Access Restricted" alert |
| 4 | Eligible (13+), not a minor | Allow |
| 5 | Eligible minor (upper bound < 18), approval flag not set | Allow |
| 6 | Eligible minor + approval flag, no unacknowledged significant change | Allow |
| 7 | …+ change present, consent never requested | "Approval Needed" wall (Request Approval); no logout |
| 8 | …consent requested, unanswered | "Approval Requested" wall (Check Again) |
| 9 | …consent denied | "Approval Declined" wall (Ask Again); survives relaunch; no logout |
| 10 | …consent granted while wall shown | "Approval Granted" confirmation (Continue), then access; change acknowledged |
| 11 | …consent granted (cached, later launches) | Allow |
| 12 | PermissionKit unavailable / send failed | Allow |
| 13 | Declined age sharing, SDK unavailable/error, unknown result, invalid UI state | Allow |
| 14 | Minor status evidence | Requires a declared upper bound < 18 (two age gates requested: 13 and 18); the adult band and bandless responses are non-minor |
| 15 | Blocker dismissal | Only an authoritative eligible outcome dismisses it; transient fail-open results never do |

Notes on the matrix:

- Rows 7–11 apply to the single change currently in effect. A declared manual change takes precedence over a detected age rating change for as long as the declaration exists in `CurrentSignificantChange.swift`, even after its consent is `granted`. Approving the manual change does not acknowledge a concurrent rating change; that one stays outstanding but is masked until the declaration is removed in a later release, and is evaluated on the next launch after that.
- Row 10: "change acknowledged" means the age rating change detector caches the approved rating so it stops reporting it. Manual changes are acknowledged implicitly by their persisted `granted` status.
- Row 12 covers both `checkConsentIfNeeded` returning `notAvailable` and a failed or unavailable `requestConsent` from the wall. Nothing is persisted in either case, so the gate re-evaluates on the next launch.
- Consent requests are never sent automatically. The only sender is the wall's Request Approval / Ask Again button.

## Policy sources

- P2 decision comment: https://automattlock.wordpress.com/2026/07/24/tx-age-verification-implementation-woo-tumblr-and-next-steps/#comment-27586
- Ticket: WOOMOB-3727
- Implementation PR: https://github.com/woocommerce/woocommerce-ios/pull/17822

## Declaring a real significant change

A "significant change" without an age rating impact (for example new Terms of Service or a new data practice) is declared by editing one file: `WooCommerce/Classes/Tools/AgeVerification/CurrentSignificantChange.swift`. Set `CurrentSignificantChange.declaration` to a `SignificantChangeDeclaration` with:

- `id`: a new, stable identifier (consent outcomes are persisted per id; reusing an old id replays its previous answer).
- `parentDescription`: the short, plain summary Apple shows inside the consent request the parent/guardian receives. Use an `NSLocalizedString` literal with the key `significantChange.<id>.parentDescription`.
- `blockerMessage`: the longer explanation shown on the in-app "Approval Needed" screen. Use an `NSLocalizedString` literal with the key `significantChange.<id>.blockerMessage`.

Both texts are required by construction, so a change cannot be declared without parent-facing copy. Legal drives the trigger: a change is declared only when Legal determines it is significant under the applicable rules. Plan for one release cycle of lead time so the copy can be reviewed and localized before the release that carries the declaration ships. Remove the declaration in a later release once the change has shipped and consent for it has had time to be collected.

## Debug tooling

Menu → Settings → Debug Panel → "Age Verification" (DEBUG and ALPHA builds only; every override is inert while unit tests run).

- **Manual significant change ID**: a non-empty id is treated as an undeclared manual significant change on the next age verification (relaunch or re-login). The field saves as you type; there is no Save button. A debug id takes precedence over `CurrentSignificantChange.declaration`, and its consent request uses an unlocalized placeholder description that only exists in DEBUG/ALPHA builds.
- **Reset significant change consent state**: clears every persisted consent status, the pending question and the acknowledged age rating cache. Tap it before every test scenario.
- **Sandbox testing entry point**: on a physical device with a sandbox Apple Account, iOS Settings → Developer → Sandbox Apple Account → Manage → Age Assurance lets you pick the age band and the parent's answer (approved/declined) that the sandbox returns. The sandbox answers instantly, so the "Approval Requested" wall is only reachable with a real supervised account. The SDKs do not work on the simulator.
