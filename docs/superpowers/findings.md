# Phone POS Implementation Findings

Noteworthy architectural discoveries and changes made during implementation.

**Last updated:** 2026-03-16

---

## 1. POSPaymentModel assumes Bluetooth throughout

The `POSPaymentModel` hardcoded `.bluetooth` as the connection method in three places: `collectPayment`, `connectReader`, and the reader reconnection observer. For Tap to Pay on phone, we introduced a `connectionMethod` property (defaulting to `.bluetooth`) that's injected via `PointOfSaleAggregateModel` from the entry point based on device idiom.

**Key behavioral difference:** Bluetooth readers stay connected and auto-reconnect. Tap to Pay connects on demand per payment. This meant the reconnection observer (`observeReaderReconnection`) — which calls `startPayment()` when a Bluetooth reader disconnects — had to be skipped entirely for Tap to Pay. Without this, entering the checkout screen would immediately trigger the Tap to Pay system UI.

## 2. checkOut() couples order sync with payment start

`PointOfSaleAggregateModel.checkOut()` both syncs the order AND calls `paymentModel.startPayment()`. On iPad this is fine — the reader is already connected and payment can start immediately. On phone, the user needs to review the cart and explicitly tap a payment button.

We added `prepareCheckout()` which syncs the order and transitions to `.finalizing` without starting payment. The phone cart peek calls this instead of `checkOut()`.

## 3. POS modal system requires explicit setup on new presentation contexts

`.posModal` requires three environment objects (`POSModalManager`, `POSSheetManager`, `POSFullScreenCoverManager`) and a `posRootModal()` modifier at the root. SwiftUI's `.fullScreenCover` creates a new environment scope, so these don't propagate from the parent.

Using `.posFullScreenCover` (the POS-specific modifier) handles all of this automatically — it creates fresh manager instances and applies `posRootModal()`. This was needed for the checkout view to show payment alerts (location permission, reader scanning).

## 4. .sheet covers the tab bar

A SwiftUI `.sheet` presented from within a tab covers the entire window including the tab bar, even at a small detent. The original plan used a sheet with custom detents for the collapsed cart peek. We switched to `safeAreaInset(edge: .bottom)` for the cart peek bar (which sits above the tab bar naturally) and a regular dismissible `.sheet` only when the user expands to the full cart.
