# PRD — WOOMOB-3455: Phone POS runs onboarding checks on every transaction

**Status:** Draft. **Empirical conclusion (2026-07-17):** Neither reported symptom reproduces as a functional bug on current trunk. Issue #2 ("runs every transaction") resolved by #17379 (reader now persists). Issue #1 ("runs without card intent") does not block — cash payments complete fine. Remaining is at most a low-priority UX nicety. See §6. **Recommend: de-prioritize or close pending team review.**
**Linear:** [WOOMOB-3455](https://linear.app/a8c/issue/WOOMOB-3455/phone-pos-runs-onboarding-checks-on-every-transaction)
**Assignee:** gabriel.maldonado
**Priority:** Medium · **Labels:** Bug, iOS, source: peacock-backlog

---

## 1. Context & Problem

On **Phone POS** (compact layout, `pointOfSalePhonePrototype` flag), the card-present-payments onboarding/readiness check runs far more often than it should:

1. **No-intent trigger** — the check runs on **every "Checkout" tap**, even when the merchant never intends to use Tap to Pay or a card reader. This can block merchants who don't have WCPay/StripeGateway set up but want to use POS with cash or other payment methods.
2. **Per-transaction re-run** — the check re-runs on **every transaction** instead of once per session. On iPad it does not re-run while a reader stays connected; Phone POS appears to disconnect the reader after each transaction (observed with the simulated reader), which forces the re-check.

Reporter (jirka.malina) reproduced the visible symptom by returning `StripeAccountOverdueRequirements` from the onboarding check. Since the original report (2026-07-07), PR #17379 (rail-based explicit selection) and the "skip overdue requirements" PR have landed, so this PRD reflects analysis against **current trunk**.

## 2. Expected Behavior (from the issue)

1. Onboarding checks should **not run at all** unless the merchant shows intent to use TTP or a card reader.
2. Onboarding checks should run **once**, not on each transaction.

## 3. Current-State Analysis

### Issue #1 — onboarding runs without merchant intent → **STILL PRESENT**
Phone POS fires the TTP pre-connect unconditionally on checkout entry, before any method is chosen:

- `PointOfSaleAggregateModel.checkOut()` → `POSPaymentModel.startPayment()`
  (`Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift:596`; `Controllers/POSPaymentModel.swift:207`)
- In `startPayment()`, `preferredConnectionMethod == .tapToPay` (phone default, `WooCommerce/Classes/POS/TabBar/POSTabCoordinator.swift:301`) → calls `connectTapToPayReader()` and returns (`POSPaymentModel.swift:230-251`).
- `connectTapToPayReader()` → `CardPresentPaymentService.connectReader(using: .tapToPay)` → `createPreflightController()` → onboarding readiness check.
  (`POSPaymentModel.swift:421-457`; `CardPresentPaymentService.swift:99, 341`)

There is **no gating on merchant payment-method intent**. Cash / scan-to-pay / mark-as-paid handlers don't run onboarding themselves, but the pre-connect already fired on checkout entry.

### Issue #2 — runs on every transaction → **MITIGATED, but still reachable**
A guard now skips the redundant disconnect→reconnect→re-check when the TTP reader stays connected:

- `connectTapToPayReader()` early-returns if `cardReaderConnectionStatus == .connected && lastConnectedMethod == .tapToPay` (`POSPaymentModel.swift:438-441`).

But it is defeated by one line — on **any** `.disconnected` event, `lastConnectedMethod` is reset to `nil`:

```swift
// POSPaymentModel.swift:1129-1135
if connectionStatus == .disconnected {
    lastConnectedMethod = nil          // line 1133 — defeats the guard above
    resetTransientCardStateOnDisconnect()
}
```

When the (simulated) reader drops after a transaction, `lastConnectedMethod` becomes `nil`; the next checkout's guard sees `nil != .tapToPay`, forces a real `disconnectReader()` + reconnect, and re-runs onboarding. iPad (regular layout) stays on a persistent reader and never hits the compact rail paths, so it does not recur there.

**Caching does not help:** `CardPresentPaymentsOnboardingUseCase.refreshIfNecessary()` (`CardPresentPaymentsOnboardingUseCase.swift:126`) only short-circuits the network sync when a **completed** state is cached. `checkCardPaymentReadiness()` still re-dispatches `publishCardReaderConnections` and rebuilds subscriptions each call (`CardPresentPaymentsReadinessUseCase.swift:40`), and a fresh preflight controller is created per `connectReader`/`collectPayment` (`CardPresentPaymentService.swift:109, 182`). No "run-once-per-session" guard around the readiness/preflight invocation itself.

### Prime suspects for a fix
- `POSPaymentModel.swift:1133` — `lastConnectedMethod = nil` on every `.disconnected` erases the "reader is still TTP" fact the guards rely on.
- Missing intent gate before `connectTapToPayReader()` in `startPayment()` (`POSPaymentModel.swift:230`).

## 4. Proposed Direction

> Both reported symptoms are resolved/non-reproducing (§6). Nothing here is a required fix; the one item below is optional UX polish.

- **~~Persistence across transactions (Issue #2)~~ — resolved:** the reporter's per-transaction reader disconnect (which drove the re-check) was fixed by [#17379](https://github.com/woocommerce/woocommerce-ios/pull/17379). Runs A and B (§6) confirm the reader now persists and the check runs once. No action needed.
- **~~Blocking cash-only merchants (Issue #1)~~ — disproven:** cash payments complete even with onboarding failing (§6 cash-block test). No block occurs.
- **Optional UX polish (low priority):** auto Tap-to-Pay pre-connect on Checkout is an intentional product & engineering decision — **do NOT defer or gate it.** The only residual nicety is that an onboarding failure during that *silent background* pre-connect can surface an onboarding screen the merchant didn't ask for. If the team wants to tidy this, suppress that screen for the silent pre-connect and present onboarding only on **explicit** card/TTP intent — mirroring how `subscribeToAlwaysOnPaymentEvents` (`POSPaymentModel.swift:1205-1239`) already suppresses *alert* UI for transparent TTP flows. Cosmetic only; not required to close the ticket.

## 5. Open Questions
- **For the team:** de-prioritize or close the ticket, given neither symptom reproduces as a functional bug? (Recommended.)
- **Only if the optional UX polish (§4) is pursued:** how to distinguish the silent background pre-connect from an explicit card/TTP payment request, so the onboarding screen is suppressed only for the former — reusing the transparent-TTP suppression pattern already in `subscribeToAlwaysOnPaymentEvents` (`POSPaymentModel.swift:1205-1239`).

## 6. Testing performed & findings (2026-07-17)

Instrumented the real onboarding-check pipeline (all temporary, `#if DEBUG`, `WOOMOB-3455` markers) and ran on a phone simulator (compact, `pointOfSalePhonePrototype` on, simulated reader):
- `CardPresentPaymentService.createPreflightController(debugSource:)` — logs `preflight built #N (source: connect|collect)` on each controller construction, tagged by call site.
- `CardPresentPaymentOnboardingAdaptor.showOnboardingIfRequired` — logs whether the *actual* check SKIPPED (already in progress) / RAN → ready (no screen) / RAN → not ready (shows screen). This is the true measure; controller construction alone is not.
- `CardPresentPaymentsOnboardingUseCase.refreshIfNecessary()` — `#if DEBUG` forces `state = .stripeAccountOverdueRequirement(plugin: .wcPay)` to reproduce the reporter's *"return StripeAccountOverdueRequirements from the onboarding check"* (also bypasses the cached-`.completed` short-circuit that would mask it).

### Run A — reader connected, onboarding passing (no forced state)
```
preflight built #1 (source: connect)
onboarding check RAN → ready, no screen        ← ran ONCE, at connect
preflight built #2 (source: collect)            ← Order 1: no "check RAN"
preflight built #3 (source: collect)            ← Order 2: no "check RAN"
```
The real onboarding check ran **once** (connect). Both collects built a preflight but short-circuited via `checkForConnectedReader`'s connected-reader early-return (`CardPresentPaymentPreflightController.swift:137-139`) — no re-check. Connect-time checks only fire on an actual connect, not per transaction.

### Run B — overdue requirements FORCED (reporter's scenario)
```
preflight built #1 (source: connect)
onboarding check RAN → not ready, showing onboarding screen   ← ran ONCE, screen shown
preflight built #2 (source: collect)            ← no "check RAN"
preflight built #3 (source: collect)            ← no "check RAN"
```
Even with overdue forced, the check/screen appeared **once** (connect) and did **not** recur on subsequent collects — the reader stayed connected, so collects short-circuited.

### Discovery / conclusion
- **Issue #2 ("runs every transaction") is not reproducible on current trunk.** Its root cause was the reporter's observed *per-transaction reader disconnect* on Phone POS — reader drops after each transaction → next checkout has no connected reader → onboarding check re-runs. [PR #17379](https://github.com/woocommerce/woocommerce-ios/pull/17379) changed the flow so the reader is **not** disconnected unless the merchant explicitly changes their preferred payment method (per gabriel.maldonado's Linear comment). The reader now persists across transactions, so `checkForConnectedReader` short-circuits and the check does not recur. Runs A and B both confirm a single check, not per-transaction.
- **Issue #1 ("runs without card intent") does not block anything.** The onboarding check does run during the auto-TTP pre-connect on Checkout (by design), and with onboarding failing an onboarding screen can appear — but the cash-block test (below) confirms **cash and other payment methods still complete**. The reporter's feared blocking of merchants without WCPay/Stripe setup does **not** occur.
- **Net: neither reported symptom reproduces as a functional bug on current trunk.** What remains is at most a minor UX nicety — showing an onboarding screen during a silent background pre-connect a merchant didn't ask for. Non-blocking, low priority. See §4.

### Cash-block test — DONE: no block
Phone sim, overdue forced, no reader connected → Checkout → **cash payment completes successfully.** The onboarding screen appearing during the silent auto-TTP pre-connect does **not** block cash / other payment methods.

This disproves the reporter's core concern (*"might potentially block users who don't have WCPay/StripeGateway setup"*). The feared blocking behavior does not occur.

### Debug markers currently in the tree (remove for the real fix, on a separate branch)
`git grep -n 3455 -- '*.swift'` — in `CardPresentPaymentService.swift`, `CardPresentPaymentOnboardingAdaptor.swift` (incl. a `CocoaLumberjackSwift` import), and `CardPresentPaymentsOnboardingUseCase.swift`. The first two are already committed as debug-only; the forced-state edit is uncommitted.

## 7. Key References

| Area | File / line |
|------|-------------|
| Checkout entry | `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift:596` |
| Payment start / pre-connect | `Modules/Sources/PointOfSale/Controllers/POSPaymentModel.swift:207, 230-251, 421-457` |
| Disconnect reset (suspect) | `POSPaymentModel.swift:1129-1135` |
| Reader connect / preflight | `WooCommerce/Classes/POS/Adaptors/Card Present Payments/CardPresentPaymentService.swift:99, 176, 341` |
| Onboarding presenter adaptor | `WooCommerce/Classes/POS/Adaptors/Card Present Payments/CardPresentPaymentOnboardingAdaptor.swift:34-46` |
| Readiness use case | `WooCommerce/Classes/ViewModels/Order Details/CardPresentPaymentsReadinessUseCase.swift:40` |
| Onboarding use case / cache | `WooCommerce/Classes/ViewRelated/Dashboard/Settings/In-Person Payments/CardPresentPaymentsOnboardingUseCase.swift:126`; `.../CardPresentPaymentOnboardingStateCache.swift` |
| Phone default method | `WooCommerce/Classes/POS/TabBar/POSTabCoordinator.swift:301` |
| Compact layout gate | `Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift:277` |
| Related PR | #17379 (rail-based explicit selection) |
