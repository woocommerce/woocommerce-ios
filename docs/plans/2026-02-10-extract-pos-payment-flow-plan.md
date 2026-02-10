# Extract POS Payment Flow — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract the payment flow from `PointOfSaleAggregateModel` into a shared `POSPaymentController` that can be used by both the cart checkout and bookings payment flows.

**Architecture:** A shared `@Observable` `POSPaymentController` owns all payment state and logic (card, cash, receipts, reader connection). Callers inject dependencies via protocols (`POSPaymentOrderProviding`, `POSCashPaymentHandling`) and configure view-level differences via `POSPaymentFlowConfiguration`. The aggregate model delegates to its owned payment controller; bookings creates its own instance.

**Tech Stack:** Swift, SwiftUI, Combine, Swift Observation (`@Observable`), Swift Testing

**Design doc:** `docs/plans/2026-02-10-extract-pos-payment-flow-design.md`

---

## PR Overview

| PR | Theme | Risk | Est. lines (excl. tests) |
|----|-------|------|--------------------------|
| **PR 1** | Protocols, configuration, cart implementations | Low (pure additions) | ~120 |
| **PR 2** | Create `POSPaymentController` | Low (pure addition) | ~300 |
| **PR 3** | Migrate aggregate model to delegate | Medium (modifies aggregate model) | ~110 |
| **PR 4** | Decouple payment views for reuse | Medium (modifies views) | ~125 |
| **PR 5** | Bookings payment flow | Low (new code, feature-flagged) | ~140 |

Each PR is independently mergeable. Dependencies: PR 2 → PR 1. PR 3 → PR 2. PR 4 → PR 3. PR 5 → PR 4.

---

## PR 1: Protocols, Configuration, and Cart Implementations

**Theme:** Create the protocol abstractions, configuration types, and cart-specific implementations that the payment controller will depend on. Pure additions — nothing uses these yet.

### Task 1: Create payment protocols

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSPaymentOrderProviding.swift`
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSCashPaymentHandling.swift`

**Step 1: Create POSPaymentOrderProviding**

```swift
import Yosemite

/// Provides an Order for the payment controller to collect payment against.
/// Cart flow returns the already-synced order; bookings flow fetches by order ID.
protocol POSPaymentOrderProviding: Sendable {
    func provideOrder() async throws -> Order
}
```

**Step 2: Create POSCashPaymentHandling**

```swift
import Yosemite

/// Handles the "mark order as paid with cash" step during cash payment.
protocol POSCashPaymentHandling: Sendable {
    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws
}
```

**Step 3: Commit**

```
feat: add POSPaymentOrderProviding and POSCashPaymentHandling protocols
```

---

### Task 2: Create POSPaymentFlowConfiguration

**Files:**
- Create: `Modules/Sources/PointOfSale/Models/POSPaymentFlowConfiguration.swift`

**Step 1: Create the configuration and action types**

```swift
/// Configures the view-level differences between payment flow callers.
struct POSPaymentFlowConfiguration {
    /// Action shown on the success screen (e.g. "New order" for cart, "Done" for bookings).
    let successAction: PaymentFlowAction

    /// Action to leave the payment flow from a capture error
    /// ("New order" for cart, "Back to Booking" for bookings).
    let captureErrorExitAction: PaymentFlowAction

    /// Action to leave the payment flow from an intent creation error
    /// ("Edit order" for cart, "Back to Booking" for bookings).
    let intentCreationErrorExitAction: PaymentFlowAction

    /// Whether to show a close (x) button on the initial payment screen.
    let showInitialCloseButton: Bool
}

/// A labeled action used by the payment flow configuration.
struct PaymentFlowAction {
    let title: String
    let action: @MainActor () -> Void
}
```

**Step 2: Add cart factory method**

```swift
extension POSPaymentFlowConfiguration {
    static func cart(onNewOrder: @escaping @MainActor () -> Void,
                     onEditOrder: @escaping @MainActor () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: NSLocalizedString("New order", comment: "..."),
                action: onNewOrder),
            captureErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("New order", comment: "..."),
                action: onNewOrder),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Edit order", comment: "..."),
                action: onEditOrder),
            showInitialCloseButton: false
        )
    }
}
```

**Step 3: Add bookings factory method**

```swift
extension POSPaymentFlowConfiguration {
    static func bookings(onDismiss: @escaping @MainActor () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: NSLocalizedString("Done", comment: "..."),
                action: onDismiss),
            captureErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Back to Booking", comment: "..."),
                action: onDismiss),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Back to Booking", comment: "..."),
                action: onDismiss),
            showInitialCloseButton: true
        )
    }
}
```

**Step 4: Commit**

```
feat: add POSPaymentFlowConfiguration with cart and bookings factories
```

---

### Task 3: Create POSPaymentError

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSPaymentError.swift`

**Step 1: Create the error type**

```swift
enum POSPaymentError: Error, LocalizedError {
    case noOrder

    var errorDescription: String? {
        switch self {
        case .noOrder:
            return NSLocalizedString("No order available for payment",
                                     comment: "Error when trying to collect payment without an order")
        }
    }
}
```

**Step 2: Commit**

```
feat: add POSPaymentError
```

---

### Task 4: Create cart-specific protocol implementations

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSCartPaymentOrderProvider.swift`
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSCartCashPaymentHandler.swift`

**Step 1: Create POSCartPaymentOrderProvider**

Wraps the order controller to return the already-synced order:

```swift
struct POSCartPaymentOrderProvider: POSPaymentOrderProviding {
    let orderController: PointOfSaleOrderControllerProtocol

    func provideOrder() async throws -> Order {
        guard case let .loaded(_, order) = orderController.orderState else {
            throw POSPaymentError.noOrder
        }
        return order
    }
}
```

**Step 2: Create POSCartCashPaymentHandler**

```swift
struct POSCartCashPaymentHandler: POSCashPaymentHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        try await orderController.collectCashPayment(changeDueAmount: changeDueAmount)
    }
}
```

Note: `collectCashPayment` on the order controller uses its internal order reference. Verify this works or adjust the order controller to accept an explicit order parameter. Check `PointOfSaleOrderController.swift` lines 131–143.

**Step 3: Commit**

```
feat: add cart-specific payment protocol implementations
```

---

### Task 5: Tests for protocols and config

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Card Present Payments/POSPaymentFlowConfigurationTests.swift`
- Create: `Modules/Tests/PointOfSaleTests/Mocks/MockPOSPaymentOrderProvider.swift`
- Create: `Modules/Tests/PointOfSaleTests/Mocks/MockPOSCashPaymentHandler.swift`

**Step 1: Create mock implementations** (needed by later PRs too)

```swift
final class MockPOSPaymentOrderProvider: POSPaymentOrderProviding {
    var orderToReturn: Order?
    var errorToThrow: Error?
    var provideOrderCallCount = 0

    func provideOrder() async throws -> Order {
        provideOrderCallCount += 1
        if let error = errorToThrow { throw error }
        guard let order = orderToReturn else { throw POSPaymentError.noOrder }
        return order
    }
}

final class MockPOSCashPaymentHandler: POSCashPaymentHandling {
    var completeCashPaymentCalled = false
    var errorToThrow: Error?

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        completeCashPaymentCalled = true
        if let error = errorToThrow { throw error }
    }
}
```

**Step 2: Test config factories**

```swift
@Test func cartConfig_hasCorrectSuccessTitle() {
    let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
    #expect(config.successAction.title == "New order")
}

@Test func cartConfig_hasNoCloseButton() {
    let config = POSPaymentFlowConfiguration.cart(onNewOrder: {}, onEditOrder: {})
    #expect(config.showInitialCloseButton == false)
}

@Test func bookingsConfig_hasCorrectSuccessTitle() {
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
    #expect(config.successAction.title == "Done")
}

@Test func bookingsConfig_hasCloseButton() {
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
    #expect(config.showInitialCloseButton == true)
}

@Test func bookingsConfig_exitActionsDismiss() {
    var dismissed = false
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: { dismissed = true })
    config.captureErrorExitAction.action()
    #expect(dismissed == true)
}
```

**Step 3: Commit**

```
test: add POSPaymentFlowConfiguration tests and payment protocol mocks
```

---

### Task 6: PR 1 verification

**Step 1: Run POS tests** — all existing tests should pass (no existing code modified)

**Step 2: Create PR**

PR title: `Add payment flow protocols and configuration types`

---

## PR 2: Create POSPaymentController

**Theme:** Create the shared `@Observable` payment controller with all payment logic extracted from the aggregate model. Pure addition — no existing code is modified. The controller is not wired up yet.

### Task 7: POSPaymentController — state, init, and Combine chains

**Files:**
- Create: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Create the controller with state and init**

Reference: `PointOfSaleAggregateModel.swift` lines 33–37 (state), lines 120–144 (init).

```swift
@Observable
@MainActor
final class POSPaymentController {
    // MARK: - State (read by views)
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer?

    // MARK: - Dependencies
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderProvider: POSPaymentOrderProviding
    private let cashPaymentHandler: POSCashPaymentHandling
    private let receiptSender: POSReceiptSending
    private let postPaymentStep: (() async throws -> Void)?
    let configuration: POSPaymentFlowConfiguration
    private let analytics: POSAnalyticsProviding
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let celebration: PaymentCaptureCelebrationProtocol

    // MARK: - Internal
    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var onOnboardingCancellation: (() -> Void)?
    private var cancellables: Set<AnyCancellable> = []
    private var currentOrder: Order?
    private var formattedOrderTotalPrice: String?

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         orderProvider: POSPaymentOrderProviding,
         cashPaymentHandler: POSCashPaymentHandling,
         receiptSender: POSReceiptSending,
         postPaymentStep: (() async throws -> Void)? = nil,
         configuration: POSPaymentFlowConfiguration,
         analytics: POSAnalyticsProviding,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         celebration: PaymentCaptureCelebrationProtocol,
         paymentState: PointOfSalePaymentState = .idle) {
        // Store all dependencies, then:
        publishCardReaderConnectionStatus()
        publishPaymentMessages()
    }
}
```

**Step 2: Add `publishCardReaderConnectionStatus()`**

Move verbatim from `PointOfSaleAggregateModel.swift` lines 354–359.

**Step 3: Add `presentationStyleDeterminerDependencies`**

Move from `PointOfSaleAggregateModel.swift` lines 628–653. Key changes:
- `formattedOrderTotalPrice` reads from `self.formattedOrderTotalPrice` (cached) instead of `orderState`
- `paymentCaptureErrorNewOrderAction` → `configuration.captureErrorExitAction.action`
- `paymentIntentCreationErrorEditOrderAction` → `configuration.intentCreationErrorExitAction.action`
- All retry/cancel actions call `cancelThenCollectPayment()` on self
- `dismissReaderConnectionModal` sets `cardPresentPaymentAlertViewModel = nil`

**Step 4: Add `presentationStyle(for:)` and `mapCardPresentPaymentEventToMessageType(_:)`**

Move from `PointOfSaleAggregateModel.swift` lines 610–626. No changes needed.

**Step 5: Add `publishPaymentMessages()`**

Move from `PointOfSaleAggregateModel.swift` lines 541–607. All four Combine chains. The only change: uses injected `collectOrderPaymentAnalyticsTracker` for tracking.

**Step 6: Commit**

```
feat: add POSPaymentController with state and Combine chains
```

---

### Task 8: POSPaymentController — card payment methods

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add `startPayment()`**

Move from `PointOfSaleAggregateModel.swift` lines 395–414 (`startPaymentWhenCardReaderConnected`). Renamed to `startPayment()`. Same logic.

**Step 2: Add `collectCardPayment()`**

Key change — uses `orderProvider` instead of `internalOrderState`:

```swift
private func collectCardPayment() async {
    do {
        let order = try await orderProvider.provideOrder()
        currentOrder = order
        // Extract formattedOrderTotalPrice from order for success messages
        try await collectPayment(for: order)
    } catch {
        DDLogError("Error taking payment: \(error)")
    }
}
```

**Step 3: Add `collectPayment(for:)` and `cancelThenCollectPayment()`**

Move from aggregate model. `cancelThenCollectPayment` needs both sync and async overloads (sync wraps async in a Task, used by closure-based callbacks from `presentationStyleDeterminerDependencies`).

**Step 4: Add reader connection methods**

`connectCardReader()`, `disconnectCardReader()`, `updateCardReaderSoftware()` — pure pass-throughs to `cardPresentPaymentService`.

**Step 5: Add `cancelCardPaymentsOnboarding()`**

Move from aggregate model lines 525–532.

**Step 6: Commit**

```
feat: add card payment methods to POSPaymentController
```

---

### Task 9: POSPaymentController — cash, receipt, reset, reconnection

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add cash payment methods**

- `startCashPayment()` — cancel card, set `.collectingCash`
- `cancelCashPayment()` — reset to idle, resume card if reader connected
- `collectCashPayment(changeDueAmount:)` — fetch order if needed, call `cashPaymentHandler`, run `postPaymentStep`, then `cashPaymentSuccess()`
- `cashPaymentSuccess()` — set `.paymentSuccess`, call `celebration.celebrate()`

**Step 2: Add receipt sending**

```swift
func sendReceipt(to emailAddress: String) async throws {
    guard let order = currentOrder else { throw POSPaymentError.noOrder }
    try await receiptSender.sendReceipt(orderID: order.orderID, recipientEmail: emailAddress)
}
```

**Step 3: Add `reset()`**

Clears all payment state back to idle. Called by aggregate model when returning to `.building`.

**Step 4: Add reader reconnection observation**

Simplified from aggregate model's `orderStage`-based approach:
- `observeReaderReconnection()` — subscribes and auto-collects on reconnect
- `cancelReaderReconnectionObservation()` — cancels subscription

The aggregate model calls these when entering `.finalizing` / `.building` respectively.

**Step 5: Commit**

```
feat: add cash payment, receipt, reset, and reconnection to POSPaymentController
```

---

### Task 10: POSPaymentController tests

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Controllers/POSPaymentControllerTests.swift`

**Step 1: Create test factory**

```swift
private func makePaymentController(
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderProvider: POSPaymentOrderProviding = MockPOSPaymentOrderProvider(),
    cashPaymentHandler: POSCashPaymentHandling = MockPOSCashPaymentHandler(),
    receiptSender: POSReceiptSending = MockPOSReceiptSender(),
    postPaymentStep: (() async throws -> Void)? = nil,
    configuration: POSPaymentFlowConfiguration = .cart(onNewOrder: {}, onEditOrder: {}),
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    celebration: PaymentCaptureCelebrationProtocol = MockPaymentCaptureCelebration()
) -> POSPaymentController { ... }
```

**Step 2: Write tests (Swift Testing)**

Key test cases:

- `startPayment_whenReaderConnected_collectsCardPayment`
- `startPayment_whenReaderDisconnected_collectsOnConnect`
- `startCashPayment_cancelsCardAndTransitionsToCash`
- `cancelCashPayment_resetsToIdleAndResumesCardIfConnected`
- `collectCashPayment_callsHandlerAndTransitionsToSuccess`
- `collectCashPayment_runsPostPaymentStep`
- `reset_clearsAllState`
- `paymentEventPublisher_updatesCardPaymentState`
- `paymentEventPublisher_updatesAlertViewModel`
- `paymentEventPublisher_updatesInlineMessage`
- `postPaymentStep_calledOnCardPaymentSuccess`
- `postPaymentStep_failure_showsError`

Follow existing test patterns: `MockCardPresentPaymentService` with `@Published` properties, `withCheckedContinuation` + `onCollectPaymentCalled` for async sync.

**Step 3: Commit**

```
test: add POSPaymentController unit tests
```

---

### Task 11: PR 2 verification

**Step 1: Run POS tests** — all existing tests pass (no existing code modified)

**Step 2: Create PR**

PR title: `Create shared POSPaymentController`

---

## PR 3: Migrate Aggregate Model to Delegate

**Theme:** Wire the aggregate model to create and delegate to its owned `POSPaymentController`. Pass-through properties maintain the existing public interface. Zero behavior change.

### Task 12: Aggregate model delegates to POSPaymentController

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`

**Step 1: Add payment controller property and create in init**

```swift
let paymentController: POSPaymentController
```

Create in `init()` with cart-specific dependencies:
- `POSCartPaymentOrderProvider(orderController: orderController)`
- `POSCartCashPaymentHandler(orderController: orderController)`
- `.cart(onNewOrder: { [weak self] in self?.startNewCart() }, onEditOrder: { [weak self] in self?.addMoreToCart() })`
- No `postPaymentStep` for cart (catalog sync handled via observation)

**Step 2: Replace payment state properties with pass-throughs**

```swift
var paymentState: PointOfSalePaymentState { paymentController.paymentState }
var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? {
    get { paymentController.cardPresentPaymentAlertViewModel }
    set { paymentController.cardPresentPaymentAlertViewModel = newValue }
}
// ... etc for cardPresentPaymentInlineMessage, cardReaderConnectionStatus, onboardingViewContainer
```

**Step 3: Replace payment methods with delegations**

Each payment method becomes a one-liner delegating to `paymentController`:
- `startCashPayment()`, `cancelCashPayment()`, `collectCashPayment(changeDueAmount:)`
- `sendReceipt(to:)`, `cancelThenCollectPayment()`
- `connectCardReader()`, `disconnectCardReader()`

**Step 4: Update lifecycle methods**

- `setStateForEditing()` → call `paymentController.reset()`
- `checkOut()` → call `paymentController.startPayment()` instead of `startPaymentWhenCardReaderConnected()`
- `setupReaderReconnectionObservation()` → call `paymentController.observeReaderReconnection()` / `.cancelReaderReconnectionObservation()` based on `orderStage`
- `setupPaymentSuccessObservation()` → read `paymentController.paymentState.isSuccess`
- `pointOfSaleClosed()` → call `paymentController.reset()` + existing cleanup

**Step 5: Remove old payment code**

Remove from aggregate model:
- `publishPaymentMessages()` and all Combine chains
- `publishCardReaderConnectionStatus()`
- `presentationStyleDeterminerDependencies`, `presentationStyle(for:)`, `mapCardPresentPaymentEventToMessageType()`
- `startPaymentWhenCardReaderConnected()`, `collectCardPayment()`, `collectPayment(for:)`
- `cashPaymentSuccess()`, `cancelCardPaymentsOnboarding()` (delegate instead)
- `startPaymentOnCardReaderConnection` cancellable

Keep:
- `startNewCart()`, `addMoreToCart()` — cart concerns
- `checkOut()` — cart concern that calls into payment controller
- `pointOfSaleClosed()` — lifecycle (calls `paymentController.reset()` + order cleanup)
- `setupPaymentSuccessObservation()` — catalog sync reaction

**Step 6: Commit**

```
refactor: migrate aggregate model to delegate payment to POSPaymentController
```

---

### Task 13: Inject POSPaymentController into SwiftUI environment

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift`

**Step 1: Add environment injection**

Where `posModel` is injected:

```swift
.environment(posModel)
.environment(posModel.paymentController)
```

No views read from it yet — this sets up the environment for PR 4.

**Step 2: Commit**

```
feat: inject POSPaymentController into SwiftUI environment
```

---

### Task 14: Update aggregate model tests

**Files:**
- Modify: `Modules/Tests/PointOfSaleTests/Models/PointOfSaleAggregateModelTests.swift`

**Step 1: Update test factory**

The factory at lines 1025–1063 needs to create the payment controller internally from its existing mock parameters. Add the cart config and protocol implementations using the existing mocks.

**Step 2: Verify all existing payment tests pass**

The `PaymentTests` nested struct should pass unchanged — pass-through properties expose the same interface.

**Step 3: Commit**

```
test: update aggregate model test factory for POSPaymentController
```

---

### Task 15: PR 3 verification

**Step 1: Run all POS tests**

**Step 2: Manual smoke test** — go through the full POS cart payment flow (card + cash + receipt + "New order" + error states). Verify zero behavior change.

**Step 3: Create PR**

PR title: `Migrate aggregate model to delegate payment to POSPaymentController`

---

## PR 4: Decouple Payment Views for Reuse

**Theme:** Make payment views read from `@Environment(POSPaymentController.self)` instead of `@Environment(PointOfSaleAggregateModel.self)` for payment concerns. Views get caller-specific actions from the configuration. Zero behavior change for cart flow.

### Task 16: Decouple PointOfSalePaymentSuccessView and PaymentsActionButtons

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/CardReaderConnection/UI States/Reader Messages/PointOfSalePaymentSuccessView.swift`
- Modify: `Modules/Sources/PointOfSale/Presentation/PaymentButtons.swift`

**Step 1: Replace environment dependency with closures**

`PointOfSalePaymentSuccessView` currently reads `@Environment(PointOfSaleAggregateModel.self)` and calls `posModel.sendReceipt(to:)`, `posModel.startNewCart()`, `posModel.barcodeScanned(_:)`.

Change to accept closures:
```swift
let onSendReceipt: (String) async throws -> Void
let successAction: PaymentFlowAction
```

Remove `.barcodeScanning` modifier (moved to dashboard in Task 18).

**Step 2: Update PaymentsActionButtons**

Currently reads `posModel` and calls `posModel.startNewCart()`. Change to accept:
```swift
let successAction: PaymentFlowAction
```

Use `successAction.title` as button label, `successAction.action()` on tap.

**Step 3: Update call sites in TotalsView**

Pass closures from the payment controller and its configuration.

**Step 4: Commit**

```
refactor: decouple PointOfSalePaymentSuccessView from aggregate model
```

---

### Task 17: Decouple PointOfSaleCollectCashView

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleCollectCashView.swift`

**Step 1: Replace environment dependency**

```swift
// Before:
@Environment(PointOfSaleAggregateModel.self) private var posModel

// After:
@Environment(POSPaymentController.self) private var paymentController
```

Update `posModel.cancelCashPayment()` → `paymentController.cancelCashPayment()` and `posModel.collectCashPayment(changeDueAmount:)` → `paymentController.collectCashPayment(changeDueAmount:)`.

**Step 2: Commit**

```
refactor: decouple PointOfSaleCollectCashView from aggregate model
```

---

### Task 18: Move barcode scanning to dashboard

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleDashboardView.swift`

**Step 1: Add barcode scanning based on payment state**

```swift
.barcodeScanning(enabled: posModel.paymentState.isSuccess) { barcode in
    posModel.startNewCart()
    posModel.barcodeScanned(barcode)
}
```

Verify scanning doesn't fire during receipt sending (check if the receipt view suppresses HID input naturally).

**Step 2: Commit**

```
refactor: move barcode scanning from payment success view to dashboard
```

---

### Task 19: Update TotalsView to read from POSPaymentController

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`
- Modify: `Modules/Sources/PointOfSale/ViewHelpers/TotalsViewHelper.swift`

**Step 1: Add payment controller environment**

```swift
@Environment(POSPaymentController.self) private var paymentController
```

**Step 2: Replace payment state reads**

Replace `posModel.paymentState`, `posModel.cardReaderConnectionStatus`, `posModel.cardPresentPaymentInlineMessage`, `posModel.startCashPayment()`, `posModel.connectCardReader` with reads/calls on `paymentController`.

Keep `posModel.orderState` reads — order state is not a payment controller concern.

**Step 3: Make discount field data-driven**

Change `TotalsViewHelper.shouldShowTotalDiscountField(cart:orderTotals:)` to not require `Cart`:
- Check if `orderTotals?.discountTotal` is non-nil and non-zero instead of `cart.coupons.isNotEmpty`

Update `TotalsViewHelper.swift` and `TotalsViewHelperTests.swift`.

**Step 4: Commit**

```
refactor: update TotalsView to read payment state from POSPaymentController
```

---

### Task 20: Handle order totals for bookings compatibility

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`
- Possibly modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Make order totals accessible without posModel.orderState**

TotalsView currently switches on `posModel.orderState` (idle/syncing/loaded/error) to show totals. For bookings, there's no `posModel.orderState`.

Recommended approach: the payment controller exposes `orderTotals: PointOfSaleOrderTotals?` derived from its cached `currentOrder` after `provideOrder()` succeeds. TotalsView can check the payment controller for totals when `posModel.orderState` isn't available.

This may need refinement during implementation. The key constraint: TotalsView must work without `posModel.orderState` for the bookings flow.

**Step 2: Commit**

```
refactor: make TotalsView order totals source configurable
```

---

### Task 21: Clean up aggregate model pass-throughs

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`

**Step 1: Check which pass-throughs are still needed**

Search for `posModel.paymentState`, `posModel.cardPresentPaymentAlertViewModel`, etc. across all views. Keep pass-throughs that are still used (e.g., `PointOfSaleDashboardView` uses `paymentState.shownFullScreen` for layout). Remove any that are no longer accessed.

**Step 2: Commit**

```
refactor: remove unused payment pass-throughs from aggregate model
```

---

### Task 22: PR 4 verification

**Step 1: Run all POS tests**

**Step 2: Manual smoke test** — pay special attention to barcode scanning on success, cash payment, error buttons, receipt sending.

**Step 3: Create PR**

PR title: `Decouple payment views from aggregate model for reuse`

---

## PR 5: Bookings Payment Flow

**Theme:** Wire "Collect Payment" on booking details to the shared `POSPaymentController` with bookings-specific configuration. Feature-flagged under `.pointOfSaleBookings`.

### Task 23: Create bookings order provider

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSBookingPaymentOrderProvider.swift`

**Step 1: Implement POSPaymentOrderProviding for bookings**

Fetches the order fresh by ID:

```swift
struct POSBookingPaymentOrderProvider: POSPaymentOrderProviding {
    let orderID: Int64
    let orderService: POSOrderServiceProtocol

    func provideOrder() async throws -> Order {
        try await orderService.loadOrder(orderID: orderID)
    }
}
```

Check what service method fetches a single order by ID. The spec mentions `POSOrderListService.loadOrder(orderID:)`.

**Step 2: Commit**

```
feat: add POSBookingPaymentOrderProvider
```

---

### Task 24: Create bookings cash payment handler

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSBookingCashPaymentHandler.swift`

**Step 1: Implement POSCashPaymentHandling for bookings**

```swift
struct POSBookingCashPaymentHandler: POSCashPaymentHandling {
    let orderService: POSOrderServiceProtocol

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        try await orderService.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: changeDueAmount)
    }
}
```

**Step 2: Commit**

```
feat: add POSBookingCashPaymentHandler
```

---

### Task 25: Create bookings payment view wrapper

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift`

**Step 1: Create the full-screen payment wrapper**

- Creates a `POSPaymentController` with bookings dependencies
- Injects it into the environment
- Renders the reusable payment view (TotalsView)
- Shows `x` close button on initial screen, hidden once processing begins
- `postPaymentStep` calls `bookingService.markBookingAsPaid(siteID:bookingID:)`

```swift
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let onDismiss: () -> Void
    @State private var paymentController: POSPaymentController

    var body: some View {
        TotalsView(/* bookings order totals */)
            .environment(paymentController)
            .overlay(alignment: .topTrailing) {
                if paymentController.paymentState == .idle {
                    closeButton
                }
            }
            .task {
                await paymentController.startPayment()
            }
    }
}
```

**Step 2: Commit**

```
feat: add POSBookingPaymentView wrapper
```

---

### Task 26: Wire Collect Payment button

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

**Step 1: Present payment flow from booking detail**

```swift
@State private var isShowingPaymentFlow = false

Button("Collect Payment") {
    isShowingPaymentFlow = true
}

.posFullScreenCover(isPresented: $isShowingPaymentFlow) {
    POSBookingPaymentView(
        booking: booking,
        onDismiss: {
            isShowingPaymentFlow = false
            await bookingsModel.refreshBooking(booking.id)
        }
    )
}
```

**Step 2: Commit**

```
feat: wire Collect Payment to shared payment flow for bookings
```

---

### Task 27: Bookings payment tests

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Bookings/POSBookingPaymentTests.swift`

**Step 1: Test order provider, cash handler, and post-payment step**

```swift
@Test func bookingOrderProvider_fetchesOrderByID() async throws { ... }
@Test func bookingCashHandler_completesPayment() async throws { ... }
@Test func bookingsPayment_runsPostPaymentStepOnSuccess() async { ... }
```

**Step 2: Commit**

```
test: add bookings payment flow tests
```

---

### Task 28: PR 5 verification

**Step 1: Run all POS tests**

**Step 2: Manual testing**

- Enable bookings feature flag
- Bookings → select unpaid booking → "Collect Payment"
- Verify full-screen payment with close button
- Card and cash payment end-to-end
- Receipt sending (standard WC template)
- Error states show "Back to Booking"
- Booking status updates after payment
- Main POS cart payment still works

**Step 3: Create PR**

PR title: `Add payment flow to POS Bookings`

---

## Notes for Implementer

### Key reference files
- **Aggregate model:** `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`
- **Payment states:** `Modules/Sources/PointOfSale/Models/PointOfSalePaymentState.swift`
- **Card payment facade:** `Modules/Sources/PointOfSale/Card Present Payments/CardPresentPaymentFacade.swift`
- **TotalsView:** `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`
- **Event presentation style:** `Modules/Sources/PointOfSale/Presentation/Card Present Payments/PointOfSaleCardPresentPaymentEventPresentationStyle.swift`
- **Existing tests:** `Modules/Tests/PointOfSaleTests/Models/PointOfSaleAggregateModelTests.swift`
- **Design doc:** `docs/plans/2026-02-10-extract-pos-payment-flow-design.md`

### Testing approach
- **Swift Testing** (`@Test`, `#expect`, `#require`) for all new tests
- Factory function pattern with default mocks
- `MockCardPresentPaymentService` with `@Published` properties to drive Combine chains
- `withCheckedContinuation` + `onCollectPaymentCalled` for async sync

### Decisions to finalize during implementation
- **Order totals in TotalsView (Task 20):** How TotalsView gets order totals without `posModel.orderState`. Payment controller could expose `orderTotals` from its cached order, or TotalsView accepts totals as a parameter.
- **Post-payment step timing (Task 7/9):** Exact hook point for `postPaymentStep` after card payment success — in the Combine chain or after the success event.
- **Cash payment handler for cart (Task 4):** Whether the order controller's `collectCashPayment` needs adjustment to accept an explicit order parameter.
