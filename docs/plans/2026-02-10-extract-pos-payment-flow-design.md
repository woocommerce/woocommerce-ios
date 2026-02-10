# Extract POS Payment Flow for Reuse

## Problem

The POS payment flow (card reader connection, card payment, cash payment, receipt) is embedded in `PointOfSaleAggregateModel`. Bookings needs the same payment experience from the "Collect Payment" button on booking details, and future features will also need to trigger payments. We need to extract the payment flow into a reusable component without risking the existing cart payment flow.

## Decision: Shared POSPaymentController + Configuration Struct

Extract all payment logic from `PointOfSaleAggregateModel` into a shared `POSPaymentController`. The aggregate model becomes a thin wrapper. Bookings (and future callers) create their own `POSPaymentController` instance with different dependencies. A `POSPaymentFlowConfiguration` struct handles view-level differences.

---

## POSPaymentController

`@Observable` class that owns all payment state and logic.

### State (published to views)

- `paymentState: PointOfSalePaymentState` (card + cash sub-states)
- `cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?`
- `cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?`
- `cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus`

### Dependencies (injected at init)

- `cardPresentPaymentService: CardPresentPaymentFacade` -- reader connection + card collection
- `orderProvider: POSPaymentOrderProviding` -- async function returning the `Order` to pay against
- `cashPaymentHandler: POSCashPaymentHandling` -- marks order completed with cash
- `postPaymentStep: (() async throws -> Void)?` -- runs after payment success, before showing success UI (e.g. mark booking as paid)
- `configuration: POSPaymentFlowConfiguration` -- view-level differences
- `analytics: POSAnalyticsProviding`

### Methods

- `startPayment()` -- entry point; if reader connected, collect immediately; otherwise subscribe and collect on connect
- `collectCardPayment()` -- fetches order via `orderProvider`, collects via card payment service
- `cancelThenCollectPayment()` -- cancels current attempt, re-initiates
- `startCashPayment()` -- cancels card payment, transitions to cash collection
- `cancelCashPayment()` -- resets to idle, resumes card if reader connected
- `collectCashPayment(changeDueAmount:)` -- calls `cashPaymentHandler`, then `postPaymentStep`
- `sendReceipt(to:)` -- sends receipt email via `receiptSender`
- `reset()` -- clears all state to idle
- `connectCardReader()` / `disconnectCardReader()` -- pass-throughs to card payment service

### Combine Subscriptions (set up at init, moved verbatim from aggregate model)

1. Payment events -> alert view model (modal alerts for reader connection)
2. Payment events -> inline message (payment status in the totals view)
3. Payment events -> card payment state (drives `paymentState.card`)
4. Payment events -> onboarding view (card reader setup)
5. Reader connection status -> `cardReaderConnectionStatus`

### Reader Reconnection

Always active while the controller exists. When the reader disconnects and reconnects, re-initiates payment collection. Simplified from the aggregate model's `orderStage`-based observation.

---

## POSPaymentOrderProviding

```swift
protocol POSPaymentOrderProviding {
    func provideOrder() async throws -> Order
}
```

- **Cart flow:** returns the already-synced order from the order controller
- **Bookings flow:** fetches the order fresh by `booking.orderID` from the API

Fresh fetch for bookings ensures the order is current. The card payment service validates the order anyway, but starting from fresh data is cleaner.

---

## POSCashPaymentHandling

```swift
protocol POSCashPaymentHandling {
    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws
}
```

- **Cart flow:** wraps `orderService.markOrderAsCompletedWithCashPayment()`
- **Bookings flow:** same order service call

---

## Post-Payment Step

An optional `() async throws -> Void` closure that runs after any successful payment (card or cash) but before showing the success screen.

- **Cart flow:** `nil` (catalog sync is handled externally by the aggregate model observing payment state)
- **Bookings flow:** calls `bookingService.markBookingAsPaid(siteID:bookingID:)`

If the post-payment step fails, an intermediate error state is shown: "Payment succeeded, but we couldn't update the booking. [Retry]". The success screen only appears after this step completes.

**Fallback approach:** If the intermediate error state proves awkward, the alternative is for the bookings model to observe payment success and handle the booking update independently (option B). The payment controller shows success immediately, and the bookings model overlays an error with retry if `markBookingAsPaid` fails. Less clean UX but simpler payment controller.

---

## POSPaymentFlowConfiguration

```swift
struct POSPaymentFlowConfiguration {
    /// What to do when payment succeeds and user taps the main action button
    let successAction: PaymentFlowAction        // "New order" vs "Done"

    /// What to do when user wants to leave the payment flow entirely
    let exitAction: PaymentFlowAction            // "Edit order"/"New order" vs "Back to Booking"

    /// Whether to show a close (x) button on the initial payment screen
    let showInitialCloseButton: Bool
}

struct PaymentFlowAction {
    let title: String
    let action: () -> Void
}
```

### What the config handles (the cart-specific coupling points)

| Coupling point | Cart | Bookings |
|---|---|---|
| Success button | "New order" -> `startNewCart()` | "Done" -> dismiss, refresh booking |
| Exit/escape button (on errors) | "Edit order" / "New order" | "Back to Booking" -> dismiss |
| Close button on initial screen | No (floating buttons handle exit) | Yes (`x` at top, hides once processing) |

### What's NOT in the config (driven by data or payment-generic)

- **Discount field:** data-driven from `PointOfSaleOrderTotals` -- shown if the order has discounts, hidden otherwise
- **Barcode scanning:** managed by the container/dashboard view based on payment state, not by the payment flow
- **Cash payment button:** payment-generic, visibility driven by reader connection status and payment state via `TotalsViewHelper`
- **Error retry/restart buttons:** payment-generic, all handled by the payment controller
- **"Try another payment method":** resets to start of payment flow (both card and cash available)

### Error state actions summary

| Error | Buttons | Source |
|---|---|---|
| Payment error (retryable) | "Try payment again" + "Go back to checkout" | Payment-generic (retry / cancel+retry) |
| Card declined | "Try another payment method" | Payment-generic (back to start) |
| Non-retryable error | "Try another payment method" | Payment-generic (cancel+retry) |
| Validating order error | "Try again" + cash button | Payment-generic |
| Payment intent creation error | "Try payment again" + **exit action** + cash button | Exit action from config |
| Payment capture error | "Try payment again" + **exit action** | Exit action from config |
| Cancelled on reader | "Try payment again" | Payment-generic |

Only 2 error buttons across all 7 error states use the config's `exitAction`. Everything else is payment-generic.

---

## Totals Display

`PointOfSaleOrderTotals` (existing struct with formatted subtotal, tax, total, discounts, fees) is passed to the payment view as data. The payment controller does not own or manage totals display.

- **Cart flow:** aggregate model provides totals from `orderController.orderState`
- **Bookings flow:** bookings model computes totals from the fetched order

The reusable payment view renders totals and payment UI together (as `TotalsView` does today). Discount fields are shown/hidden based on whether the totals data contains discounts -- no config boolean needed.

---

## Presentation

The reusable payment view is the same component, hosted differently:

- **Cart flow:** inline panel in the dashboard `HStack` (as today). Expands to full-screen for processing/success/error states.
- **Bookings flow:** presented as a `.posFullScreenCover` from the booking detail view.

The `x` close button (from config) is only shown on the initial screen of the bookings payment flow. It hides once payment processing begins. After that, error recovery buttons provide the escape routes.

---

## Migration Strategy

**Wrap, don't rewrite.** Incremental, zero-behavior-change for the cart flow.

1. Create `POSPaymentController` with payment logic extracted verbatim from the aggregate model.
2. Aggregate model creates and owns a `POSPaymentController` instance.
3. Aggregate model's payment properties become pass-throughs: `var paymentState { paymentController.paymentState }`.
4. Aggregate model's payment methods become delegations: `func startCashPayment() { paymentController.startCashPayment() }`.
5. Views that read `@Environment(PointOfSaleAggregateModel.self)` for payment state **keep working unchanged** -- same public interface.
6. `setStateForEditing()` calls `paymentController.reset()` when transitioning `orderStage` to `.building`.
7. The reusable payment view (for bookings) reads from `@Environment(POSPaymentController.self)` directly.

Views can migrate from `posModel.paymentState` to `paymentController.paymentState` incrementally over time.

---

## Bookings Payment Flow (End-to-End)

### 1. Entry

- Booking detail shows "Collect Payment" button when `canCollectPayment` (unpaid + has orderID)
- Tap presents a `.posFullScreenCover`
- Bookings model creates a `POSPaymentController` with bookings-specific dependencies

### 2. Initial screen

- `x` close button (top corner) dismisses back to booking detail
- Shows order totals (from freshly fetched order)
- Reader connected: payment begins automatically, `x` hides
- Reader disconnected: connect prompt + cash payment button visible

### 3. Card payment

- Same card reader flow as main POS (connect -> tap/insert -> process -> success)
- On card payment confirmed -> `postPaymentStep` runs (`markBookingAsPaid`) -> success screen
- If `postPaymentStep` fails -> intermediate error with retry

### 4. Cash payment

- Same collect cash view (enter amount, change due, mark complete)
- `completeCashPayment` marks order paid -> `postPaymentStep` runs -> success screen

### 5. Success screen

- "Done" button dismisses the payment flow
- "Email receipt" available (standard WC template, not POS template, since order is not `created_via: pos_rest_api`)
- No barcode scanning

### 6. Error states

- All payment-generic retry/restart buttons work as normal
- "Back to Booking" (from `configuration.exitAction`) replaces "Edit order" / "New order"

### 7. Dismissal

- On dismiss (success "Done" or exit action): bookings model refreshes the booking + order to confirm updated status

---

## Differences from Main POS Payment Flow

| Aspect | Cart flow | Bookings flow |
|---|---|---|
| Order source | Created via `syncOrder()` at checkout | Fetched fresh by `booking.orderID` |
| Presentation | Inline panel in dashboard HStack | `.posFullScreenCover` from booking detail |
| Success action | "New order" (clears cart) | "Done" (dismiss, refresh booking) |
| Error exit action | "Edit order" / "New order" | "Back to Booking" (dismiss) |
| Post-payment step | None (catalog sync via observation) | `markBookingAsPaid()` (must succeed) |
| Close button | No (floating buttons) | Yes, on initial screen only |
| Barcode scanning | On dashboard container | Not applicable |
| Receipt template | POS template (`created_via: pos_rest_api`) | Standard WC template |
| Floating buttons | Visible | Not visible |
