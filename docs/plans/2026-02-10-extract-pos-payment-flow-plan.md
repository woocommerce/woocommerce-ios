# Extract POS Payment Flow — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract the payment flow from `PointOfSaleAggregateModel` into a shared `POSPaymentController` that can be used by both the cart checkout and bookings payment flows.

**Architecture:** A shared `@Observable` `POSPaymentController` owns all payment state and logic (card, cash, receipts, reader connection). Callers inject dependencies via protocols (`POSPaymentOrderProviding`, `POSCashPaymentHandling`) and configure view-level differences via `POSPaymentFlowConfiguration`. The aggregate model delegates to its owned payment controller; bookings creates its own instance.

**Tech Stack:** Swift, SwiftUI, Combine, Swift Observation (`@Observable`), Swift Testing

**Design doc:** `docs/plans/2026-02-10-extract-pos-payment-flow-design.md`

---

## PR Overview

| PR | Theme | Risk | Size |
|----|-------|------|------|
| **PR 1** | Extract `POSPaymentController` from aggregate model | Medium (modifies aggregate model) | Large |
| **PR 2** | Decouple payment views for reuse | Medium (modifies views) | Medium |
| **PR 3** | Bookings payment flow | Low (new code, feature-flagged) | Medium |

Each PR is independently mergeable. PR 2 depends on PR 1. PR 3 depends on PR 2.

---

## PR 1: Extract POSPaymentController from Aggregate Model

**Theme:** Create the shared payment controller, supporting protocols, and configuration types. Migrate the aggregate model to delegate to its owned payment controller. Zero behavior change for the cart flow.

### Task 1: Create POSPaymentOrderProviding protocol

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSPaymentOrderProviding.swift`

**Step 1: Create the protocol**

```swift
import Yosemite

/// Provides an Order for the payment controller to collect payment against.
/// Cart flow returns the already-synced order; bookings flow fetches by order ID.
protocol POSPaymentOrderProviding: Sendable {
    func provideOrder() async throws -> Order
}
```

**Step 2: Commit**

```
feat: add POSPaymentOrderProviding protocol
```

---

### Task 2: Create POSCashPaymentHandling protocol

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSCashPaymentHandling.swift`

**Step 1: Create the protocol**

```swift
import Yosemite

/// Handles the "mark order as paid with cash" step during cash payment.
/// Cart flow delegates to the order service; bookings flow does the same.
protocol POSCashPaymentHandling: Sendable {
    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws
}
```

**Step 2: Commit**

```
feat: add POSCashPaymentHandling protocol
```

---

### Task 3: Create POSPaymentFlowConfiguration

**Files:**
- Create: `Modules/Sources/PointOfSale/Models/POSPaymentFlowConfiguration.swift`

**Step 1: Create the configuration types**

```swift
/// Configures the view-level differences between payment flow callers.
struct POSPaymentFlowConfiguration {
    /// Action shown on the success screen (e.g. "New order" for cart, "Done" for bookings).
    let successAction: PaymentFlowAction

    /// Action to leave the payment flow entirely from error states
    /// (e.g. "Edit order"/"New order" for cart, "Back to Booking" for bookings).
    let exitAction: PaymentFlowAction

    /// Whether to show a close (x) button on the initial payment screen.
    /// Bookings shows this; cart doesn't (floating buttons handle exit).
    let showInitialCloseButton: Bool
}

/// A labeled action used by the payment flow configuration.
struct PaymentFlowAction {
    let title: String
    let action: @MainActor () -> Void
}
```

**Step 2: Commit**

```
feat: add POSPaymentFlowConfiguration
```

---

### Task 4: Create POSPaymentController — state and init

This is the core extraction. Build it incrementally over Tasks 4–8.

**Files:**
- Create: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Create the controller with state properties and init**

Start with the state properties and constructor. These mirror the aggregate model's payment-related properties.

Reference: `PointOfSaleAggregateModel.swift` lines 33–37 for the state properties, lines 120–144 for how they're initialized.

```swift
import Combine
import Yosemite

@Observable
@MainActor
final class POSPaymentController {
    // MARK: - Published state (read by views)
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer?

    // MARK: - Dependencies
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderProvider: POSPaymentOrderProviding
    private let cashPaymentHandler: POSCashPaymentHandling
    private let postPaymentStep: (() async throws -> Void)?
    let configuration: POSPaymentFlowConfiguration
    private let analytics: POSAnalyticsProviding
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let celebration: PaymentCaptureCelebrationProtocol

    // MARK: - Internal state
    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var onOnboardingCancellation: (() -> Void)?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Order cache (set after provideOrder succeeds)
    private var currentOrder: Order?
    private var formattedOrderTotalPrice: String?

    init(
        cardPresentPaymentService: CardPresentPaymentFacade,
        orderProvider: POSPaymentOrderProviding,
        cashPaymentHandler: POSCashPaymentHandling,
        postPaymentStep: (() async throws -> Void)? = nil,
        configuration: POSPaymentFlowConfiguration,
        analytics: POSAnalyticsProviding,
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
        celebration: PaymentCaptureCelebrationProtocol,
        paymentState: PointOfSalePaymentState = .idle
    ) {
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderProvider = orderProvider
        self.cashPaymentHandler = cashPaymentHandler
        self.postPaymentStep = postPaymentStep
        self.configuration = configuration
        self.analytics = analytics
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.celebration = celebration
        self.paymentState = paymentState

        publishCardReaderConnectionStatus()
        publishPaymentMessages()
    }
}
```

Note: `currentOrder` caches the order after the first `provideOrder()` call so the payment controller doesn't re-fetch on retry. It's set in `collectCardPayment()` and used by `presentationStyleDeterminerDependencies` for `formattedOrderTotalPrice`.

**Step 2: Commit**

```
feat: add POSPaymentController with state and init
```

---

### Task 5: POSPaymentController — Combine subscription chains

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add `publishCardReaderConnectionStatus()`**

Move from `PointOfSaleAggregateModel.swift` lines 354–359. No changes needed — it subscribes to `cardPresentPaymentService.readerConnectionStatusPublisher` and updates `cardReaderConnectionStatus`.

**Step 2: Add `presentationStyleDeterminerDependencies`**

Move from `PointOfSaleAggregateModel.swift` lines 628–653. Key changes:
- `formattedOrderTotalPrice` reads from `currentOrder` (cached) or `formattedOrderTotalPrice` instead of `orderState`
- `paymentCaptureErrorNewOrderAction` uses `configuration.exitAction.action` instead of `startNewCart()`
- `paymentIntentCreationErrorEditOrderAction` uses `configuration.exitAction.action` instead of `addMoreToCart()`
- `tryPaymentAgainBackToCheckoutAction`, `nonRetryableErrorExitAction`, `paymentCaptureErrorTryAgainAction` all call `cancelThenCollectPayment()` on self
- `dismissReaderConnectionModal` sets `cardPresentPaymentAlertViewModel = nil`

**Step 3: Add `presentationStyle(for:)`**

Move from `PointOfSaleAggregateModel.swift` lines 621–626. Uses `presentationStyleDeterminerDependencies` — no changes needed.

**Step 4: Add `mapCardPresentPaymentEventToMessageType(_:)`**

Move from `PointOfSaleAggregateModel.swift` lines 610–619. No changes needed.

**Step 5: Add `publishPaymentMessages()`**

Move from `PointOfSaleAggregateModel.swift` lines 541–607. All four Combine chains:
1. Payment events → alert view model
2. Payment events → inline message
3. Payment events → card payment state
4. Payment events → onboarding view container

The only change: analytics tracking in chain 3 uses `self.collectOrderPaymentAnalyticsTracker` (injected dependency) instead of `self.collectOrderPaymentAnalyticsTracker` (property on aggregate model) — effectively the same, just passed via init.

**Step 6: Commit**

```
feat: add Combine subscription chains to POSPaymentController
```

---

### Task 6: POSPaymentController — card payment methods

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add `startPayment()`**

Move from `PointOfSaleAggregateModel.swift` lines 395–414 (`startPaymentWhenCardReaderConnected`). Renamed to `startPayment()` for clarity. Same logic: if reader connected, collect immediately; otherwise subscribe and collect on connect.

**Step 2: Add `collectCardPayment()`**

Move from `PointOfSaleAggregateModel.swift` lines 417–429. Key change: instead of reading `internalOrderState`, call `orderProvider.provideOrder()`:

```swift
private func collectCardPayment() async {
    do {
        let order = try await orderProvider.provideOrder()
        currentOrder = order
        try await collectPayment(for: order)
    } catch {
        DDLogError("Error taking payment: \(error)")
    }
}
```

Note: Extract the `formattedOrderTotalPrice` from the order here too, so the `presentationStyleDeterminerDependencies` can use it for success messages. Use the same formatting approach as the aggregate model (reading from order totals).

**Step 3: Add `collectPayment(for:)`**

Move from `PointOfSaleAggregateModel.swift` lines 431–433. Pass-through to `cardPresentPaymentService.collectPayment(for:using:channel:)`.

**Step 4: Add `cancelThenCollectPayment()`**

Move from `PointOfSaleAggregateModel.swift` lines 470–480. Both sync and async overloads. Same logic: cancel then re-collect.

**Step 5: Add reader connection/disconnection methods**

Move from `PointOfSaleAggregateModel.swift` lines 370–389:
- `connectCardReader()`
- `disconnectCardReader()`
- `updateCardReaderSoftware()`

Pure pass-throughs to `cardPresentPaymentService`.

**Step 6: Add `cancelCardPaymentsOnboarding()`**

Move from `PointOfSaleAggregateModel.swift` lines 525–532.

**Step 7: Add post-payment step execution**

After card payment succeeds (in the Combine chain that sets `.cardPaymentSuccessful`), run the `postPaymentStep` if provided. This needs to happen after payment success is confirmed but before the success view renders as final. If the post-payment step fails, transition to an error state that allows retry.

**Step 8: Commit**

```
feat: add card payment methods to POSPaymentController
```

---

### Task 7: POSPaymentController — cash payment methods

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add cash payment methods**

Move from `PointOfSaleAggregateModel.swift` lines 434–458:
- `startCashPayment()` — cancel card, set `.collectingCash`
- `cancelCashPayment()` — reset to idle, resume card if reader connected
- `collectCashPayment(changeDueAmount:)` — call `cashPaymentHandler.completeCashPayment(for:changeDueAmount:)` with `currentOrder`, then `postPaymentStep`, then `cashPaymentSuccess()`
- `cashPaymentSuccess()` — set `.paymentSuccess`, call `celebration.celebrate()`

Key change in `collectCashPayment`: the order comes from `currentOrder` (cached from a previous `collectCardPayment` call or fetched fresh if entering cash directly). If `currentOrder` is nil, fetch it first via `orderProvider.provideOrder()`.

**Step 2: Add receipt sending**

Move from `PointOfSaleAggregateModel.swift` lines 461–463. Use a `receiptSender` dependency (add to init if not already there) or pass through to a receipt sending closure.

Actually, looking at this more carefully: receipt sending just needs the order ID. The payment controller has `currentOrder` cached. Add:

```swift
func sendReceipt(to emailAddress: String) async throws {
    guard let order = currentOrder else { throw POSPaymentError.noOrder }
    try await receiptSender.sendReceipt(orderID: order.orderID, recipientEmail: emailAddress)
}
```

Add `receiptSender: POSReceiptSending` as a dependency on init.

**Step 3: Add `reset()`**

Called by the aggregate model when transitioning to `.building`:

```swift
func reset() {
    paymentState = .idle
    cardPresentPaymentInlineMessage = nil
    currentOrder = nil
    formattedOrderTotalPrice = nil
    startPaymentOnCardReaderConnection?.cancel()
    startPaymentOnCardReaderConnection = nil
}
```

**Step 4: Commit**

```
feat: add cash payment, receipt, and reset to POSPaymentController
```

---

### Task 8: POSPaymentController — reader reconnection observation

**Files:**
- Modify: `Modules/Sources/PointOfSale/Controllers/POSPaymentController.swift`

**Step 1: Add reader reconnection observation**

Move from `PointOfSaleAggregateModel.swift` lines 482–518. Simplify: the aggregate model checks `orderStage` to decide whether to observe; the payment controller is always "active" when it exists. Use a simpler approach:

```swift
private var readerReconnectionCancellable: AnyCancellable?

/// Observes reader reconnection and re-initiates payment.
/// Called when the controller is active and should auto-collect on reconnect.
func observeReaderReconnection() {
    readerReconnectionCancellable = cardPresentPaymentService.readerConnectionStatusPublisher
        .filter { if case .connected = $0 { return true } else { return false } }
        .removeDuplicates()
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.startPayment()
            }
        }
}

func cancelReaderReconnectionObservation() {
    readerReconnectionCancellable?.cancel()
    readerReconnectionCancellable = nil
}
```

The aggregate model will call `observeReaderReconnection()` when entering `.finalizing` and `cancelReaderReconnectionObservation()` when entering `.building`. This replaces the `setupReaderReconnectionObservation()` that watched `orderStage` directly.

**Step 2: Commit**

```
feat: add reader reconnection observation to POSPaymentController
```

---

### Task 9: Cart-specific protocol implementations

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

Wraps the order controller's cash payment method:

```swift
struct POSCartCashPaymentHandler: POSCashPaymentHandling {
    let orderController: PointOfSaleOrderControllerProtocol

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        try await orderController.collectCashPayment(changeDueAmount: changeDueAmount)
    }
}
```

Note: `collectCashPayment` on the order controller already takes the order from its internal state. We may need to verify this works or adjust the order controller to accept an explicit order parameter. Check `PointOfSaleOrderController.swift` lines 131–143.

**Step 3: Create POSPaymentError enum**

```swift
enum POSPaymentError: Error, LocalizedError {
    case noOrder

    var errorDescription: String? {
        switch self {
        case .noOrder:
            return NSLocalizedString("No order available for payment", comment: "Error when trying to collect payment without an order")
        }
    }
}
```

This can go in the `POSPaymentController.swift` file or a separate file.

**Step 4: Commit**

```
feat: add cart-specific payment protocol implementations
```

---

### Task 10: Migrate aggregate model to delegate to POSPaymentController

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`

This is the key migration step. The aggregate model creates a `POSPaymentController` and delegates to it.

**Step 1: Add payment controller as a property**

```swift
let paymentController: POSPaymentController
```

Create it in `init()` with cart-specific dependencies and configuration.

The cart flow configuration:
```swift
let cartConfig = POSPaymentFlowConfiguration(
    successAction: PaymentFlowAction(title: NSLocalizedString("New order", comment: "...")) { [weak self] in
        self?.startNewCart()
    },
    exitAction: PaymentFlowAction(title: NSLocalizedString("Edit order", comment: "...")) { [weak self] in
        self?.addMoreToCart()
    },
    showInitialCloseButton: false
)
```

Note: the exit action label differs between error states ("Edit order" for intent creation error, "New order" for capture error). The configuration currently has a single `exitAction`. We may need to expand this to `exitActionForIntentCreationError` and `exitActionForCaptureError`, or keep a single exit action and adjust the label. Check how the `presentationStyleDeterminerDependencies` currently differentiates:
- `paymentCaptureErrorNewOrderAction` calls `startNewCart()`
- `paymentIntentCreationErrorEditOrderAction` calls `addMoreToCart()`

These are actually two different actions with different labels. The configuration needs both. Revise `POSPaymentFlowConfiguration`:

```swift
struct POSPaymentFlowConfiguration {
    let successAction: PaymentFlowAction
    let captureErrorExitAction: PaymentFlowAction   // "New order" for cart, "Back to Booking" for bookings
    let intentCreationErrorExitAction: PaymentFlowAction  // "Edit order" for cart, "Back to Booking" for bookings
    let showInitialCloseButton: Bool
}
```

For bookings, both exit actions would be the same ("Back to Booking" → dismiss). For cart, they differ.

**Step 2: Replace payment state properties with pass-throughs**

```swift
// Before:
private(set) var paymentState: PointOfSalePaymentState
var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

// After:
var paymentState: PointOfSalePaymentState { paymentController.paymentState }
var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? {
    get { paymentController.cardPresentPaymentAlertViewModel }
    set { paymentController.cardPresentPaymentAlertViewModel = newValue }
}
var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { paymentController.cardPresentPaymentInlineMessage }
var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus { paymentController.cardReaderConnectionStatus }
var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer? {
    get { paymentController.cardPresentPaymentOnboardingViewContainer }
    set { paymentController.cardPresentPaymentOnboardingViewContainer = newValue }
}
```

**Step 3: Replace payment methods with delegations**

```swift
func startCashPayment() async {
    await paymentController.startCashPayment()
}

func cancelCashPayment() async {
    await paymentController.cancelCashPayment()
}

func collectCashPayment(changeDueAmount: String?) async throws {
    try await paymentController.collectCashPayment(changeDueAmount: changeDueAmount)
}

func sendReceipt(to emailAddress: String) async throws {
    try await paymentController.sendReceipt(to: emailAddress)
}

func cancelThenCollectPayment() {
    paymentController.cancelThenCollectPayment()
}

func connectCardReader() async {
    await paymentController.connectCardReader()
}

func disconnectCardReader() async {
    await paymentController.disconnectCardReader()
}
```

**Step 4: Update `setStateForEditing()`**

```swift
// Before:
paymentState = .idle
cardPresentPaymentInlineMessage = nil

// After:
paymentController.reset()
```

**Step 5: Update `checkOut()`**

Replace `await startPaymentWhenCardReaderConnected()` with `await paymentController.startPayment()`.

**Step 6: Update `setupReaderReconnectionObservation()`**

Replace the direct `orderStage` observation with calls to:
- `paymentController.observeReaderReconnection()` when entering `.finalizing`
- `paymentController.cancelReaderReconnectionObservation()` when entering `.building`

**Step 7: Update `setupPaymentSuccessObservation()`**

This stays on the aggregate model but reads `paymentController.paymentState.isSuccess` instead of `paymentState.isSuccess`.

**Step 8: Remove old payment code**

Remove from the aggregate model:
- `publishPaymentMessages()` and all Combine chains
- `publishCardReaderConnectionStatus()`
- `presentationStyleDeterminerDependencies` computed property
- `presentationStyle(for:)` method
- `mapCardPresentPaymentEventToMessageType()` method
- `startPaymentWhenCardReaderConnected()` method
- `collectCardPayment()` method
- `collectPayment(for:)` method
- `cashPaymentSuccess()` method
- `startPaymentOnCardReaderConnection` cancellable
- `cancelCardPaymentsOnboarding()` (delegate to controller)

Keep on the aggregate model:
- `startNewCart()` — cart concern
- `addMoreToCart()` — cart concern
- `checkOut()` — cart concern that calls into payment controller
- `pointOfSaleClosed()` — lifecycle concern (calls `paymentController.reset()` + order controller cleanup)
- `setupPaymentSuccessObservation()` — catalog sync reaction

**Step 9: Commit**

```
refactor: migrate aggregate model to delegate payment to POSPaymentController
```

---

### Task 11: Update aggregate model tests

**Files:**
- Modify: `Modules/Tests/PointOfSaleTests/Models/PointOfSaleAggregateModelTests.swift`

**Step 1: Update test factory**

Add `paymentController` parameter or update the factory to create one internally from the existing mock parameters. The factory at lines 1025–1063 needs to create the payment controller with:
- `MockCardPresentPaymentService` (already a parameter)
- A `POSCartPaymentOrderProvider` wrapping the mock order controller
- A `POSCartCashPaymentHandler` wrapping the mock order controller
- The cart-specific `POSPaymentFlowConfiguration`
- Mock analytics (already a parameter)

**Step 2: Verify all existing payment tests pass**

The `PaymentTests` nested struct contains tests for:
- Card payment state changes driven by `MockCardPresentPaymentService.paymentEvent`
- Cash payment flow
- Reader connection status
- Payment success messages

These should all pass because the aggregate model's pass-through properties expose the same interface. If any tests directly access properties that moved to the payment controller, update them to go through the aggregate model's pass-throughs.

**Step 3: Commit**

```
test: update aggregate model test factory for POSPaymentController
```

---

### Task 12: Create POSPaymentController tests

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Controllers/POSPaymentControllerTests.swift`
- Create: `Modules/Tests/PointOfSaleTests/Mocks/MockPOSPaymentOrderProvider.swift`
- Create: `Modules/Tests/PointOfSaleTests/Mocks/MockPOSCashPaymentHandler.swift`

**Step 1: Create mock implementations**

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

**Step 2: Create test factory**

```swift
private func makePaymentController(
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderProvider: POSPaymentOrderProviding = MockPOSPaymentOrderProvider(),
    cashPaymentHandler: POSCashPaymentHandling = MockPOSCashPaymentHandler(),
    postPaymentStep: (() async throws -> Void)? = nil,
    configuration: POSPaymentFlowConfiguration = .cart(onNewOrder: {}, onEditOrder: {}),
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    celebration: PaymentCaptureCelebrationProtocol = MockPaymentCaptureCelebration()
) -> POSPaymentController { ... }
```

Consider adding a convenience static factory on `POSPaymentFlowConfiguration` for tests:
```swift
extension POSPaymentFlowConfiguration {
    static func cart(onNewOrder: @escaping @MainActor () -> Void, onEditOrder: @escaping @MainActor () -> Void) -> Self { ... }
}
```

**Step 3: Write tests using Swift Testing**

Key test cases (each a `@Test` function):

- `startPayment_whenReaderConnected_collectsCardPayment` — set mock reader as connected, call `startPayment()`, verify `collectPaymentWasCalled`
- `startPayment_whenReaderDisconnected_collectsOnConnect` — start with no reader, call `startPayment()`, then connect mock reader, verify `collectPaymentWasCalled`
- `startCashPayment_cancelsCardPaymentAndTransitionsToCash` — verify `paymentState.cash == .collectingCash`
- `cancelCashPayment_resetsToIdleAndResumesCardIfConnected` — verify state reset and card collection resumes
- `collectCashPayment_callsHandlerAndTransitionsToSuccess` — verify `completeCashPaymentCalled` and `paymentState.cash == .paymentSuccess`
- `collectCashPayment_runsPostPaymentStep` — provide a post-payment step closure, verify it's called
- `reset_clearsAllState` — verify all state returns to idle
- `paymentEventPublisher_updatesCardPaymentState` — set mock `paymentEvent`, verify `paymentState.card` updates
- `paymentEventPublisher_updatesAlertViewModel` — verify connection-related events produce alerts
- `paymentEventPublisher_updatesInlineMessage` — verify payment events produce inline messages
- `postPaymentStep_calledOnCardPaymentSuccess` — verify post-payment step runs after card success
- `postPaymentStep_failure_showsError` — verify failure is surfaced

Follow the existing test patterns:
- Use `MockCardPresentPaymentService` with `@Published` properties to drive Combine chains
- Use `withCheckedContinuation` with `onCollectPaymentCalled` for async synchronization
- Use `#expect` assertions (Swift Testing)

**Step 4: Commit**

```
test: add POSPaymentController unit tests
```

---

### Task 13: Inject POSPaymentController into SwiftUI environment

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift` or `PointOfSaleDashboardView.swift`

**Step 1: Add `.environment(posModel.paymentController)` to the view hierarchy**

Find where `posModel` is injected as environment (in `PointOfSaleEntryPointView`). Add the payment controller alongside it:

```swift
.environment(posModel)
.environment(posModel.paymentController)
```

This makes `POSPaymentController` available to all child views via `@Environment(POSPaymentController.self)`.

For now, no views read from it directly — they still go through `posModel`. This just sets up the environment for PR 2 and PR 3.

**Step 2: Verify the app builds and existing tests pass**

**Step 3: Commit**

```
feat: inject POSPaymentController into SwiftUI environment
```

---

### Task 14: Final verification and PR

**Step 1: Run all POS tests**

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme WooCommerce -testPlan PointOfSale -destination 'platform=iOS Simulator,name=iPad (10th generation)'
```

Or whatever test invocation this project uses. Check `CLAUDE.md` or `fastlane` for test commands.

**Step 2: Manual smoke test**

Build and run the app. Go through the POS cart payment flow (card and cash) and verify:
- Card reader connection works
- Card payment succeeds
- Cash payment succeeds
- Receipt sending works
- "New order" resets correctly
- Error states show correct buttons

**Step 3: Create PR**

PR title: `Extract POSPaymentController from aggregate model`

PR description should cover:
- What was extracted and why
- The protocols and configuration types
- That all existing behavior is unchanged (pass-through pattern)
- Link to the design doc

---

## PR 2: Decouple Payment Views for Reuse

**Theme:** Make payment views read from `@Environment(POSPaymentController.self)` instead of `@Environment(PointOfSaleAggregateModel.self)`. Views get their caller-specific actions from `POSPaymentFlowConfiguration`. Zero behavior change for cart flow.

### Task 15: Update presentationStyleDeterminerDependencies

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/Card Present Payments/PointOfSaleCardPresentPaymentEventPresentationStyle.swift`

**Step 1: Verify Dependencies struct alignment**

The `Dependencies` struct (lines 9–17) has these fields:
- `tryPaymentAgainBackToCheckoutAction` → payment-generic (cancelThenCollectPayment)
- `nonRetryableErrorExitAction` → payment-generic (cancelThenCollectPayment)
- `formattedOrderTotalPrice` → from order (on payment controller)
- `paymentCaptureErrorTryAgainAction` → payment-generic (cancelThenCollectPayment)
- `paymentCaptureErrorNewOrderAction` → **from config** (captureErrorExitAction)
- `paymentIntentCreationErrorEditOrderAction` → **from config** (intentCreationErrorExitAction)
- `dismissReaderConnectionModal` → payment-generic (clear alert)

The payment controller already builds these dependencies using its configuration. No changes needed to the `Dependencies` struct itself — the payment controller constructs it correctly.

**Step 2: Commit (if any changes needed)**

---

### Task 16: Decouple PointOfSalePaymentSuccessView

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/CardReaderConnection/UI States/Reader Messages/PointOfSalePaymentSuccessView.swift`

**Step 1: Replace `@Environment(PointOfSaleAggregateModel.self)` with closures**

Currently reads `posModel` from environment and calls:
- `posModel.sendReceipt(to:)` — pass as closure
- `posModel.startNewCart()` + `posModel.barcodeScanned(_:)` — this is the barcode scanning, which we're moving to the container

Change the view to accept closures instead:

```swift
// Before:
@Environment(PointOfSaleAggregateModel.self) private var posModel

// After:
let onSendReceipt: (String) async throws -> Void
let successAction: PaymentFlowAction
```

Remove the `.barcodeScanning` modifier from this view entirely (Task 18 moves it to the dashboard).

Update `PaymentsActionButtons` in the same change — it currently reads `posModel` for `startNewCart()`. Change it to accept the success action:

```swift
// Before (in PaymentsActionButtons):
@Environment(PointOfSaleAggregateModel.self) private var posModel
// posModel.startNewCart() on tap

// After:
let successAction: PaymentFlowAction
// successAction.action() on tap, with successAction.title as label
```

**Step 2: Update call sites**

Where `PointOfSalePaymentSuccessView` is created (in `TotalsView` → `CardPaymentView` or `CashPaymentView`), pass the closures from the payment controller and its configuration:

```swift
PointOfSalePaymentSuccessView(
    viewModel: ...,
    onSendReceipt: { email in try await paymentController.sendReceipt(to: email) },
    successAction: paymentController.configuration.successAction
)
```

**Step 3: Commit**

```
refactor: decouple PointOfSalePaymentSuccessView from aggregate model
```

---

### Task 17: Decouple PointOfSaleCollectCashView

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleCollectCashView.swift`

**Step 1: Replace `@Environment(PointOfSaleAggregateModel.self)` with `@Environment(POSPaymentController.self)`**

The view calls two methods:
- `posModel.cancelCashPayment()` → `paymentController.cancelCashPayment()`
- `posModel.collectCashPayment(changeDueAmount:)` → `paymentController.collectCashPayment(changeDueAmount:)`

```swift
// Before:
@Environment(PointOfSaleAggregateModel.self) private var posModel

// After:
@Environment(POSPaymentController.self) private var paymentController
```

Update the two method calls accordingly.

**Step 2: Commit**

```
refactor: decouple PointOfSaleCollectCashView from aggregate model
```

---

### Task 18: Move barcode scanning from success view to dashboard

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleDashboardView.swift`
- Verify: `Modules/Sources/PointOfSale/Presentation/CardReaderConnection/UI States/Reader Messages/PointOfSalePaymentSuccessView.swift` (barcode modifier already removed in Task 16)

**Step 1: Add barcode scanning to the dashboard based on payment state**

In `PointOfSaleDashboardView`, apply `.barcodeScanning` conditionally when payment state indicates success:

```swift
.barcodeScanning(enabled: posModel.paymentState.isSuccess) { barcode in
    posModel.startNewCart()
    posModel.barcodeScanned(barcode)
}
```

This keeps barcode scanning as a cart/dashboard concern, not a payment flow concern. It only activates during the success state, matching the current behavior.

**Step 2: Verify barcode scanning doesn't fire during receipt view**

The current implementation skips barcode scanning when `isShowingSendReceiptView` is true (it's in the `else` branch). With the dashboard-level approach, we need to ensure scanning doesn't interfere with receipt sending. Check if the receipt view is a sheet/cover that would naturally suppress barcode input, or if we need an additional condition.

**Step 3: Commit**

```
refactor: move barcode scanning from payment success view to dashboard
```

---

### Task 19: Update TotalsView to read from POSPaymentController

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`

**Step 1: Add `@Environment(POSPaymentController.self)` to TotalsView**

```swift
@Environment(POSPaymentController.self) private var paymentController
```

**Step 2: Replace payment state reads**

Systematically replace `posModel.paymentState`, `posModel.cardReaderConnectionStatus`, `posModel.cardPresentPaymentInlineMessage` with reads from `paymentController`.

Keep `posModel.orderState` reads from the aggregate model for now — order state is NOT a payment controller concern. The view still needs both environment values.

For the cart flow, this is a transparent change — both `posModel.paymentState` and `paymentController.paymentState` return the same value (pass-through).

**Step 3: Replace payment method calls**

- `posModel.startCashPayment()` → `paymentController.startCashPayment()`
- `posModel.connectCardReader` → `paymentController.connectCardReader` (if called from TotalsView)

**Step 4: Update `TotalsFieldsContent`**

Currently takes a `Cart` for `shouldShowTotalDiscountField(cart:orderTotals:)`. For bookings, there's no `Cart`. Change `TotalsViewHelper.shouldShowTotalDiscountField` to be data-driven:
- Instead of checking `cart.coupons.isNotEmpty`, check if `orderTotals?.discountTotal` is non-nil and non-zero
- This removes the `Cart` dependency from the totals display

Update `TotalsViewHelper.swift` and its tests accordingly.

**Step 5: Commit**

```
refactor: update TotalsView to read payment state from POSPaymentController
```

---

### Task 20: Handle order state in TotalsView for bookings

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`

**Step 1: Consider how TotalsView gets order totals**

Currently TotalsView reads `posModel.orderState` which is a `PointOfSaleOrderState` enum (idle/syncing/loaded/error). For bookings, the order is fetched by the payment controller's order provider, not by the aggregate model's order controller.

Options:
- **A:** TotalsView accepts `PointOfSaleOrderTotals?` as a parameter instead of reading `orderState` from environment. The caller (dashboard or bookings) provides it.
- **B:** The payment controller exposes an `orderTotals: PointOfSaleOrderTotals?` property that's set after `provideOrder()` succeeds.
- **C:** Keep reading from `posModel.orderState` for now; bookings creates its own view that passes totals differently.

Option B is cleanest — the payment controller already caches `currentOrder`. Add a computed `orderTotals` property that derives `PointOfSaleOrderTotals` from `currentOrder` (using the same mapping the order controller uses).

Alternatively, accept `orderTotals` as a parameter on TotalsView. For cart, pass `posModel.orderState`; for bookings, pass the payment controller's cached totals.

This decision may need refinement during implementation. The key constraint: TotalsView must work without `posModel.orderState` for the bookings flow.

**Step 2: Commit**

```
refactor: make TotalsView order totals source configurable
```

---

### Task 21: Update TotalsViewHelper tests

**Files:**
- Modify: `Modules/Tests/PointOfSaleTests/ViewHelpers/TotalsViewHelperTests.swift`

**Step 1: Update `shouldShowTotalDiscountField` tests**

If the method signature changed (from taking `Cart` to being data-driven), update the tests to match.

**Step 2: Verify all TotalsViewHelper tests pass**

**Step 3: Commit**

```
test: update TotalsViewHelper tests for data-driven discount field
```

---

### Task 22: Remove aggregate model pass-throughs (cleanup)

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`

**Step 1: Check which pass-through properties are still used by views**

After decoupling views to read from `POSPaymentController` directly, check if any views still access payment state via `posModel`. Search for:
- `posModel.paymentState`
- `posModel.cardPresentPaymentAlertViewModel`
- `posModel.cardPresentPaymentInlineMessage`
- `posModel.cardReaderConnectionStatus`

If views still need these (e.g., `PointOfSaleDashboardView` for layout decisions like `paymentState.shownFullScreen`), keep the pass-throughs for those. Remove any that are no longer accessed.

**Step 2: Also check non-view code** (e.g., `setupPaymentSuccessObservation`, `pointOfSaleClosed`) — these may still read from pass-throughs.

Note: The dashboard view itself uses `paymentState.shownFullScreen` for layout. This will need to read from the payment controller too, or the pass-through stays. Evaluate during implementation.

**Step 3: Commit**

```
refactor: remove unused payment pass-throughs from aggregate model
```

---

### Task 23: Final verification and PR

**Step 1: Run all POS tests**

**Step 2: Manual smoke test (same as Task 14)**

Pay special attention to:
- Barcode scanning on the success screen still works (now from dashboard)
- Cash payment flow works end-to-end
- Error buttons show correct text and work correctly
- Receipt sending works

**Step 3: Create PR**

PR title: `Decouple payment views from aggregate model for reuse`

---

## PR 3: Bookings Payment Flow

**Theme:** Wire up the "Collect Payment" button on booking details to use the shared `POSPaymentController` with bookings-specific configuration. Feature-flagged under `.pointOfSaleBookings`.

### Task 24: Create bookings order provider

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSBookingPaymentOrderProvider.swift`

**Step 1: Implement POSPaymentOrderProviding for bookings**

Fetches the order fresh by ID from the API:

```swift
struct POSBookingPaymentOrderProvider: POSPaymentOrderProviding {
    let orderID: Int64
    let orderService: POSOrderServiceProtocol // or whatever service can fetch a single order

    func provideOrder() async throws -> Order {
        try await orderService.loadOrder(orderID: orderID)
    }
}
```

Check what service method is available for fetching a single order by ID. The spec mentions `POSOrderListService.loadOrder(orderID:)`. Use whatever exists or create a thin wrapper.

**Step 2: Commit**

```
feat: add POSBookingPaymentOrderProvider
```

---

### Task 25: Create bookings cash payment handler

**Files:**
- Create: `Modules/Sources/PointOfSale/Card Present Payments/POSBookingCashPaymentHandler.swift`

**Step 1: Implement POSCashPaymentHandling for bookings**

Same as cart — marks the order as completed with cash:

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

### Task 26: Create bookings payment flow configuration

**Files:**
- Modify: `Modules/Sources/PointOfSale/Models/POSPaymentFlowConfiguration.swift` (add convenience factory)

**Step 1: Add bookings factory method**

```swift
extension POSPaymentFlowConfiguration {
    static func bookings(onDismiss: @escaping @MainActor () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: NSLocalizedString("Done", comment: "Button to dismiss payment flow after successful booking payment"),
                action: onDismiss
            ),
            captureErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Back to Booking", comment: "Button to return to booking detail from payment error"),
                action: onDismiss
            ),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Back to Booking", comment: "Button to return to booking detail from payment error"),
                action: onDismiss
            ),
            showInitialCloseButton: true
        )
    }
}
```

**Step 2: Add cart factory method** (if not already done)

```swift
extension POSPaymentFlowConfiguration {
    static func cart(onNewOrder: @escaping @MainActor () -> Void, onEditOrder: @escaping @MainActor () -> Void) -> Self {
        POSPaymentFlowConfiguration(
            successAction: PaymentFlowAction(
                title: NSLocalizedString("New order", comment: "Button to start new order after successful payment"),
                action: onNewOrder
            ),
            captureErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("New order", comment: "Button to abandon current order from capture error"),
                action: onNewOrder
            ),
            intentCreationErrorExitAction: PaymentFlowAction(
                title: NSLocalizedString("Edit order", comment: "Button to edit order from payment intent creation error"),
                action: onEditOrder
            ),
            showInitialCloseButton: false
        )
    }
}
```

**Step 3: Commit**

```
feat: add bookings and cart convenience factories for POSPaymentFlowConfiguration
```

---

### Task 27: Wire Collect Payment button to payment flow

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`
- Create (if needed): `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift`

**Step 1: Create the bookings payment view wrapper**

A simple full-screen wrapper that:
- Creates a `POSPaymentController` with bookings dependencies
- Injects it into the environment
- Renders the reusable payment view (TotalsView or its successor)
- Shows a close (`x`) button when in the initial payment state
- Hides the close button once processing begins

```swift
struct POSBookingPaymentView: View {
    let booking: POSBooking
    let onDismiss: () -> Void

    @State private var paymentController: POSPaymentController

    init(booking: POSBooking, /* dependencies */, onDismiss: @escaping () -> Void) {
        self.booking = booking
        self.onDismiss = onDismiss
        // Create payment controller with bookings config
        _paymentController = State(initialValue: POSPaymentController(
            cardPresentPaymentService: /* shared */,
            orderProvider: POSBookingPaymentOrderProvider(orderID: booking.orderID!, ...),
            cashPaymentHandler: POSBookingCashPaymentHandler(...),
            postPaymentStep: { try await bookingService.markBookingAsPaid(siteID: ..., bookingID: booking.id) },
            configuration: .bookings(onDismiss: onDismiss),
            analytics: /* shared */,
            ...
        ))
    }

    var body: some View {
        // Reusable payment view + close button
        TotalsView(/* with bookings-appropriate order totals */)
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

**Step 2: Present from booking detail**

In `POSBookingDetailView`, when "Collect Payment" is tapped:

```swift
@State private var isShowingPaymentFlow = false

// In the Collect Payment button action:
Button("Collect Payment") {
    isShowingPaymentFlow = true
}

.posFullScreenCover(isPresented: $isShowingPaymentFlow) {
    POSBookingPaymentView(
        booking: booking,
        onDismiss: {
            isShowingPaymentFlow = false
            // Refresh booking to confirm status
            await bookingsModel.refreshBooking(booking.id)
        }
    )
}
```

**Step 3: Handle post-payment booking refresh**

When the payment flow is dismissed (success or exit), refresh the booking and its linked order to confirm the updated status.

**Step 4: Commit**

```
feat: wire Collect Payment button to shared payment flow for bookings
```

---

### Task 28: Add bookings payment tests

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Bookings/POSBookingPaymentTests.swift`

**Step 1: Test that bookings payment controller is created with correct config**

```swift
@Test func bookingsConfig_hasCorrectSuccessActionTitle() {
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
    #expect(config.successAction.title == "Done")
}

@Test func bookingsConfig_hasCloseButton() {
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: {})
    #expect(config.showInitialCloseButton == true)
}

@Test func bookingsConfig_exitActionsMatchDismiss() {
    var dismissed = false
    let config = POSPaymentFlowConfiguration.bookings(onDismiss: { dismissed = true })
    config.captureErrorExitAction.action()
    #expect(dismissed == true)
}
```

**Step 2: Test bookings order provider**

```swift
@Test func bookingOrderProvider_fetchesOrderByID() async throws {
    let mockService = MockPOSOrderService()
    mockService.orderToReturn = makeOrder(orderID: 42)
    let provider = POSBookingPaymentOrderProvider(orderID: 42, orderService: mockService)
    let order = try await provider.provideOrder()
    #expect(order.orderID == 42)
}
```

**Step 3: Test post-payment step runs**

```swift
@Test func bookingsPayment_runsPostPaymentStepOnSuccess() async {
    var postPaymentCalled = false
    let controller = makePaymentController(
        postPaymentStep: { postPaymentCalled = true }
    )
    // Simulate payment success...
    #expect(postPaymentCalled == true)
}
```

**Step 4: Commit**

```
test: add bookings payment flow tests
```

---

### Task 29: Final verification and PR

**Step 1: Run all POS tests**

**Step 2: Manual testing**

- Ensure bookings feature flag is on
- Navigate to Bookings → select an unpaid booking → tap "Collect Payment"
- Verify full-screen payment flow appears with close button
- Test card payment end-to-end
- Test cash payment end-to-end
- Test receipt sending
- Test close button dismisses
- Test error states show "Back to Booking" buttons
- Verify booking status updates after payment
- Verify main POS cart payment still works correctly

**Step 3: Create PR**

PR title: `Add payment flow to POS Bookings`

---

## Notes for Implementer

### Key reference files
- **Aggregate model:** `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift` — the source of all payment code being extracted
- **Payment states:** `Modules/Sources/PointOfSale/Models/PointOfSalePaymentState.swift`
- **Card payment facade:** `Modules/Sources/PointOfSale/Card Present Payments/CardPresentPaymentFacade.swift`
- **TotalsView:** `Modules/Sources/PointOfSale/Presentation/TotalsView.swift`
- **Event presentation style:** `Modules/Sources/PointOfSale/Presentation/Card Present Payments/PointOfSaleCardPresentPaymentEventPresentationStyle.swift`
- **Existing tests:** `Modules/Tests/PointOfSaleTests/Models/PointOfSaleAggregateModelTests.swift`
- **Mock card service:** `Modules/Tests/PointOfSaleTests/Mocks/MockCardPresentPaymentService.swift`
- **Design doc:** `docs/plans/2026-02-10-extract-pos-payment-flow-design.md`

### Testing approach
- Use **Swift Testing** (`@Test`, `#expect`, `#require`) for all new tests
- Use the factory function pattern with default mocks for test setup
- Test Combine chains by setting `@Published` properties on `MockCardPresentPaymentService`
- Test async methods with `await` directly
- Use `withCheckedContinuation` + `onCollectPaymentCalled` for async synchronization

### Risk mitigation
- PR 1 is the highest risk (modifies aggregate model). Review carefully. All existing tests must pass.
- PR 2 modifies views but should be zero behavior change. Manual smoke testing is important.
- PR 3 is lowest risk — new feature-flagged code.
- At each PR, verify the main POS cart payment flow works end-to-end.

### Decisions to finalize during implementation
- **`POSPaymentFlowConfiguration` exit actions:** The plan splits into `captureErrorExitAction` and `intentCreationErrorExitAction`. Confirm this is needed during implementation — if both bookings actions are identical ("Back to Booking"), consider keeping a single `exitAction` and handling the label difference only for the cart flow.
- **Order totals in TotalsView (Task 20):** The exact mechanism for providing order totals to TotalsView without `posModel.orderState` needs refinement. The payment controller could expose `orderTotals` derived from its cached order, or TotalsView could accept totals as a parameter.
- **Post-payment step timing for card payments (Task 6, Step 7):** The exact hook point for running `postPaymentStep` after card payment success needs to be determined — whether it runs in the Combine chain that sets `.cardPaymentSuccessful`, or after the success event is received.
