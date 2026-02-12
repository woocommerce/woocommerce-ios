# POS Bookings Implementation Plan

## Context

We're adding Bookings to the Point of Sale module. Merchants create bookings on the web — POS lets them **view bookings and collect payment**. There is **no cart concept** in bookings: a booking already has an associated WooCommerce order; we fetch that order and pay against it.

This plan builds from `trunk` for **two developers working in parallel**.

**Base branch:** `trunk`
**Implementation branch:** `task/pos-bookings-foundation` (branched from `trunk`)
**Feature flag:** All changes gated under `.pointOfSaleBookings`

---

## Requirements

### What are Bookings?
Merchants use the WooCommerce Bookings plugin to sell time-based services (e.g. hair appointments, fitness classes, equipment rentals). Bookings are created on the web — either by the merchant in wp-admin or by customers through the store's checkout. Each booking is linked to a WooCommerce order that holds the payment details.

### What are we building?
A Bookings screen inside Point of Sale that lets merchants **view their bookings and collect payment** for them. POS does not create or edit bookings — it is a read-and-pay interface.

### Milestone 1 — Core Flow & Payment (Feb 13)
**Goal:** End-to-end payment for a booking with minimal scope.

**Navigation & Entry**
- "Bookings" button in the POS floating menu — **only visible when the merchant's site supports bookings** (has the WooCommerce Bookings plugin active with bookable products or existing bookings). This mirrors the main app's Bookings tab eligibility check (`BookingsTabEligibilityChecker`).
- Bookings opens as a full-screen overlay on top of POS

**Booking List (left pane)**
- Shows today's bookings, paginated (load more on scroll)
- Each row displays: customer name, booking amount, service name, time, payment status
- Search bookings by customer name
- Pull-to-refresh
- Empty state when no bookings exist
- Loading state with ghost/skeleton rows
- Error state with retry
- In-memory caching: retains content when bookings is closed and reopened

**Booking Detail (right pane) — before payment:**
1. **Header** — time range, service + customer, status badges ("Unattended" + "Unpaid")
2. **Booking details** — date, time, team member, location, duration
3. **Customer** — name, email, phone, billing address
4. **Customer note** — free-text note from the customer
5. **Attendance status** — toggle ("Attended" / "Unattended")
6. **Payment** — breakdown (Service, Taxes, Discount, Total)
7. **Collect Payment** — button (hidden when already paid or cancelled, or no linked order)
8. **Booking note** — internal note area + "Add note"

**Booking Detail (right pane) — after payment:**
Same sections 1–6, then:
7. **Payment status** — confirmation row ("Paid" checkmark)
8. **Booking note** — internal note area + "Add note", plus ellipsis menu (top right) with: View Order, Issue Refund, Cancel Booking

**Card Payment**
- Same card reader flow as POS product checkout (connect reader → tap/insert card → process → success)
- Reader connection status shown (disconnected → prompt to connect)
- Handles: card declined, reader disconnect mid-payment, network failure during order fetch
- On success: booking marked as paid via API, list refreshes to reflect new status

**Cash Payment**
- Enter amount received, see change due calculated
- "Mark as Paid" button (disabled until amount covers total)
- On success: booking marked as paid, list refreshes

**Receipt**
- After successful payment (card or cash), option to email a receipt
- Receipt template is determined by order origin: orders created via POS (`created_via: pos_rest_api`) use the POS receipt template; all other orders (including booking orders) use the standard WooCommerce receipt template

**Data Enrichment**
- Booking API returns raw IDs only (customer_id, product_id, resource_id, order_id)
- Service enriches bookings by batch-fetching linked orders (`ordersRemote.loadOrders(for:orderIDs:)`) and resources in parallel
- Customer name + service/product name come from the order enrichment (`BookingOrderInfo`)
- Resource/staff name comes from separate resource fetch

### Milestone 2 — Booking Management (Feb 20)
**Goal:** Make bookings actionable and understandable for merchants.

**Status Badges**
- Booking status: booked/completed are automatic and never shown as badges. Only cancelled is displayed (as a badge).
- Attendance status badge: color-coded for unattended (default), attended (success)
- Payment status badge: color-coded for unpaid (warning), paid (info), refunded (muted)
- Badges displayed in booking detail and list rows

**Booking Detail Enrichment**
- Booking notes (internal notes, with "Add note")
- Post-payment ellipsis menu: View Order, Issue Refund, Cancel Booking
- Action-gating computed properties (canMarkAttended, canCancel, canCollectPayment)

Note: Duration, location, customer email/phone/billing address, and customer note are already part of the M1 model and detail view.

**Booking List Enrichment**
- Attendance badge next to payment badge in each row
- Resource name (staff) visible if available
- More visible time range

**Update Attendance Status**
- Bidirectional toggle: "Mark Attended" button when attendance is `unattended`, "Mark Unattended" button when attendance is `attended`
- Button hidden when booking is cancelled
- Requires `.posModal()` confirmation dialog before executing
- On success: badge updates, list row refreshes
- On failure: error alert with retry

**Cancel Booking**
- "Cancel Booking" button — destructive style, shown when `canCancel` (booking status is NOT cancelled/completed)
- Requires `.posModal()` confirmation: "Cancel this booking? This cannot be undone."
- On success: booking shows cancelled state, payment buttons hidden, list updates
- On failure: error alert with retry

**Row Update After Actions**
- `updateBooking(bookingID:)` method re-fetches a single booking + its linked order, enriches, and replaces in view state + cache + selectedBooking
- Same pattern as `POSOrderListController.updateOrder(orderID:)`

### Milestone 3 — Polish & Release (Feb 27)
**Goal:** Complete operational needs and prepare for release.

**View Related Order**
- "View Order" button in booking detail (shown when booking has a linked order)
- Loads the linked order by ID via `POSOrderListService.loadOrder(orderID:)` and pushes `POSOrderDetailsView` directly
- No changes to the POS order list — bookings navigate directly to the order detail

**Refunds**
Two refund paths supported:
1. **From order detail** — "View Order" navigates to `POSOrderDetailsView`, which has the full refund flow built in (available from M3 with View Order)
2. **From booking detail** — "Issue Refund" button directly on the booking detail view (available when paid with linked order). M3 scope.

Implementation options to explore:
- **POC approach ([PR #16638](https://github.com/woocommerce/woocommerce-ios/pull/16638)):** Booking-specific `POSBookingRefundController` that reuses existing refund infrastructure (`POSRefundsServiceProtocol`, `POSRefundReviewData`, all 5 refund modal screens). The POC duplicated `POSRefundItemsSelectionView` because it's coupled to `POSOrderListModel` — decoupling that view would eliminate the duplication.
- **Deep linking:** Navigate from booking detail directly into the order detail's refund flow (e.g. open `POSOrderDetailsView` with the refund modal pre-triggered), avoiding new refund controller code entirely.

**Date Picker & Sort**
- Single date picker to show bookings for a specific day (defaults to today)
- Native SwiftUI `DatePicker` for day selection
- Sort by date: "Newest to Oldest" / "Oldest to Newest"
- Sort handled via `BookingsRemote.Order` enum (`.ascending`/`.descending`)
- Date filter uses `startDateBefore` / `startDateAfter` on `BookingFilters` (start/end of selected day)
- Empty state: "No bookings for this date" with reset-to-today option
- Date resets to today when bookings is closed and reopened

**Testing & Stabilization**
- Full regression across all milestones
- State management across payment → action → refresh cycles
- iPad layout at all split view sizes
- Dynamic type / accessibility
- Error recovery paths
- Feature flag: verify zero impact when flag is off

### Constraints
- **No cart.** Bookings already have an order — we fetch and pay against it.
- **No booking creation.** POS is view + pay only.
- **API: `wc-bookings/v2` only** (`wcBookingsV2`). Requires `WC_BOOKINGS_EXPERIMENTAL_ENABLED` on the server. v2 adds `attendance_status`, better filtering/sorting, and enhanced resource endpoints. All `BookingsRemote` endpoints must use this version.
- **Feature flagged.** All changes behind `.pointOfSaleBookings`. No impact on existing POS when flag is off.
- **Site eligibility.** The "Bookings" menu item is only visible when the merchant's site supports bookings — the WooCommerce Bookings plugin must be active and the store must have bookable products or existing bookings. This reuses the same eligibility check as the main app's Bookings tab (`BookingsTabEligibilityChecker`). When the site doesn't support bookings, no factory is injected, the model is `nil`, and the menu item is hidden.

### Reference Repositories
- **woocommerce-ios** (`woocommerce/woocommerce-ios`) — this repository. The POS module lives in `Modules/Sources/PointOfSale/`, networking in `Modules/Sources/Networking/`, and the service/business logic layer in `Modules/Sources/Yosemite/`.
- **woocommerce** (`woocommerce/woocommerce`) — the WooCommerce core plugin. Contains the WC REST API that powers orders, receipts, and the `wc/v3/orders` endpoint used to fetch orders for payment. `created_via` parameter is `type: array` with `compare: IN`.
- **woocommerce-bookings** (`woocommerce/woocommerce-bookings`) — the Bookings plugin. Provides the `wc-bookings/v2` REST API for bookings and resources. Key server-side files:
  - `includes/api/rest-api/v2/Controllers/class-wc-bookings-rest-booking-v2-controller.php` — booking endpoints (list, update, mark paid)
  - `includes/api/rest-api/class-wc-bookings-rest-resources-controller.php` — resource endpoints (staff/equipment)
  - Order creation: `set_created_via('bookings')` when creating orders for bookings

---

## Architecture Decisions

### API Version
All bookings API calls use `wc-bookings/v2` (`wcBookingsV2`) as specified in the constraints above. No v1 fallback.

### Data Enrichment Strategy
The booking API only returns raw IDs — no customer names, product names, or resource names. `POSBookingService.fetchBookings()` enriches in parallel:
1. Fetch bookings from bookings API
2. In parallel: batch-fetch linked orders via `ordersRemote.loadOrders(for:orderIDs:)` + fetch resources for unique resource IDs
3. Enrich each booking: `BookingOrderInfo(booking:order:)` provides customer name, service/product name, payment info
4. Resource fetch provides staff/resource name

This mirrors `BookingStore`'s existing enrichment pattern (lines 216-234 of `BookingStore.swift`).

### POSBookingsModel (analogous to POSAggregateModel)
- Owns `POSBookingListController`, `POSBookingPaymentController`
- Injected as `@Environment` into bookings views
- Shares `CardPresentPaymentFacade` with POS (received at init)
- Does NOT share `PointOfSaleOrderController` — bookings fetch existing orders, not create new ones
- M2 booking actions (mark attended, cancel) are methods on this model directly

### Strategies Pattern (like Products/Orders)
- `POSBookingListFetchStrategy` protocol — remote-first, pluggable for local later
- `POSBookingListFetchStrategyFactory` — produces default, search, and filtered strategies
- Default strategy fetches today's bookings; search strategy passes search query; filtered strategy builds from `POSBookingFilterState`
- Start with remote-only via `BookingsRemote`, via a new service in Yosemite providing an async/await interface. Consider adding async networking functions too, if needed.

### Payment: Reuse `TotalsView`
Reuse the production payment states:
- `PointOfSaleCardPaymentState` (11 states: idle, acceptingCard, cardInserted, preparingReader, processingPayment, paymentError, cardPaymentSuccessful, validatingOrder, validatingOrderError, paymentIntentCreationError)
- `PointOfSaleCashPaymentState` (idle, collectingCash, paymentSuccess)
- Combined via `PointOfSalePaymentState` struct

**Goal:** Reuse all or parts of `TotalsView` for booking payment rather than building separate booking payment views. Investigation found only 4 cart-specific coupling points in the view hierarchy (success actions, error button text, cash flow closures, discount field). Everything else is payment-generic. See B1 for the coupling analysis and implementation options to explore.

### Payment Flow Differences from POS Products

|                    | POS Products                              | POS Bookings                                  |
| ------------------ | ----------------------------------------- | --------------------------------------------- |
| Order              | Created during checkout (`syncOrder`)     | Fetched by order ID from booking              |
| **Entry**          | **Checkout button → order synced**        | **Collect Payment button → order fetched**    |
| Payment UI         | `TotalsView` driven by AggregateModel    | Reuse TotalsView (see B1 for options)         |
| Success action     | "New order" (clears cart)                 | "Done" (back to booking list)                 |
| Error actions      | "New order" / "Edit order"                | "Back to Booking" / "Try Again"               |
| Barcode on success | Enabled                                   | Disabled                                      |
| Receipt            | POS template (`created_via: pos_rest_api`)| Standard template (order not created via POS) |
| Reader reconnect   | Subscription-based auto-collect           | Same subscription-based pattern               |

### Navigation
- Bookings opens as `.posFullScreenCover` from floating menu (same as Orders)
- Uses `CustomNavigationSplitView` (used by `POSOrdersView`)
- Left: booking list, Right: booking detail / payment
- "View Order" (M3): presents `POSOrdersView` as `.posFullScreenCover` on top of bookings

### Status Presentation Model

The backend API uses a single `status` field that mixes booking lifecycle and payment semantics (e.g. `paid`, `unpaid`, `confirmed`, `cancelled`, `complete`). The `attendance_status` field is separate. For POS display, the **presentation layer** interprets these API values into three independent dimensions. No Networking or Yosemite enums are changed — the mapping is purely in `PointOfSale/Presentation/Bookings/POSBookingStatusPresentation.swift`.

**Booking lifecycle** (derived from `BookingStatus`):

| API `status` value | `BookingStatus` enum | POS lifecycle | Badge? |
|---|---|---|---|
| `paid`, `unpaid`, `confirmed`, `pending-confirmation` | `.paid`, `.unpaid`, `.confirmed`, `.pendingConfirmation` | Booked | No |
| `complete` | `.complete` | Completed | No |
| `cancelled` | `.cancelled` | Cancelled | Yes (error color) |

**Payment status** (derived from `BookingStatus`):

| API `status` value | `BookingStatus` enum | POS payment status |
|---|---|---|
| `paid`, `complete` | `.paid`, `.complete` | Paid |
| `unpaid`, `confirmed`, `pending-confirmation` | `.unpaid`, `.confirmed`, `.pendingConfirmation` | Unpaid |

**Attendance** (derived from `BookingAttendanceStatus`):

| API `attendance_status` value | `BookingAttendanceStatus` enum | POS attendance |
|---|---|---|
| `checked-in` | `.checkedIn` | Attended |
| `booked`, `no-show`, `cancelled` | `.booked`, `.noShow`, `.cancelled` | Unattended |

The `POSBooking` model stores the raw `BookingStatus` and `BookingAttendanceStatus` values. Views use the POS presentation types (`POSBookingLifecycleStatus`, `POSBookingPaymentStatus`, `POSBookingAttendanceDisplay`) to derive display text and colors.

---

## Milestone 1 — Core Flow & Payment (Feb 13)

### Phase 1: Foundation

#### F1. Create POSBookingServiceProtocol — paginated, filterable
**New file:** `Modules/Sources/Yosemite/Tools/POS/POSBookingService.swift`

Create a general-purpose booking service in Yosemite:

```swift
protocol POSBookingServiceProtocol: Sendable {
    func fetchBookings(siteID: Int64, pageNumber: Int, pageSize: Int,
                       filters: BookingFilters?, searchQuery: String?,
                       order: BookingsRemote.Order) async throws -> POSBookingFetchResult
    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws
}
```

- Uses existing `BookingsRemote.loadAllBookings()` (already supports pagination, filters, sorting)
- **Enrichment:** batch-fetch linked orders via `ordersRemote.loadOrders(for:orderIDs:)` AND resources via `BookingsRemote.fetchResource()` in parallel
- `BookingOrderInfo(booking:order:)` provides customer name, service/product name, payment info
- `hasNextPage` derived from `bookings.count == pageSize`
- Keep `fetchTodaysBookings()` as convenience wrapper with date-range filters
- Add convenience wrappers for upcoming and all bookings

**Existing code to reuse:**
- `BookingsRemote` at `Networking/Remote/BookingsRemote.swift` — `loadAllBookings(for:pageNumber:pageSize:filters:searchQuery:order:)`
- `BookingFilters` — supports productIDs, customerIDs, resourceIDs, dates, attendanceStatuses
- `BookingOrderInfo(booking:order:)` at `Networking/Model/Bookings/BookingOrderInfo.swift`
- `BookingStore` lines 216-234 — reference for enrichment pattern

#### F2. Create MockPOSBookingService
**New file:** `Modules/Tests/PointOfSaleTests/Mocks/MockPOSBookingService.swift`

Mock conforming to `POSBookingServiceProtocol` for unit tests.

#### F3. Create POSBookingListState — pagination-aware
**New file:** `Modules/Sources/PointOfSale/Models/POSBookingListState.swift`

Mirror `POSOrdersViewState` pattern:
```swift
enum POSBookingListState: Equatable {
    case loading([POSBooking])
    case loaded([POSBooking], hasMoreItems: Bool)
    case inlineError([POSBooking], error: PointOfSaleErrorState, context: InlineErrorContext)
    case error(PointOfSaleErrorState)
    case empty

    enum InlineErrorContext { case refresh, pagination }
}
```

#### F4. Create POSBooking model
**New file:** `Modules/Sources/PointOfSale/Models/POSBooking.swift`

Simple struct for booking display. Uses the raw API enum values — the POS presentation layer interprets them into three display dimensions (see Status Presentation Model). Reuses `PointOfSalePaymentState` for payment — no separate `POSBookingPaymentState`.

Properties:
- `id: Int64`
- `customerName: String`
- `serviceName: String`
- `startDate: Date`, `endDate: Date`
- `formattedAmount: String`
- `status: BookingStatus`, `attendanceStatus: BookingAttendanceStatus`
- `orderID: Int64?`
- `resourceName: String?` (team member / staff)
- `customerEmail: String?` (from order billing address)
- `customerPhone: String?` (from order billing address)
- `billingAddress: String?` (formatted from order billing address)
- `customerNote: String?` (from order customer note)
- `location: String?` (from resource or order billing address)
- `duration: String` (formatted from start/end, e.g. "60 min")

All customer-related fields come from the order enrichment that already happens in `POSBookingService` (batch-fetching linked orders). No additional API calls needed.

---

### Phase 2: Parallel Streams

### Stream A: List, Detail & Navigation

#### A1. POSBookingListFetchStrategy + Factory
**New files in:** `Modules/Sources/Yosemite/PointOfSale/BookingList/`

```swift
protocol POSBookingListFetchStrategy {
    func fetchBookings(pageNumber: Int) async throws -> POSBookingPageResult
    var supportsCaching: Bool { get }
    var showsLoadingWithItems: Bool { get }
}
```

- `POSDefaultBookingListFetchStrategy` — builds `BookingFilters` with today's date range
- `POSSearchBookingListFetchStrategy` — passes search query to service
- `POSBookingListFetchStrategyFactory` — factory protocol + default impl

**Mirrors:** `Yosemite/PointOfSale/OrderList/POSOrderListFetchStrategy.swift`

#### A2. POSBookingListController — strategy-based, paginated
**New file:** `PointOfSale/Controllers/POSBookingListController.swift`

- Accepts fetch strategy factory (switchable default ↔ search)
- Uses `AsyncPaginationTracker` for page management
- Methods: `loadBookings()`, `refreshBookings()`, `loadNextBookings()`, `searchBookings(searchTerm:)`, `clearSearchBookings()`
- In-memory `cachedBookings` — retains content across view lifecycle
- `updateBooking(bookingID:)` — re-fetch single booking + linked order, enrich, replace in state/cache/selectedBooking
- Caches bookings when switching to search, restores on clear

**Mirrors:** `PointOfSale/Controllers/POSOrderListController.swift`

#### A3. POSBookingsModel — create
**New file:** `PointOfSale/Models/POSBookingsModel.swift`

`@Observable` orchestration model (analogous to `POSAggregateModel` for bookings). Owns `bookingListController` (protocol type), `receiptSender`, payment dependencies. M2 booking actions added as methods directly on this model.

#### A4. POSBookingsContainerView — split view
**New file:** `PointOfSale/Presentation/Bookings/POSBookingsContainerView.swift`

- `CustomNavigationSplitView` (from `POSOrdersView`)
- Error/empty/content states matching `POSOrdersView` pattern
- Auto-select first booking on iPad

**Mirrors:** `PointOfSale/Presentation/Orders/POSOrdersView.swift`

#### A5. POSBookingListView — pagination and search
**New file:** `PointOfSale/Presentation/Bookings/POSBookingListView.swift`

- "Bookings" header + close button + search icon
- `InfiniteScrollView` for pagination
- `POSSearchField` for search
- Ghost loading rows, pull-to-refresh, inline errors

**Mirrors:** `PointOfSale/Presentation/Orders/POSOrderListView.swift`

#### A6. POSBookingRowView
**New file:** `PointOfSale/Presentation/Bookings/POSBookingRowView.swift`

- `ScaledMetric` + `dynamicTypeSize` for accessibility
- `posItemCardBorderStyles()` for selection highlight
- 3-line layout: customer+amount, service+time, status badge

#### A7. POSBookingDetailView
**New file:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

M1 layout (before payment):
1. **Header** — time range, service + customer name, status badges (attendance + payment)
2. **Booking details** — date, time, team member, location, duration
3. **Customer** — name, email, phone, billing address
4. **Customer note**
5. **Attendance status** — toggle
6. **Payment** — breakdown (service, taxes, discount, total)
7. **Collect Payment** button
8. **Booking note** — internal note + "Add note"

After payment: sections 1–6 remain, "Collect Payment" replaced by "Paid" confirmation row, ellipsis menu added (View Order, Issue Refund, Cancel Booking)

Contextual states: paid → checkmark + ellipsis menu, cancelled → cancelled label, noLinkedOrder → explanation, unpaid with order → collect payment button

#### A8. Empty/Loading/Error views
**New files:** `POSBookingDetailsEmptyView.swift`, `POSBookingDetailsLoadingView.swift`

#### A9. Entry point wiring
**Modify:** `PointOfSale/Presentation/PointOfSaleEntryPointView.swift`

Pass strategy factory to booking list controller. `POSFloatingControlView` already has bookings button behind `.pointOfSaleBookings`.

---

### Stream B: Payment & Checkout

#### B1. Make TotalsView reusable for booking payment

**Goal:** When a merchant taps "Collect Payment" on a booking, they see the same payment experience as cart checkout — card reader connection, inline payment messages, cash payment entrance. Reuse as much of `TotalsView` and its sub-views as possible rather than building booking-specific payment views.

**What's already reusable (no changes needed):**
- All payment state types (`PointOfSalePaymentState`, `PointOfSaleCardPaymentState`, `PointOfSaleCashPaymentState`)
- Card reader connection UI, inline payment messages, `TotalsViewHelper` (except one method), layout/animation logic
- `PointOfSaleCardPaymentState(from:using:)` event-to-state mapping
- `PointOfSaleCardPresentPaymentEventPresentationStyle` event routing
- `CardPresentPaymentFacade` payment service

**What's cart-specific (the 4 coupling points to address):**

| Coupling | File | What's cart-specific |
|----------|------|---------------------|
| Success view | `PointOfSalePaymentSuccessView` | Reads `posModel` from environment. "New order" calls `startNewCart()`. Barcode scanning. |
| Cash collection | `PointOfSaleCollectCashView` | Reads `posModel` from environment. Calls `cancelCashPayment()` / `collectCashPayment()`. |
| Error button text | 3 error message VMs | "New order" / "Edit order" / "Go back to checkout" — don't apply to bookings |
| Discount field | `TotalsFieldsContent` | Takes a `Cart` to check `cart.coupons.isNotEmpty` |

**Booking equivalents for cart-specific behaviors:**
- Success: "Done" (dismiss, refresh list) instead of "New order". No barcode scanning.
- Error: "Back to Booking" / "Try Again" instead of "New order" / "Edit order"
- Cash: same flow, different action targets
- Discount field: not shown for bookings

**Implementation options to explore:**
- **Configuration-based:** Introduce a configuration struct that abstracts the 4 coupling points (success actions, error button text, cash closures, discount visibility). `TotalsView` accepts configuration; `PointOfSaleAggregateModel` provides cart config, booking controller provides booking config. Single view, zero duplication.
- **Extract sub-views:** Make the currently `private` sub-views in `TotalsView` (`PaymentViewContent`, `CardPaymentView`, `CashPaymentButton`, `TotalsFieldsContent`) `internal`. Build a booking payment view that composes the same sub-views with booking-specific wiring. More duplication at the composition level, but less invasive.
- **Hybrid:** Extract + decouple the two views that read `@Environment(PointOfSaleAggregateModel.self)` directly (`PointOfSalePaymentSuccessView`, `PointOfSaleCollectCashView`) to accept closures instead. This alone may be sufficient to make `TotalsView` reusable without a full configuration struct.

**Key principle:** Any refactoring must be zero-behavior-change for the existing cart flow.

#### B2. POSBookingPaymentController — payment orchestration for bookings
**New file:** `PointOfSale/Controllers/POSBookingPaymentController.swift`

Manages the payment state machine for a booking. Mirrors `PointOfSaleAggregateModel`'s payment orchestration but without cart/catalog/order-creation concerns.

**State:** `paymentState`, `cardPresentPaymentAlertViewModel`, `cardPresentPaymentInlineMessage`, `cardReaderConnectionStatus`

**Key methods:**
- `startPaymentWhenCardReaderConnected()` — if connected, collect immediately; otherwise subscribe and collect on connect
- `collectCardPayment()` — fetch order via `orderProvider`, then `cardPaymentFacade.collectPayment(for:using:channel:)`
- `cancelThenCollectPayment()` — cancel current and retry
- `publishPaymentMessages()` — 3 Combine subscription chains (events → alerts, inline messages, card state)
- On `cardPaymentSuccessful`: call `bookingService.markBookingAsPaid()`
- Cash: `startCashPayment()`, `cancelCashPayment()`, `collectCashPayment(changeDueAmount:)`
- Reader reconnection: subscription-based (same pattern as AggregateModel)

**Notes:**
- The `validatingOrder` phase is real — the card payment service validates the order is payable. `validatingOrderError` handles order fetch failure, already paid, etc.
- Receipt: template determined by order origin (`created_via`), not by booking context

#### B3. Receipt handling — template based on order origin
**Modify:** `PointOfSale/Utils/POSReceiptSender.swift`

Use the order's `created_via` field to determine receipt template. Orders created via POS (`created_via: pos_rest_api`) use the POS receipt template; all other orders use the standard WooCommerce receipt template. No booking-specific flag needed — the distinction is already encoded in the order's origin.

---

### Phase 3: Convergence

#### C1. Wire payment into POSBookingsContainerView
- "Collect Payment" in booking detail triggers the reusable payment flow (see B1 for approach options)
- On success → dismiss → refresh list → booking shows "Paid"
- Receipt template determined by order's `created_via` field (see B3)

#### C2. Entry point wiring
- Strategy factory + all dependencies injected in `PointOfSaleEntryPointView`

---

### M1 Dependency Graph

```
F1 (Service + enrichment) ──┬── F2 (Mock)
                                  ├── A1 (Strategies) → A2 (Controller) → A5 (ListView) → A4 (Container)
                                  └── B3 (Receipt)

F3 (List state)  ─── A2 (Controller)
F4 (Booking model) ── A2 (Controller)

A6, A7, A8 ─── no deps, start immediately

B1 (Refactor TotalsView) → B2 (Booking payment controller)
C1 (Wire payment) ─── after A4 + B2 + B3
C2 (Entry point) ─── after A2 + A1
```

### M1 Suggested Work Split

| Person A (UI-focused)                         | Person B (Payment-focused)                    |
| --------------------------------------------- | --------------------------------------------- |
| F3 (list state), F4 (model)                   | F1 (service + enrichment), F2 (mock)          |
| A6 (row), A7 (detail), A8 (empty/loading)     | B1 (refactor TotalsView + configuration)      |
| A1 (strategies) → A2 (controller)             | B2 (booking payment controller)               |
| A5 (list) → A4 (container) → A3 (model)       | B3 (receipt)                                  |
| C1 + C2 (wire + test)                          | C1 + C2 (wire + test)                         |

---

## Milestone 2 — Booking Management (Feb 20)

### Phase 1: Foundation

#### M2-F1. Expand POSBookingServiceProtocol — attendance + cancel
**Modify:** `Modules/Sources/Yosemite/Tools/POS/POSBookingService.swift`

Add methods to the existing protocol:
```swift
func updateAttendanceStatus(siteID: Int64, bookingID: Int64, status: BookingAttendanceStatus) async throws
func cancelBooking(siteID: Int64, bookingID: Int64) async throws
```

- Calls `BookingsRemote.updateBooking(from:bookingID:attendanceStatus:bookingStatus:note:)` directly — single PUT endpoint supporting all fields
- Cancel = update booking status to `.cancelled`
- Remote-only, no optimistic updates (architecture open for later)
- Update mock to match

**Existing code:**
- `BookingsRemote.updateBooking()` at `Networking/Remote/BookingsRemote.swift` — single PUT with optional `attendanceStatus`, `bookingStatus`, `note` params
- Uses the v2 API (see Constraints)

#### M2-F2. POSBookingPaymentBadgeView — payment status
**New file:** `PointOfSale/Presentation/Bookings/POSBookingPaymentBadgeView.swift`

Color-coded badge for `POSBookingPaymentStatus` (POS presentation type derived from `BookingStatus`):
- `unpaid` → `.posWarningLowest` bg, `.posOnWarningLowest` text
- `paid` → `.posInfoLowest` bg, `.posOnInfoLowest` text
- `refunded` → muted/grey

Uses `.posCaptionRegular` font, `POSPadding.small`/`.xSmall`, `POSCornerRadiusStyle.small`.

**Mirrors:** `PointOfSale/Presentation/Orders/POSOrderBadgeView.swift`

#### M2-F3. POSBookingCancelledBadgeView + AttendanceBadgeView

**Cancelled badge:** Shown only when `bookingStatus == .cancelled` → `.posErrorLowest` bg, `.posOnErrorLowest` text.
Booking statuses `booked` and `completed` are automatic and never displayed as badges.

**Attendance badge** for `BookingAttendanceStatus`:
- `unattended` → `.posDefault` bg, `.posOnDefault` text
- `attended` → `.posSuccessLowest` bg, `.posOnSuccessLowest` text

**API enums (Networking layer — DO NOT MODIFY):**
- `BookingStatus` at `Networking/Model/Bookings/Booking.swift` — complete, paid, unpaid, cancelled, pendingConfirmation, confirmed, unknown
- `BookingAttendanceStatus` at same file — booked, checkedIn, cancelled, noShow, unknown

**POS presentation types (PointOfSale layer — `POSBookingStatusPresentation.swift`):**
- `POSBookingLifecycleStatus` — booked, completed, cancelled (derived from `BookingStatus`)
- `POSBookingPaymentStatus` — paid, unpaid (derived from `BookingStatus`)
- `POSBookingAttendanceDisplay` — attended, unattended (derived from `BookingAttendanceStatus`)

See "Status Presentation Model" in Architecture Decisions for the full mapping.

---

### Phase 2: Parallel Streams

### Stream A: Detail & List Enrichment

#### M2-A1. POSBooking model enrichment
**Modify:** `PointOfSale/Models/POSBooking.swift`

Add properties:
- `notes: [String]` (internal booking notes)

Add computed properties (use POS presentation types to derive from raw API enums):
- `canMarkAttended: Bool` — true when `POSBookingAttendanceDisplay(attendanceStatus:)` is `.unattended`
- `canCancel: Bool` — true when `POSBookingLifecycleStatus(bookingStatus:)` is NOT `.cancelled`/`.completed`
- `canCollectPayment: Bool` — true when `POSBookingPaymentStatus(bookingStatus:)` is `.unpaid` AND has orderID

Note: Most customer/detail data (email, phone, billing address, customer note, location, duration) is already on the M1 model (F4). M2 adds booking notes and action-gating computed properties.

#### M2-A2. POSBookingDetailView enrichment
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

M1 already renders the full detail layout (header, booking details, customer, customer note, attendance, payment, collect payment / paid status). M2 adds:
- **Booking note section** — internal booking notes with "Add note" support
- **Post-payment ellipsis menu** — View Order, Issue Refund, Cancel Booking (shown only after payment, top-right of booking note section)
- **Action-gating** — use `canMarkAttended`, `canCancel`, `canCollectPayment` to control button/toggle visibility

#### M2-A3. POSBookingRowView enrichment
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingRowView.swift`

Add to existing 3-line layout:
- Attendance badge next to payment badge
- Resource name (staff) if available
- More visible time range

### Stream B: Booking Actions

#### M2-B1. Booking actions on POSBookingsModel
**Modify:** `PointOfSale/Models/POSBookingsModel.swift`

Add methods directly on `POSBookingsModel`:
```swift
func markAttended(booking: POSBooking) async throws
func cancelBooking(booking: POSBooking) async throws
```

- Calls `POSBookingServiceProtocol.updateAttendanceStatus()` / `.cancelBooking()`
- On success: calls `updateBooking(bookingID:)` to refresh the specific booking in list + detail
- On failure: surfaces error to UI
- Analytics events: `booking_marked_attended`, `booking_cancelled`

#### M2-B2. Attendance update UI
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`
**New files:** `PointOfSale/Presentation/Bookings/UpdateAttendance/` (4 files: modal state, confirmation view, success view, modal content)

- Bidirectional attendance toggle in the detail view (section 5):
  - "Mark Attended" button when current status is `unattended`
  - "Mark Unattended" button when current status is `attended`
  - Button hidden when booking is cancelled
- Requires `.posModal()` confirmation dialog before executing (mirrors cancel booking modal flow)
- Calls `bookingsController.updateAttendanceStatus(bookingID:status:)` on confirm
- Modal states: confirmation → processing → success/error
- Error state reuses `POSRefundErrorView` with retry
- On success: badge updates inline, header status badges update, list row refreshes via `refreshBookings()`
- On failure: error alert with retry

#### M2-B3. Cancel booking UI
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

- Before payment: "Cancel Booking" shown as a button (when `canCancel`)
- After payment: "Cancel Booking" available via ellipsis menu (top-right)
- `.posModal()` confirmation: "Cancel this booking? This cannot be undone."
- On success: booking shows cancelled state, payment buttons hidden, list updates
- On failure: error alert with retry

#### M2-B4. Analytics for booking actions
**Modify:** Analytics tracking via `POSAnalyticsProviding`

Events:
- `booking_detail_viewed` — when detail pane shows a booking
- `booking_marked_attended` — attendance updated to attended
- `booking_cancelled` — booking cancelled

---

### Phase 3: Convergence

#### M2-C1. Testing
- Unit tests for booking actions (mark attended, cancel, error handling)
- Unit tests for badge color mapping
- Unit tests for `canMarkAttended`/`canCancel`/`canCollectPayment` computed properties
- Manual: verify badge colors, action flows, list refresh after status change

---

### M2 Dependency Graph

```
M2-F1 (Service expand) ── M2-B1 (Actions on model) ── M2-B2/B3 (Action UI)
M2-F2 (Payment badge) ──┐
M2-F3 (Cancelled + Attendance badge) ┼── M2-A2 (Detail enrichment)
M2-A1 (Model enrichment) ┘
M2-A1 ── M2-A3 (Row enrichment)
```

### M2 Suggested Work Split

| Person A (UI-focused)                          | Person B (Actions-focused)                    |
| ---------------------------------------------- | --------------------------------------------- |
| M2-F2 (payment badge), M2-F3 (cancelled + attendance badge) | M2-F1 (service expand + mock)                |
| M2-A1 (model), M2-A2 (detail), M2-A3 (row)    | M2-B1 (actions), M2-B2/B3 (action UI)        |
| Testing (badges, computed properties)           | M2-B4 (analytics) + testing (actions)         |

---

## Milestone 3 — Polish & Release (Feb 27)

### Phase 1: Foundation

#### M3-F1. POSBookingDateFilterState
**New file:** `PointOfSale/Models/POSBookingDateFilterState.swift`

Simple state model capturing the selected date and sort order. Defaults to today.

```swift
struct POSBookingDateFilterState {
    var selectedDate: Date  // defaults to today
    var sortOrder: BookingsRemote.Order  // .ascending (default) or .descending
}
```

Produces a `BookingFilters` with `startDateAfter` (start of selected day) and `startDateBefore` (end of selected day). Sort via `BookingsRemote.Order`.

#### M3-F2. POSDateFilteredBookingListFetchStrategy
**New file:** `Yosemite/PointOfSale/BookingList/POSDateFilteredBookingListFetchStrategy.swift`

Strategy that converts `POSBookingDateFilterState` into `BookingFilters` (date bounds) and passes the sort order to the service.

Update `POSBookingListFetchStrategyFactory` to produce date-filtered strategy.

---

### Phase 2: Parallel Streams

### Stream A: Filter UI + View Order

#### M3-A1. POSBookingDatePickerView
**New file:** `PointOfSale/Presentation/Bookings/POSBookingDatePickerView.swift`

Inline controls in the booking list header:
- **Date picker** — native SwiftUI `DatePicker` (`.datePickerStyle(.compact)`) for selecting a day. Defaults to today.
- **Sort toggle** — "Oldest first" (default, `.ascending`) / "Newest first" (`.descending`)

Changing either control immediately reloads bookings for the selected date with the chosen sort order.

#### M3-A2. POSBookingListView — add date picker and sort
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingListView.swift`

- Add `POSBookingDatePickerView` in list header (date picker + sort toggle)
- On date/sort change: switch strategy to `POSDateFilteredBookingListFetchStrategy`, reload

#### M3-A3. POSBookingListController — date filter support
**Modify:** `PointOfSale/Controllers/POSBookingListController.swift`

- Add `applyDateFilter(state: POSBookingDateFilterState)` method
- Switches fetch strategy via factory
- `resetDateFilter()` restores default strategy (today, ascending)

#### M3-A4. View related order — push POSOrderDetailsView directly

**Alternative to showing the full order list:** navigate directly to `POSOrderDetailsView` from booking detail. This is simpler, faster for the merchant, and avoids the need for M3-B1 (order list integration) as a prerequisite.

**How it works:**

`POSOrderDetailsView` requires two init parameters: `order: POSOrder` and `onBack: () -> Void`. It also reads these from the environment:
- `POSOrderListModel` — used for receipt sending and refund flow
- `\.horizontalSizeClass`, `\.siteTimezone`, `\.posAnalytics`, `\.posFeatureFlags`, `\.posCurrencyProvider`

All of these are already available to booking views — `PointOfSaleEntryPointView` injects `orderListModel` and all POS environment values at the root level (lines 190-203).

**Loading the order:** `POSOrderListService.loadOrder(orderID:)` fetches a single order by ID from the API and maps it to `POSOrder` via `POSOrderMapper` (handles all currency formatting). This method is exposed through `POSOrderListFetchStrategy.loadOrder(orderID:)`. The booking's `orderID` field provides the link.

**Implementation:**

**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

```swift
@Environment(POSOrderListModel.self) private var orderListModel

@State private var linkedOrder: POSOrder?
@State private var isLoadingOrder = false
@State private var showOrderDetail = false

func viewLinkedOrder() async {
    isLoadingOrder = true
    defer { isLoadingOrder = false }
    guard let orderID = booking.orderID else { return }
    do {
        linkedOrder = try await orderListModel.ordersController.fetchStrategy.loadOrder(orderID: orderID)
        showOrderDetail = true
    } catch {
        // show error notice
    }
}
```

Present via `.posFullScreenCover(isPresented: $showOrderDetail)`:
```swift
.posFullScreenCover(isPresented: $showOrderDetail) {
    if let linkedOrder {
        POSOrderDetailsView(order: linkedOrder, onBack: { showOrderDetail = false })
            .environment(orderListModel)
    }
}
```

**Required change:** Add `loadOrder(orderID:)` to `POSOrderListControllerProtocol` and implement in `POSOrderListController` (delegates to `fetchStrategy.loadOrder(orderID:)`). The fetch strategy is currently private, so the controller must expose this method.

**Notes:**
- `POSOrderListModel` is already in the environment (injected at `PointOfSaleEntryPointView`), so all environment dependencies are satisfied.
- Refund flow works out of the box via View Order — `POSOrderDetailsView` handles it internally via `orderListModel`. Direct "Issue Refund" from booking detail is covered in M3-A5.
- Receipt sending works because it only needs the `POSOrder` object, not list membership.
- No changes to `POSOrdersView`, `OrdersRemote`, or `POSOrder` model needed.

#### M3-A5. Issue Refund from booking detail

"Issue Refund" button on `POSBookingDetailView` — shown when `POSBookingPaymentStatus` is `.paid` AND booking has a linked `orderID`.

**Two implementation options to explore:**
1. **POC approach ([PR #16638](https://github.com/woocommerce/woocommerce-ios/pull/16638)):** Create `POSBookingRefundController` that fetches the order via `POSOrderProviding`, converts line items to `[POSRefundSelectableItem]`, manages selection state, and delegates to `POSRefundsServiceProtocol`. Reuses all existing refund modal screens (`POSRefundReviewView`, `POSRefundReasonView`, `POSRefundConfirmationView`, `POSRefundSuccessView`, `POSRefundErrorView`) and data types (`POSRefundReviewData`, `POSRefundableItem`). The POC duplicated `POSRefundItemsSelectionView` because it reads `@Environment(POSOrderListModel.self)` — decoupling that view to accept items + closures as parameters would eliminate the duplication.
2. **Deep linking:** Navigate from booking detail directly into the order detail's refund flow (e.g. open `POSOrderDetailsView` with the refund modal pre-triggered), avoiding new refund controller code entirely.

---

### Phase 3: Stabilization

#### M3-C1. End-to-end testing

Full regression across all milestones:
- M1: list → select → pay (card + cash) → receipt → done
- M2: badges → mark attended → cancel
- M3: filter → sort → view order → refund (via order detail + from booking detail)

#### M3-C2. Bug fixes and polish

Address issues found in testing. Focus areas:
- State management across payment → action → refresh cycles
- iPad layout at all split view sizes
- Dynamic type / accessibility
- Error recovery paths
- Feature flag: verify zero impact when flag is off

---

### M3 Dependency Graph

```
M3-F1 (Filter state) ── M3-F3 (Filter strategy) ── M3-A1 (Filter UI) ── M3-A2 (List update)
M3-F3 ── M3-A3 (Controller update)
M3-A4 (View order) ── no deps, can start immediately
M3-A5 (Issue refund) ── depends on M3-A4 (View order provides POSOrderProviding wiring)

M3-C1/C2 ── after all above
```

### M3 Suggested Work Split

| Person A (Filter UI-focused)                   | Person B (View Order + Refund + Polish)        |
| ---------------------------------------------- | --------------------------------------------- |
| M3-F1 (filter state)                           | M3-F3 (filter strategy)                       |
| M3-A1 (filter UI), M3-A2/A3 (list+controller)  | M3-A4 (view order), M3-A5 (issue refund)      |
| M3-C1 + M3-C2 (testing + polish)               | M3-C1 + M3-C2 (testing + polish)             |

---

## Edge Cases & Test Plan

### M1: Card Payment
| Scenario | Expected |
|----------|----------|
| Reader not connected | "Connect reader" CTA |
| Reader disconnects mid-payment | Error, auto-retry on reconnect |
| Card declined | Error + "Try Again" |
| Payment succeeds but `markBookingAsPaid` fails | Show success, log error |
| No linked order (`orderID == nil`) | "No order linked" state, disable pay |
| Already paid externally | Refresh shows "Paid", hide pay buttons |
| Network failure during order fetch | Error with retry |

### M1: Cash Payment
| Scenario | Expected |
|----------|----------|
| Amount < total | Button disabled |
| Amount = total | No change due |
| Amount > total | Show change due |
| Network failure | Error, allow retry |

### M1: Receipts
| Scenario | Expected |
|----------|----------|
| Booking receipt | Standard template (order not `created_via: pos_rest_api`) |
| Invalid email | Validation error |

### M1: Navigation
| Scenario | Expected |
|----------|----------|
| Payment success → Done | List refreshes, shows "Paid" |
| Close bookings during payment | Payment cancelled safely |
| iPad rotation during payment | Layout adapts, state preserved |
| Reopen bookings | Cached list shown while refreshing |

### M2: Attendance Updates
| Scenario | Expected |
|----------|----------|
| Unattended booking | "Mark Attended" button shown |
| Attended booking | "Mark Unattended" button shown |
| Cancelled booking | Attendance button hidden |
| Network failure on update | Error alert with retry |
| Two people update same booking simultaneously | Last write wins, refresh shows latest |
| Update attendance on booking with no linked order | Allowed (attendance is independent of payment) |
| Mark attended → then mark unattended | Both directions work, badge toggles |

### M2: Cancel Booking
| Scenario | Expected |
|----------|----------|
| Cancel paid booking | Confirmation warns payment exists, proceeds |
| Cancel already cancelled booking | Button hidden |
| Cancel during active payment | Payment must complete/cancel first |
| Network failure on cancel | Error alert with retry |

### M3: View Order
| Scenario | Expected |
|----------|----------|
| Booking has linked order | "View Order" button shown, loads order and opens detail |
| Booking has no linked order | "View Order" button hidden |
| Order fetch fails | Error notice with retry |

### M3: Refund from Booking Detail
| Scenario | Expected |
|----------|----------|
| Paid booking with linked order | "Issue Refund" button shown |
| Unpaid booking | "Issue Refund" button hidden |
| Cancelled booking | "Issue Refund" button hidden |
| Booking with no linked order | "Issue Refund" button hidden |
| Already fully refunded order | Refund flow detects and prevents double refund |
| Refund succeeds | Booking list refreshes to reflect updated status |

### M3: Date Picker & Sort
| Scenario | Expected |
|----------|----------|
| Select date with no bookings | Empty state with "No bookings for this date" |
| Change date then search | Search within selected date's bookings |
| Close and reopen bookings | Date resets to today, sort resets to ascending |
| Toggle sort order | Bookings reload with new sort order for the selected date |

---

## Key Files Reference

### M1 — New (all created from scratch on `trunk`)
- `Yosemite/Tools/POS/POSBookingService.swift`
- `Yosemite/PointOfSale/BookingList/POSBookingListFetchStrategy.swift`
- `Yosemite/PointOfSale/BookingList/POSDefaultBookingListFetchStrategy.swift`
- `Yosemite/PointOfSale/BookingList/POSSearchBookingListFetchStrategy.swift`
- `Yosemite/PointOfSale/BookingList/POSBookingListFetchStrategyFactory.swift`
- `PointOfSale/Models/POSBooking.swift`
- `PointOfSale/Models/POSBookingListState.swift`
- `PointOfSale/Models/POSBookingsModel.swift`
- `PointOfSale/Controllers/POSBookingListController.swift`
- `PointOfSale/Controllers/POSBookingPaymentController.swift`
- `PointOfSale/Presentation/Bookings/POSBookingsContainerView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingListView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingRowView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDetailsEmptyView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDetailsLoadingView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingStatusPresentation.swift`

### M1 — Modify (existing files on `trunk`)
- `PointOfSale/Presentation/TotalsView.swift` + related payment views — decouple cart-specific behaviors to enable booking reuse (see B1 for options)
- `Networking/Remote/BookingsRemote.swift` — ensure v2 endpoints are used
- `PointOfSale/Utils/POSReceiptSender.swift` — use `created_via` for template selection
- `PointOfSale/Presentation/PointOfSaleEntryPointView.swift` — wiring

### M2 — New
- `PointOfSale/Presentation/Bookings/POSBookingPaymentBadgeView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingCancelledBadgeView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingAttendanceBadgeView.swift`

### M2 — Modify
- `Yosemite/Tools/POS/POSBookingService.swift` — add mark attended + cancel methods
- `PointOfSale/Models/POSBooking.swift` — enriched properties + computed properties
- `PointOfSale/Models/POSBookingsModel.swift` — add action methods
- `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift` — enrichment + action buttons + confirmation modals
- `PointOfSale/Presentation/Bookings/POSBookingRowView.swift` — enriched display

### M3 — New
- `PointOfSale/Models/POSBookingDateFilterState.swift`
- `Yosemite/PointOfSale/BookingList/POSDateFilteredBookingListFetchStrategy.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDatePickerView.swift`

### M3 — Modify
- `PointOfSale/Presentation/Bookings/POSBookingListView.swift` — date picker and sort controls
- `PointOfSale/Controllers/POSBookingListController.swift` — date filter support
- `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift` — "View Order" button + "Issue Refund" button
- `PointOfSale/Controllers/POSOrderListController.swift` — expose `loadOrder(orderID:)` on protocol
- `PointOfSale/Presentation/Orders/Refund/POSRefundItemsSelectionView.swift` — decouple from `POSOrderListModel` (if POC approach chosen)

---

## WooCommerce Bookings API Reference (v2)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `wc-bookings/v2/bookings` | GET | List bookings (paginated, filterable, sortable) |
| `wc-bookings/v2/bookings/{id}` | PUT | Update booking (mark paid, update attendance, cancel) |
| `wc-bookings/v2/resources/{id}` | GET | Fetch resource (staff/equipment) |
| `wc/v3/orders/{id}` | GET | Fetch order for payment |
| `wc/v3/orders?include[]={ids}` | GET | Batch fetch orders for enrichment |

### Booking Response Fields (v2)
`id`, `start`, `end`, `all_day`, `status`, `cost`, `currency`, `customer_id`, `product_id`, `resource_id`, `date_created`, `date_modified`, `order_id`, `order_item_id`, `parent_id`, `person_counts`, `local_timezone`, `note`, `attendance_status`

Note: No customer name, product name, or resource name — these require separate order/resource fetches.

### Filters (v2)
- `product[]`, `customer[]`, `resource[]` — array of IDs
- `start_date_before`, `start_date_after` — ISO 8601 dates
- `booking_status[]` — payment/booking status array
- `attendance_status` — single string: `attended` or `unattended` (binary filter on server)
- `orderby`: `start_date` or `cost`
- `order`: `ASC` or `DESC`
- `search`: customer name search

### API Status Values

The API `status` field combines booking lifecycle and payment semantics into a single field:
`unpaid` · `pending-confirmation` · `confirmed` · `paid` · `cancelled` · `complete` · `in-cart`

These map to `BookingStatus` enum in `Networking/Model/Bookings/Booking.swift`:
`complete` · `paid` · `unpaid` · `cancelled` · `pendingConfirmation` · `confirmed` · `unknown`

The API `attendance_status` field has two values:
`attended` · `unattended`

These map to `BookingAttendanceStatus` enum (current values differ from API — existing app code):
`booked` · `checkedIn` · `cancelled` · `noShow` · `unknown`

**POS presentation** interprets these into three display dimensions (see Architecture Decisions > Status Presentation Model):
- Booking lifecycle: Booked / Completed / Cancelled
- Payment status: Paid / Unpaid
- Attendance: Attended / Unattended

