# POS Bookings Payment Feature

## Overview

Add a "Bookings" option to the POS floating menu that opens a list of today's bookings. Merchants can tap a booking to see details and collect card or cash payment for unpaid bookings.

**Key constraint:** All bookings are created on the web. POS is for viewing and collecting payment only.

## Architecture

### Design Principles

- Self-contained within POS patterns (controllers, services, protocol injection)
- Completely separate from cart-based checkout flow
- Shares styling and `CardPresentPaymentFacade` with checkout, but no state or views
- Wraps existing `BookingStore` via new `POSBookingService`

### Data Flow

```
BookingStore (existing)
    ↓
POSBookingService (new protocol in Yosemite)
    ↓
POSBookingListController (new in POS)
    ↓
POSBookingListView (new in POS)
```

### New Models

```swift
// Simplified booking for POS display
struct POSBooking {
    let bookingID: Int64
    let orderID: Int64?          // Needed for payment
    let customerName: String
    let serviceName: String
    let startTime: Date
    let amount: String           // Formatted currency
    let status: POSBookingStatus
}

enum POSBookingStatus {
    case unpaid
    case paid
    case cancelled
    case noLinkedOrder           // Edge case: can't collect payment
}
```

### List State

```swift
enum POSBookingListState: Equatable {
    case loading
    case loaded([POSBooking])
    case empty                   // No bookings today
    case error(PointOfSaleErrorState)
}
```

### Service Protocol

```swift
protocol POSBookingServiceProtocol {
    func fetchTodaysBookings(siteID: Int64) async throws -> [POSBooking]
    func collectPayment(for booking: POSBooking, siteID: Int64) async throws
    func markBookingAsPaid(bookingID: Int64, siteID: Int64) async throws
}
```

## User Interface

### Entry Point

Add "Bookings" item to the existing `...` floating menu, parallel to "Orders". Same access pattern, separate list view.

### Bookings List (`POSBookingListView`)

**Features:**
- Pull-to-refresh to reload today's bookings
- Ghost loading rows during fetch
- Empty state: "No bookings today"
- Sorted chronologically by start time (earliest first)

**Booking Row Layout:**

```
┌─────────────────────────────────────────────────┐
│  Jane Smith                             $50.00  │
│  [Unpaid] · Haircut · 2:30 PM                   │
└─────────────────────────────────────────────────┘
```

- Top row: Customer name (left), amount (right)
- Bottom row: Status badge (left), service + time (right of badge)
- Selected row gets 2px `posOnSurface` border (matching orders pattern)

**Filtering:**
- Shows today's bookings only
- All statuses shown (unpaid, paid, cancelled, no linked order)

### Booking Detail (`POSBookingDetailView`)

Focused detail screen for confirming and collecting payment:

```
┌─────────────────────────────────────────────────┐
│  ← Back                                         │
│                                                 │
│  Jane Smith                                     │
│  Haircut                                        │
│                                                 │
│  Today, 2:30 PM                                 │
│                                                 │
│  ─────────────────────────────────────────────  │
│                                                 │
│  Total                                  $50.00  │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │           Pay by Card                   │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Components:**
- Back button (compact size class only)
- Customer name: large, prominent
- Service name: secondary text
- Date/time: formatted as "Today, 2:30 PM"
- Total amount: right-aligned
- "Pay by Card" button: `POSFilledButtonStyle`
- "Pay by Cash" button: `POSOutlinedButtonStyle`

**Contextual States (instead of payment buttons):**

| Booking Status | Display |
|----------------|---------|
| `paid` | "Payment Complete" label with checkmark icon |
| `cancelled` | "Booking Cancelled" label, muted styling |
| `noLinkedOrder` | "No order linked to this booking" explanation text |

## Payment Flow

### Payment States

```swift
enum POSBookingPaymentState: Equatable {
    case ready              // "Tap, insert, or swipe card"
    case processing         // "Processing payment..."
    case success            // Checkmark + "Payment successful"
    case error(String)      // Error message + "Try Again" button
}
```

### Card Payment Screen (`POSBookingPaymentView`)

Full-screen takeover:

```
┌─────────────────────────────────────────────────┐
│                                                 │
│                                                 │
│              [Card Reader Icon]                 │
│                                                 │
│          Tap, insert, or swipe card             │
│                                                 │
│                   $50.00                        │
│                                                 │
│                                                 │
│           ┌─────────────────────┐               │
│           │       Cancel        │               │
│           └─────────────────────┘               │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Cash Payment Flow

Uses existing `PointOfSaleCashPaymentState` patterns:
1. Enter amount tendered
2. Show change due
3. Confirm payment
4. Mark booking as paid

### Payment Process

1. Screen appears in `ready` state
2. `CardPresentPaymentFacade.collectPayment()` called with the booking's linked order
3. UI updates based on `CardPresentPaymentEvent` from the facade
4. On success: call `markBookingAsPaid()`, transition to `success` state
5. Success screen shows checkmark animation + receipt/done options

**Cancel:** Calls `CardPresentPaymentFacade.cancelPayment()` and dismisses to booking detail.

### Success Screen

```
┌─────────────────────────────────────────────────┐
│                                                 │
│                    ✓                            │
│                                                 │
│            Payment Successful                   │
│                  $50.00                         │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │          Email Receipt                  │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │              Done                       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

- "Email Receipt" opens existing `POSSendReceiptView`
- "Done" dismisses and returns to bookings list

## Error Handling

### Payment Errors

| Scenario | Handling |
|----------|----------|
| Card declined | Show error message + "Try Again" button |
| Reader disconnected | Show error + "Try Again" |
| Network failure | Show error + "Try Again" |
| Order already paid | Show "This order has already been paid" + "Done" |

### List Errors

| Scenario | Handling |
|----------|----------|
| Network failure on load | Full-screen error with "Retry" button |
| Network failure on refresh | Inline error, preserve existing list |

### Edge Cases

| Scenario | Handling |
|----------|----------|
| Booking's order was deleted | `noLinkedOrder` status on detail screen |
| Booking paid outside POS | Refresh shows updated "Paid" status |
| No bookings today | Empty state with illustration |

### Partial Failure

If `markBookingAsPaid` fails after payment succeeds:
- Log the error silently
- Show success (payment is the critical path)
- Merchant can update booking status in main app if needed

## File Structure

### New Files (POS Module)

```
Modules/Sources/PointOfSale/
├── Controllers/
│   ├── POSBookingListController.swift
│   └── POSBookingPaymentController.swift
├── Models/
│   ├── POSBooking.swift
│   ├── POSBookingListState.swift
│   └── POSBookingPaymentState.swift
├── Presentation/
│   └── Bookings/
│       ├── POSBookingListView.swift
│       ├── POSBookingRowView.swift
│       ├── POSBookingDetailView.swift
│       └── POSBookingPaymentView.swift
```

### New Files (Yosemite)

```
Modules/Sources/Yosemite/
├── PointOfSale/
│   └── POSBookingService.swift
```

### Files to Modify

- Floating menu view (add "Bookings" option)
- `POSDependencyProviding` (add `POSBookingServiceProtocol`)
- `PointOfSaleEntryPointView` (inject booking service)

## Reused Components

- `CardPresentPaymentFacade` for card payments
- `POSSendReceiptView` for email receipts
- Cash payment state patterns from existing checkout
- POS design system (colors, spacing, buttons, badges)
- Ghost loading rows, error states, empty states

## Out of Scope

| Feature | Reason |
|---------|--------|
| Creating bookings in POS | Bookings made on web only |
| Editing bookings (notes, attendance) | Main app handles booking management |
| Filtering/date selection | Today only; future enhancement |
| Search | Not needed for single day's bookings |
| Refunds for booking payments | Use main app's refund flow |

## Future Enhancements

- **D-Light filtering:** Segmented control for "Today / Tomorrow / This Week"
- **Full booking details:** Attendance status, notes, customer address
- **Booking search:** If merchants need to find specific bookings
