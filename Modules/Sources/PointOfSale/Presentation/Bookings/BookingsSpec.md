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

**Booking Detail (right pane)**
- Selecting a booking shows its details: service, date/time, customer, resource (staff), amount
- Payment action button: "Collect Payment"
- Button hidden when booking is already paid or cancelled
- State for bookings with no linked order (payment not possible)

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
- Booking orders use the **standard WooCommerce receipt template** (not the POS-specific template)

**Data Enrichment**
- Booking API returns raw IDs only (customer_id, product_id, resource_id, order_id)
- Service enriches bookings by batch-fetching linked orders (`ordersRemote.loadOrders(for:orderIDs:)`) and resources in parallel
- Customer name + service/product name come from the order enrichment (`BookingOrderInfo`)
- Resource/staff name comes from separate resource fetch

### Milestone 2 — Booking Management (Feb 20)
**Goal:** Make bookings actionable and understandable for merchants.

**Status Badges**
- Payment status badge: color-coded for unpaid (warning), paid/complete (info), cancelled (error), pending/confirmed (default)
- Attendance status badge: color-coded for booked (default), checked-in (success), no-show (error), cancelled (muted)
- Both displayed in booking detail and list rows

**Booking Detail Enrichment**
- Duration (formatted from start/end, e.g. "1h 30m")
- Time range (e.g. "9:00 AM – 10:30 AM")
- Booking notes
- Customer email and phone (from order billing address)
- Sections: service summary → status badges → customer info → notes → payment breakdown → actions

**Booking List Enrichment**
- Attendance badge next to payment badge in each row
- Resource name (staff) visible if available
- More visible time range

**Update Attendance Status**
- "Check In" button — shown when `canCheckIn` (status is confirmed/paid AND attendance is booked)
- "No Show" button — shown when `canCheckIn`
- Both require `.posModal()` confirmation dialog before executing
- On success: badge updates, list row refreshes
- On failure: error alert with retry

**Cancel Booking**
- "Cancel Booking" button — destructive style, shown when `canCancel` (status is NOT cancelled/complete)
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
- Presents `POSOrdersView` as `.posFullScreenCover` on top of bookings (same pattern as orders from POS floating menu)
- Pre-selects the linked order in the orders list
- Requires booking orders to be visible in POS order list (see below)

**Refunds**
- Handled via the orders view — when user taps "View Order", the `POSOrderDetailsView` already has the complete refund flow
- No separate "Refund" button on booking detail view
- Refund flow: select items → reason → review → confirm → success (all existing)

**Sort & Filter**
- Full filter parity with the main app Bookings tab (5 filter types):
  1. Team Member (resource) — picker that fetches available resources
  2. Service / Event (product) — picker that fetches bookable products
  3. Attendance Status — multi-select from booked/checkedIn/noShow/cancelled
  4. Customer — picker that fetches/searches customers
  5. Date & Time — custom date range with from/to pickers
- Sort by date only: "Newest to Oldest" / "Oldest to Newest" (matching main app Bookings tab — `BookingListViewModel.SortBy` only supports date sorting by `startDate`)
- SwiftUI POS-styled rebuild (existing Bookings tab uses UIKit `FilterListViewController`)
- Reuse existing data models: `BookingTeamMemberFilter`, `BookingProductFilter`, `BookingCustomerFilter`, `BookingDateRangeFilter`
- Sort handled via `BookingsRemote.Order` enum (`.ascending`/`.descending`) — no changes to `BookingFilters` needed
- Filter button in list header with active filter count badge
- "Apply" + "Reset" buttons
- Empty state: "No bookings match filters" with clear button
- Filters reset to default (today) when bookings is closed and reopened

**Order List Integration**
- Show booking orders in the POS order list alongside POS orders
- Change `created_via` parameter from `"pos-rest-api"` to `["pos-rest-api", "bookings"]` when `.pointOfSaleBookings` flag is enabled
- WC REST API `created_via` parameter natively supports arrays (`type: array`, `compare: IN`)
- Apply to both `loadPOSOrders()` and `searchPOSOrders()` in `OrdersRemote`
- Add `createdVia` field to `POSOrder` model for visual distinction
- Show "Booking" indicator on booking-originated order rows
- Customer-checkout bookings (`created_via: "checkout"` or `"store-api"`) are too broad — these values are shared by all WooCommerce orders, not just bookings. Only include admin/API-created (`"bookings"`). **Needs clarification:** whether customer-created booking orders should also appear in the POS order list, and if so, how to distinguish them.

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
- M2 booking actions (check-in, no-show, cancel) are methods on this model directly

### Strategies Pattern (like Products/Orders)
- `POSBookingListFetchStrategy` protocol — remote-first, pluggable for local later
- `POSBookingListFetchStrategyFactory` — produces default, search, and filtered strategies
- Default strategy fetches today's bookings; search strategy passes search query; filtered strategy builds from `POSBookingFilterState`
- Start with remote-only via `BookingsRemote`, via a new service in Yosemite providing an async/await interface. Consider adding async networking functions too, if needed.

### Payment: Reuse `PointOfSalePaymentState`
Reuse the production payment states:
- `PointOfSaleCardPaymentState` (11 states: idle, acceptingCard, cardInserted, preparingReader, processingPayment, paymentError, cardPaymentSuccessful, validatingOrder, validatingOrderError, paymentIntentCreationError)
- `PointOfSaleCashPaymentState` (idle, collectingCash, paymentSuccess)
- Combined via `PointOfSalePaymentState` struct

These drive UI identically to TotalsView (background colors, full-screen states, inline messages).

### Payment Flow Differences from POS Products

|                    | POS Products                              | POS Bookings                                  |
| ------------------ | ----------------------------------------- | --------------------------------------------- |
| Order              | Created during checkout (`syncOrder`)     | Fetched by order ID from booking              |
| **Cart**           | **Cart, Checkout button tapped → order synced (created)** | **Collect Payment button tapped — booking already has an order, fetch it** |
| Payment UI         | Driven by `PointOfSaleAggregateModel`     | Driven by `POSBookingsModel`                  |
| Receipt            | POS receipt template                      | Standard receipt template (non-POS order)     |
| Reader reconnect   | Subscription-based auto-collect           | Same subscription-based pattern               |

### Navigation
- Bookings opens as `.posFullScreenCover` from floating menu (same as Orders)
- Uses `CustomNavigationSplitView` (used by `POSOrdersView`)
- Left: booking list, Right: booking detail / payment
- "View Order" (M3): presents `POSOrdersView` as `.posFullScreenCover` on top of bookings

### Booking Orders
- Admin-created bookings: `created_via: "bookings"`
- Customer-created bookings: `created_via: "checkout"` (classic checkout) or `"store-api"` (block-based checkout) — **needs clarification:** it's unclear whether we need to include these in the POS order list, and which values to filter on. The `"checkout"` and `"store-api"` values are shared by all WooCommerce orders, not just bookings.
- POS orders: `created_via: "pos-rest-api"`

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
- `BookingFilters` — supports productIDs, customerIDs, resourceIDs, dates, attendanceStatuses, paymentStatuses
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

Simple struct for booking display. Properties: id, customerName, serviceName, startDate, endDate, amount (formatted), status, attendanceStatus, orderID, resourceName. No cart-related properties. Reuses `PointOfSalePaymentState` for payment — no separate `POSBookingPaymentState`.

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

- Sections: booking info, status badges, customer, payment breakdown, action buttons
- Contextual states: paid → checkmark, cancelled → label, noLinkedOrder → explanation, unpaid with order → collect payment button

#### A8. Empty/Loading/Error views
**New files:** `POSBookingDetailsEmptyView.swift`, `POSBookingDetailsLoadingView.swift`

#### A9. Entry point wiring
**Modify:** `PointOfSale/Presentation/PointOfSaleEntryPointView.swift`

Pass strategy factory to booking list controller. `POSFloatingControlView` already has bookings button behind `.pointOfSaleBookings`.

---

### Stream B: Payment & Checkout

#### B1. POSBookingPaymentController — full payment state machine
**New file:** `PointOfSale/Controllers/POSBookingPaymentController.swift`

```swift
@MainActor @Observable
final class POSBookingPaymentController {
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus
    let booking: POSBooking
}
```

**Key methods (mirror AggregateModel):**
- `startPaymentWhenCardReaderConnected()` — subscription-based: if connected, collect immediately; otherwise subscribe to connection status and collect on connect
- `collectCardPayment()` — fetch order via `orderProvider.fetchOrder(siteID:orderID:)`, then `cardPaymentFacade.collectPayment(for:using:channel:)`
- `cancelThenCollectPayment()` — cancel current and retry
- `publishPaymentMessages()` — 3 subscription chains:
  1. Events → `cardPresentPaymentAlertViewModel` (modals)
  2. Events → `cardPresentPaymentInlineMessage` (inline)
  3. Events → `paymentState.card` via `PointOfSaleCardPaymentState(from:using:)`
- On `cardPaymentSuccessful`: call `bookingService.markBookingAsPaid()`
- Even though the order exists, we still need `validatingOrder` phase, as the card payment service will check it is payable.

**Key differences from AggregateModel:**
- `validatingOrderError` CAN happen (order fetch failure)
- No order creation, no cart, no order stage
- Error action closures reset to idle and go back to the booking (no "new order" or "edit order" concepts.) We need to make the button text modifiable for the context.

**Cash methods:**
- `startCashPayment()` — cancel card, set `cash = .collectingCash`
- `cancelCashPayment()` — set `cash = .idle`, resume card if connected
- `collectCashPayment(changeDueAmount:)` — mark paid, set `cash = .paymentSuccess`

**Reader reconnection:** subscription-based (like AggregateModel)

**Reuses:**
- `PointOfSaleCardPaymentState(from:using:)` initializer
- `PointOfSaleCardPresentPaymentEventPresentationStyle`
- `CardPresentPaymentFacade`
- Subscription patterns from `PointOfSaleAggregateModel` lines 352-654

#### B2. POSBookingPaymentView — card payment UI
**New file:** `PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift`

State-driven rendering based on `paymentState.card`:
- `idle/preparingReader/acceptingCard/cardInserted` — inline messages + booking amount
- `processingPayment` — purple background
- `paymentError` — error with retry
- `cardPaymentSuccessful` — "Email Receipt" + "Done"

Uses: `PointOfSaleCardPresentPaymentInLineMessage`, `PointOfSaleCardPresentPaymentAlert`, `PointOfSaleCardPresentPaymentReaderDisconnectedMessageView`

#### B3. POSBookingCashPaymentView
**New file:** `PointOfSale/Presentation/Bookings/POSBookingCashPaymentView.swift`

- Closure-based actions (no `@Environment(PointOfSaleAggregateModel.self)`)
- `FormattableAmountTextField` + `CollectCashViewHelper` for currency/change
- Success state with receipt sending

**Mirrors:** `PointOfSaleCollectCashView.swift` but with closures

#### B4. Receipt handling — standard template for bookings
**Modify:** `PointOfSale/Utils/POSReceiptSender.swift`

Add `isBookingOrder: Bool = false` parameter. When `true`, force `isEligibleForPOSReceipt = false` to use standard receipt template instead of POS template.

---

### Phase 3: Convergence

#### C1. Wire payment into POSBookingsContainerView
- Create `POSBookingPaymentController` when user taps "Pay by Card" / "Pay by Cash"
- On success → dismiss → refresh list → booking shows "Paid"
- Receipt sending uses `isBookingOrder: true`

#### C2. Entry point wiring
- Strategy factory + all dependencies injected in `PointOfSaleEntryPointView`

---

### M1 Dependency Graph

```
F1 (Service + enrichment) ──┬── F2 (Mock)
                                  ├── A1 (Strategies) → A2 (Controller) → A5 (ListView) → A4 (Container)
                                  ├── B1 (Payment controller) → B2 (Payment view) → B3 (Cash view)
                                  └── B4 (Receipt)

F3 (List state)  ─── A2 (Controller)
F4 (Booking model) ── A2 (Controller), B1 (Payment controller)

A6, A7, A8 ─── no deps, start immediately

C1 (Wire payment) ─── after A4 + B2 + B3 + B4
C2 (Entry point) ─── after A2 + A1
```

### M1 Suggested Work Split

| Person A (UI-focused)                         | Person B (Payment-focused)                    |
| --------------------------------------------- | --------------------------------------------- |
| F3 (list state), F4 (model)                   | F1 (service + enrichment), F2 (mock)          |
| A6 (row), A7 (detail), A8 (empty/loading)     | B1 (payment controller)                       |
| A1 (strategies) → A2 (controller)             | B2 (payment view) → B3 (cash view)            |
| A5 (list) → A4 (container) → A3 (model)       | B4 (receipt)                                  |
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

#### M2-F2. POSBookingStatusBadgeView — payment status
**New file:** `PointOfSale/Presentation/Bookings/POSBookingStatusBadgeView.swift`

Color-coded badge for `BookingStatus`:
- `unpaid` → `.posWarningLowest` bg, `.posOnWarningLowest` text
- `paid` / `complete` → `.posInfoLowest` bg, `.posOnInfoLowest` text
- `cancelled` → `.posErrorLowest` bg, `.posOnErrorLowest` text
- `pendingConfirmation` / `confirmed` → `.posDefault` bg, `.posOnDefault` text

Uses `.posCaptionRegular` font, `POSPadding.small`/`.xSmall`, `POSCornerRadiusStyle.small`.

**Mirrors:** `PointOfSale/Presentation/Orders/POSOrderBadgeView.swift`

#### M2-F3. POSBookingAttendanceBadgeView — attendance status
**New file:** `PointOfSale/Presentation/Bookings/POSBookingAttendanceBadgeView.swift`

Color-coded badge for `BookingAttendanceStatus`:
- `booked` → `.posDefault` bg, `.posOnDefault` text
- `checkedIn` → `.posSuccessLowest` bg, `.posOnSuccessLowest` text
- `noShow` → `.posErrorLowest` bg, `.posOnErrorLowest` text
- `cancelled` → muted/grey

**Existing enums:**
- `BookingAttendanceStatus` at `Networking/Model/Bookings/Booking.swift` — booked, checkedIn, cancelled, noShow, unknown
- `BookingStatus` at same file — complete, paid, unpaid, cancelled, pendingConfirmation, confirmed, unknown

---

### Phase 2: Parallel Streams

### Stream A: Detail & List Enrichment

#### M2-A1. POSBooking model enrichment
**Modify:** `PointOfSale/Models/POSBooking.swift`

Add properties:
- `duration: String` (formatted from start/end, e.g. "1h 30m")
- `timeRange: String` (e.g. "9:00 AM – 10:30 AM")
- `notes: String`
- `customerEmail: String?`
- `customerPhone: String?`

Add computed properties:
- `canCheckIn: Bool` — true when status is confirmed/paid AND attendance is booked
- `canCancel: Bool` — true when status is NOT cancelled/complete
- `canCollectPayment: Bool` — true when unpaid/pendingConfirmation AND has orderID

All new data comes from existing enrichment (order billing address for email/phone, booking fields for dates/notes). No additional API calls.

#### M2-A2. POSBookingDetailView enrichment
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

Sections (top to bottom):
1. **Service summary** — service name, date, time range, duration, resource
2. **Status badges** — payment status + attendance status side by side
3. **Customer info** — name, email, phone
4. **Notes** — booking notes (if any)
5. **Payment breakdown** — booking cost, any existing payments
6. **Actions** — Pay by Card, Pay by Cash (from M1), Check In, No Show, Cancel

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
func checkIn(booking: POSBooking) async throws
func markNoShow(booking: POSBooking) async throws
func cancelBooking(booking: POSBooking) async throws
```

- Calls `POSBookingServiceProtocol.updateAttendanceStatus()` / `.cancelBooking()`
- On success: calls `updateBooking(bookingID:)` to refresh the specific booking in list + detail
- On failure: surfaces error to UI
- Analytics events: `booking_checked_in`, `booking_marked_no_show`, `booking_cancelled`

#### M2-B2. Attendance update UI
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

- "Check In" button — shown when `canCheckIn`, `.posModal()` confirmation dialog, calls bookingsModel
- "No Show" button — shown when `canCheckIn`, `.posModal()` confirmation dialog
- On success: badge updates inline, list row updates via `updateBooking()`
- On failure: error alert with retry

**Confirmation pattern:** Uses `.posModal()` modifier (not native `.alert()` or `.confirmationDialog()`) — matches POS design patterns (e.g. `POSRefundConfirmationView`).

#### M2-B3. Cancel booking UI
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

- "Cancel Booking" button — destructive style, shown when `canCancel`
- `.posModal()` confirmation: "Cancel this booking? This cannot be undone."
- On success: booking shows cancelled state, payment buttons hidden, list updates
- On failure: error alert with retry

#### M2-B4. Analytics for booking actions
**Modify:** Analytics tracking via `POSAnalyticsProviding`

Events:
- `booking_detail_viewed` — when detail pane shows a booking
- `booking_checked_in` — attendance updated to checkedIn
- `booking_marked_no_show` — attendance updated to noShow
- `booking_cancelled` — booking cancelled

---

### Phase 3: Convergence

#### M2-C1. Testing
- Unit tests for booking actions (check-in, no-show, cancel, error handling)
- Unit tests for badge color mapping
- Unit tests for `canCheckIn`/`canCancel`/`canCollectPayment` computed properties
- Manual: verify badge colors, action flows, list refresh after status change

---

### M2 Dependency Graph

```
M2-F1 (Service expand) ── M2-B1 (Actions on model) ── M2-B2/B3 (Action UI)
M2-F2 (Status badge) ──┐
M2-F3 (Attendance badge) ┼── M2-A2 (Detail enrichment)
M2-A1 (Model enrichment) ┘
M2-A1 ── M2-A3 (Row enrichment)
```

### M2 Suggested Work Split

| Person A (UI-focused)                          | Person B (Actions-focused)                    |
| ---------------------------------------------- | --------------------------------------------- |
| M2-F2 (status badge), M2-F3 (attendance badge) | M2-F1 (service expand + mock)                |
| M2-A1 (model), M2-A2 (detail), M2-A3 (row)    | M2-B1 (actions), M2-B2/B3 (action UI)        |
| Testing (badges, computed properties)           | M2-B4 (analytics) + testing (actions)         |

---

## Milestone 3 — Polish & Release (Feb 27)

### Phase 1: Foundation

#### M3-F1. POSBookingFilterState
**New file:** `PointOfSale/Models/POSBookingFilterState.swift`

```swift
struct POSBookingFilterState: Equatable {
    var teamMembers: [BookingTeamMemberFilter]
    var products: [BookingProductFilter]
    var attendanceStatuses: [BookingAttendanceStatus]
    var customers: [BookingCustomerFilter]
    var dateRange: BookingDateRangeFilter?
    var sortOrder: BookingsRemote.Order  // .ascending (oldest first) or .descending (newest first)
}
```

Sort is always by `startDate` — matching the main app's Bookings tab behavior. No `BookingSortOption` enum needed.

Reuses existing data models from the main app Bookings tab:
- `BookingTeamMemberFilter` (name + resourceID)
- `BookingProductFilter` (name + productID)
- `BookingCustomerFilter` (name + customerID)
- `BookingDateRangeFilter` (startDate + endDate)
- `BookingAttendanceStatus` enum

#### M3-F2. ~~Add `orderby` to BookingFilters~~ (No longer needed)

Sort is handled by the existing `BookingsRemote.Order` enum (`.ascending`/`.descending`) which `loadAllBookings()` already accepts as its `order:` parameter. Sort is always by `startDate`, matching the main app. No changes to `BookingFilters` or `BookingsRemote` are needed.

#### M3-F3. POSFilteredBookingListFetchStrategy
**New file:** `Yosemite/PointOfSale/BookingList/POSFilteredBookingListFetchStrategy.swift`

New strategy that builds `BookingFilters` from `POSBookingFilterState`:
- Maps `teamMembers` → `BookingFilters.resourceIDs`
- Maps `products` → `BookingFilters.productIDs`
- Maps `customers` → `BookingFilters.customerIDs`
- Maps `attendanceStatuses` → `BookingFilters.attendanceStatuses`
- Maps `dateRange` → `startDateBefore`/`startDateAfter`
- Maps `sortOrder` → `BookingsRemote.Order` (`.ascending`/`.descending`) — always sorts by `startDate`

Update `POSBookingListFetchStrategyFactory` to produce filtered strategy.

---

### Phase 2: Parallel Streams

### Stream A: Filter UI + View Order

#### M3-A1. POSBookingFilterView
**New file:** `PointOfSale/Presentation/Bookings/POSBookingFilterView.swift`

Sheet or inline panel with all 5 filter types (matching Bookings tab):
1. **Team Member** — picker fetches available resources
2. **Service / Event** — picker fetches bookable products
3. **Attendance Status** — multi-select from booked/checkedIn/noShow/cancelled
4. **Customer** — picker fetches/searches customers
5. **Date & Time** — date range picker (can adapt existing `BookingDateTimeFilterView` which is SwiftUI)

Plus sort controls:
- Sort by date: "Newest to Oldest" (default) / "Oldest to Newest"
- Maps to `BookingsRemote.Order` (`.descending`/`.ascending`)

"Apply" + "Reset" buttons. Active filter count shown on filter button in list header.

**Existing data models to reuse:**
- `BookingTeamMemberFilter`, `BookingProductFilter`, `BookingCustomerFilter`, `BookingDateRangeFilter`
- `BookingDateTimeFilterView` (SwiftUI, potentially adaptable to POS styling)
- `BookingFiltersViewModel.BookingListFilter` enum + `createViewModel()` pattern
- Note: The main app filter UI uses UIKit `FilterListViewController` — POS needs SwiftUI rebuild

#### M3-A2. POSBookingListView — add filter button
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingListView.swift`

- Add filter icon button next to search icon in header
- Show active filter count badge
- Present `POSBookingFilterView` as sheet
- On apply: switch strategy to `POSFilteredBookingListFetchStrategy`, reload

#### M3-A3. POSBookingListController — filter strategy support
**Modify:** `PointOfSale/Controllers/POSBookingListController.swift`

- Add `applyFilters(state: POSBookingFilterState)` method
- Switches fetch strategy via factory
- Caches current results before filter (like search does)
- `clearFilters()` restores default strategy

#### M3-A4. View related order — present POSOrdersView
**Modify:** `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

- Add "View Order" button when booking has a linked order and order is visible in POS order list
- Present `POSOrdersView` as `.posFullScreenCover` on top of bookings
- `POSOrderListModel` is `@Observable` and propagates through `.fullScreenCover` automatically
- Add `preselectedOrderID` parameter to `POSOrdersView` — after orders load, select matching order instead of first
- Requires M3-B1 (booking orders in POS order list) so the order is actually in the list

**Modify:** `PointOfSale/Presentation/Orders/POSOrdersView.swift`
- Add optional `preselectedOrderID: Int64?` parameter
- After orders load, if set, find and select that order

### Stream B: Order List Integration

#### M3-B1. Show booking orders in POS order list
**Modify:** `Modules/Sources/NetworkingCore/Remote/OrdersRemote.swift`

Current filter is hardcoded:
```swift
ParameterValues.posFilter = "pos-rest-api"
```

When `.pointOfSaleBookings` is enabled, include booking orders:
- Change `created_via` parameter to array: `["pos-rest-api", "bookings"]`
- WC REST API `created_via` is `type: array` with `compare: IN` — supports this natively
- Apply to both `loadPOSOrders()` and `searchPOSOrders()`

**Note:** Customer-checkout bookings use `created_via: "checkout"` (classic) or `"store-api"` (block checkout) — these are shared by all WooCommerce orders, not just bookings. Only admin/API-created booking orders (`"bookings"`) should appear. **Needs clarification:** whether customer-created booking orders should also be included and how to identify them.

#### M3-B2. POSOrder model — add createdVia field
**Modify:** `Modules/Sources/Yosemite/PointOfSale/OrderList/POSOrder.swift`

- Add `createdVia: String` field
- `POSOrderMapper` already maps from `Order` → `POSOrder` — add this field

#### M3-B3. POSOrderRowView — identify booking orders
**Modify:** `PointOfSale/Presentation/Orders/POSOrderRowView.swift`

- Add visual "Booking" indicator for orders where `createdVia == "bookings"`
- Small label or icon next to the order number

---

### Phase 3: Stabilization

#### M3-C1. End-to-end testing

Full regression across all milestones:
- M1: list → select → pay (card + cash) → receipt → done
- M2: badges → check-in → no-show → cancel
- M3: filter → sort → view order → refund (via order view) → order list integration

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

M3-B1 (Order list filter) ── M3-B2 (POSOrder field) ── M3-B3 (Row indicator)
M3-B1 ── M3-A4 (View order — needs booking orders visible)

M3-C1/C2 ── after all above
```

### M3 Suggested Work Split

| Person A (Filter UI-focused)                   | Person B (Integration-focused)                |
| ---------------------------------------------- | --------------------------------------------- |
| M3-F1 (filter state)                           | M3-F3 (filter strategy)                       |
| M3-A1 (filter UI), M3-A2/A3 (list+controller)  | M3-B1 (order list), M3-B2/B3 (order model/row) |
| M3-A4 (view order wiring)                       |                                               |
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
| Booking receipt | Standard template (NOT POS) |
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
| Check in already checked-in booking | Button hidden (not applicable) |
| Check in cancelled booking | Button hidden |
| Network failure on check-in | Error alert with retry |
| Two people check in same booking simultaneously | Last write wins, refresh shows latest |
| Check in booking with no linked order | Allowed (attendance is independent of payment) |

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
| Booking has linked order visible in list | "View Order" button shown, opens orders view |
| Booking order not in list (flag off) | "View Order" button hidden or disabled |
| Order not found after navigation | Graceful handling, fallback to first order |

### M3: Sort & Filter
| Scenario | Expected |
|----------|----------|
| Filter returns no results | Empty state with "No bookings match filters" + clear button |
| Apply filter then search | Search within filtered results |
| Close and reopen bookings | Filters reset to default (today) |
| Filter by resource when no resources | Resource filter hidden or empty |

### M3: Order List Integration
| Scenario | Expected |
|----------|----------|
| Booking order appears in POS order list | Shows with "Booking" indicator |
| Tap booking order in order list | Shows standard order detail (not booking detail) |
| Feature flag off | Only "pos-rest-api" orders shown (no change) |

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
- `PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingCashPaymentView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDetailsEmptyView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingDetailsLoadingView.swift`

### M1 — Modify (existing files on `trunk`)
- `Networking/Remote/BookingsRemote.swift` — ensure v2 endpoints are used
- `PointOfSale/Utils/POSReceiptSender.swift` — booking order flag
- `PointOfSale/Presentation/PointOfSaleEntryPointView.swift` — wiring

### M2 — New
- `PointOfSale/Presentation/Bookings/POSBookingStatusBadgeView.swift`
- `PointOfSale/Presentation/Bookings/POSBookingAttendanceBadgeView.swift`

### M2 — Modify
- `Yosemite/Tools/POS/POSBookingService.swift` — add attendance + cancel methods
- `PointOfSale/Models/POSBooking.swift` — enriched properties + computed properties
- `PointOfSale/Models/POSBookingsModel.swift` — add action methods
- `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift` — enrichment + action buttons + confirmation modals
- `PointOfSale/Presentation/Bookings/POSBookingRowView.swift` — enriched display

### M3 — New
- `PointOfSale/Models/POSBookingFilterState.swift`
- `Yosemite/PointOfSale/BookingList/POSFilteredBookingListFetchStrategy.swift`
- `PointOfSale/Presentation/Bookings/POSBookingFilterView.swift`

### M3 — Modify
- `NetworkingCore/Remote/OrdersRemote.swift` — array created_via for booking orders
- `Yosemite/PointOfSale/OrderList/POSOrder.swift` — add createdVia field
- `Yosemite/PointOfSale/OrderList/POSOrderMapper.swift` — map createdVia
- `PointOfSale/Presentation/Bookings/POSBookingListView.swift` — filter button
- `PointOfSale/Controllers/POSBookingListController.swift` — filter strategy support
- `PointOfSale/Presentation/Bookings/POSBookingDetailView.swift` — "View Order" button
- `PointOfSale/Presentation/Orders/POSOrdersView.swift` — preselectedOrderID parameter
- `PointOfSale/Presentation/Orders/POSOrderRowView.swift` — booking order indicator

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

### Booking Statuses
`unpaid` · `pending-confirmation` · `confirmed` · `paid` · `complete` · `cancelled` · `in-cart`

### Attendance Statuses
`booked` · `checked-in` · `no-show` · `cancelled`

### Orders API: created_via
`created_via` parameter: `type: array`, `sanitize_callback: wp_parse_list`, `compare: IN`
Supports: `["pos-rest-api", "bookings"]` for combined POS + booking orders.
