# POS Bookings Payment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable merchants to view today's bookings in POS and collect card or cash payments.

**Architecture:** Self-contained feature within the POS module following existing patterns. New `POSBookingListController` and views parallel the existing orders implementation. Payment flows through the booking's linked order using existing `CardPresentPaymentFacade`, then calls `markBookingAsPaid`.

**Tech Stack:** SwiftUI, Swift Testing, @Observable macro, Yosemite stores, CardPresentPaymentFacade

**Design Document:** `docs/plans/2026-02-04-pos-bookings-payment-design.md`

---

## Task 1: POSBooking Model

**Files:**
- Create: `Modules/Sources/PointOfSale/Models/POSBooking.swift`
- Test: `Modules/Tests/PointOfSaleTests/Models/POSBookingTests.swift`

### Step 1.1: Write the failing test

```swift
// POSBookingTests.swift
import Testing
@testable import PointOfSale

struct POSBookingTests {
    @Test func status_unpaid_when_booking_has_linked_order_and_not_paid() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: false
        )

        #expect(booking.status == .unpaid)
    }

    @Test func status_paid_when_booking_is_paid() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: true,
            isCancelled: false
        )

        #expect(booking.status == .paid)
    }

    @Test func status_cancelled_when_booking_is_cancelled() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: 100,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: true
        )

        #expect(booking.status == .cancelled)
    }

    @Test func status_noLinkedOrder_when_orderID_is_nil() {
        let booking = POSBooking(
            bookingID: 1,
            orderID: nil,
            customerName: "Jane Smith",
            serviceName: "Haircut",
            startTime: Date(),
            amount: "$50.00",
            isPaid: false,
            isCancelled: false
        )

        #expect(booking.status == .noLinkedOrder)
    }

    @Test func canCollectPayment_true_only_when_unpaid() {
        let unpaid = POSBooking(bookingID: 1, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: false)
        let paid = POSBooking(bookingID: 2, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: true, isCancelled: false)
        let cancelled = POSBooking(bookingID: 3, orderID: 100, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: true)
        let noOrder = POSBooking(bookingID: 4, orderID: nil, customerName: "Jane", serviceName: "Cut", startTime: Date(), amount: "$50", isPaid: false, isCancelled: false)

        #expect(unpaid.canCollectPayment == true)
        #expect(paid.canCollectPayment == false)
        #expect(cancelled.canCollectPayment == false)
        #expect(noOrder.canCollectPayment == false)
    }
}
```

### Step 1.2: Run test to verify it fails

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build failure - `POSBooking` type not found

### Step 1.3: Write minimal implementation

```swift
// POSBooking.swift
import Foundation

public enum POSBookingStatus: Equatable, Sendable {
    case unpaid
    case paid
    case cancelled
    case noLinkedOrder
}

public struct POSBooking: Equatable, Sendable, Identifiable {
    public let bookingID: Int64
    public let orderID: Int64?
    public let customerName: String
    public let serviceName: String
    public let startTime: Date
    public let amount: String
    public let isPaid: Bool
    public let isCancelled: Bool

    public var id: Int64 { bookingID }

    public var status: POSBookingStatus {
        if orderID == nil {
            return .noLinkedOrder
        }
        if isCancelled {
            return .cancelled
        }
        if isPaid {
            return .paid
        }
        return .unpaid
    }

    public var canCollectPayment: Bool {
        status == .unpaid
    }

    public init(
        bookingID: Int64,
        orderID: Int64?,
        customerName: String,
        serviceName: String,
        startTime: Date,
        amount: String,
        isPaid: Bool,
        isCancelled: Bool
    ) {
        self.bookingID = bookingID
        self.orderID = orderID
        self.customerName = customerName
        self.serviceName = serviceName
        self.startTime = startTime
        self.amount = amount
        self.isPaid = isPaid
        self.isCancelled = isCancelled
    }
}
```

### Step 1.4: Run test to verify it passes

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 1.5: Commit

```bash
git add Modules/Sources/PointOfSale/Models/POSBooking.swift Modules/Tests/PointOfSaleTests/Models/POSBookingTests.swift
git commit -m "feat(pos): add POSBooking model with status computation"
```

---

## Task 2: POSBookingListState Model

**Files:**
- Create: `Modules/Sources/PointOfSale/Models/POSBookingListState.swift`
- Test: `Modules/Tests/PointOfSaleTests/Models/POSBookingListStateTests.swift`

### Step 2.1: Write the failing test

```swift
// POSBookingListStateTests.swift
import Testing
@testable import PointOfSale

struct POSBookingListStateTests {
    @Test func isLoading_true_only_for_loading_state() {
        #expect(POSBookingListState.loading.isLoading == true)
        #expect(POSBookingListState.loaded([]).isLoading == false)
        #expect(POSBookingListState.empty.isLoading == false)
        #expect(POSBookingListState.error(.init(title: "Error", message: "Msg", buttonText: "Retry")).isLoading == false)
    }

    @Test func bookings_returns_array_for_loaded_state() {
        let bookings = [POSBookingTests.makeBooking()]
        let state = POSBookingListState.loaded(bookings)

        #expect(state.bookings == bookings)
    }

    @Test func bookings_returns_empty_for_other_states() {
        #expect(POSBookingListState.loading.bookings.isEmpty)
        #expect(POSBookingListState.empty.bookings.isEmpty)
        #expect(POSBookingListState.error(.init(title: "E", message: "M", buttonText: "R")).bookings.isEmpty)
    }
}

// Test helper extension
extension POSBookingTests {
    static func makeBooking(
        bookingID: Int64 = 1,
        orderID: Int64? = 100,
        customerName: String = "Jane Smith",
        serviceName: String = "Haircut",
        startTime: Date = Date(),
        amount: String = "$50.00",
        isPaid: Bool = false,
        isCancelled: Bool = false
    ) -> POSBooking {
        POSBooking(
            bookingID: bookingID,
            orderID: orderID,
            customerName: customerName,
            serviceName: serviceName,
            startTime: startTime,
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled
        )
    }
}
```

### Step 2.2: Run test to verify it fails

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingListStateTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build failure - `POSBookingListState` type not found

### Step 2.3: Write minimal implementation

```swift
// POSBookingListState.swift
import Foundation

public enum POSBookingListState: Equatable, Sendable {
    case loading
    case loaded([POSBooking])
    case empty
    case error(PointOfSaleErrorState)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var bookings: [POSBooking] {
        if case .loaded(let bookings) = self {
            return bookings
        }
        return []
    }
}
```

### Step 2.4: Run test to verify it passes

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingListStateTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 2.5: Commit

```bash
git add Modules/Sources/PointOfSale/Models/POSBookingListState.swift Modules/Tests/PointOfSaleTests/Models/POSBookingListStateTests.swift
git commit -m "feat(pos): add POSBookingListState for booking list view states"
```

---

## Task 3: POSBookingPaymentState Model

**Files:**
- Create: `Modules/Sources/PointOfSale/Models/POSBookingPaymentState.swift`
- Test: `Modules/Tests/PointOfSaleTests/Models/POSBookingPaymentStateTests.swift`

### Step 3.1: Write the failing test

```swift
// POSBookingPaymentStateTests.swift
import Testing
@testable import PointOfSale

struct POSBookingPaymentStateTests {
    @Test func canCancel_true_for_ready_and_error_states() {
        #expect(POSBookingPaymentState.ready.canCancel == true)
        #expect(POSBookingPaymentState.error("Failed").canCancel == true)
        #expect(POSBookingPaymentState.processing.canCancel == false)
        #expect(POSBookingPaymentState.success.canCancel == false)
    }

    @Test func showsAmount_true_for_ready_and_processing() {
        #expect(POSBookingPaymentState.ready.showsAmount == true)
        #expect(POSBookingPaymentState.processing.showsAmount == true)
        #expect(POSBookingPaymentState.success.showsAmount == true)
        #expect(POSBookingPaymentState.error("Failed").showsAmount == false)
    }

    @Test func errorMessage_returns_message_for_error_state() {
        let state = POSBookingPaymentState.error("Card declined")
        #expect(state.errorMessage == "Card declined")
    }

    @Test func errorMessage_returns_nil_for_non_error_states() {
        #expect(POSBookingPaymentState.ready.errorMessage == nil)
        #expect(POSBookingPaymentState.processing.errorMessage == nil)
        #expect(POSBookingPaymentState.success.errorMessage == nil)
    }
}
```

### Step 3.2: Run test to verify it fails

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingPaymentStateTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build failure - `POSBookingPaymentState` type not found

### Step 3.3: Write minimal implementation

```swift
// POSBookingPaymentState.swift
import Foundation

public enum POSBookingPaymentState: Equatable, Sendable {
    case ready
    case processing
    case success
    case error(String)

    public var canCancel: Bool {
        switch self {
        case .ready, .error:
            return true
        case .processing, .success:
            return false
        }
    }

    public var showsAmount: Bool {
        switch self {
        case .ready, .processing, .success:
            return true
        case .error:
            return false
        }
    }

    public var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
```

### Step 3.4: Run test to verify it passes

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingPaymentStateTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 3.5: Commit

```bash
git add Modules/Sources/PointOfSale/Models/POSBookingPaymentState.swift Modules/Tests/PointOfSaleTests/Models/POSBookingPaymentStateTests.swift
git commit -m "feat(pos): add POSBookingPaymentState for card/cash payment flow"
```

---

## Task 4: POSBookingService Protocol and Mock

**Files:**
- Create: `Modules/Sources/Yosemite/PointOfSale/POSBookingService.swift`
- Create: `Modules/Tests/PointOfSaleTests/Mocks/MockPOSBookingService.swift`

### Step 4.1: Write the service protocol

```swift
// POSBookingService.swift
import Foundation
import Networking

public protocol POSBookingServiceProtocol: Sendable {
    func fetchTodaysBookings(siteID: Int64) async throws -> [Booking]
    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws
}

public final class POSBookingService: POSBookingServiceProtocol {
    private let stores: StoresManager

    public init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    public func fetchTodaysBookings(siteID: Int64) async throws -> [Booking] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await withCheckedThrowingContinuation { continuation in
            let action = BookingAction.synchronizeBookings(
                siteID: siteID,
                pageNumber: 1,
                pageSize: 100,
                startDateFilter: .init(startDate: startOfDay, endDate: endOfDay),
                productFilter: nil,
                customerFilter: nil,
                resourceFilter: nil,
                attendanceStatuses: nil,
                sortOrder: .ascending
            ) { result in
                switch result {
                case .success(let bookings):
                    continuation.resume(returning: bookings)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.stores.dispatch(action)
        }
    }

    public func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = BookingAction.markBookingAsPaid(
                siteID: siteID,
                bookingID: bookingID
            ) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.stores.dispatch(action)
        }
    }
}
```

### Step 4.2: Write the mock for testing

```swift
// MockPOSBookingService.swift
import Foundation
@testable import Yosemite
@testable import PointOfSale
import Networking

final class MockPOSBookingService: POSBookingServiceProtocol, @unchecked Sendable {
    var bookingsToReturn: [Booking] = []
    var fetchTodaysBookingsCallCount = 0
    var markBookingAsPaidCallCount = 0
    var markBookingAsPaidBookingID: Int64?
    var shouldThrowOnFetch = false
    var shouldThrowOnMarkAsPaid = false

    func fetchTodaysBookings(siteID: Int64) async throws -> [Booking] {
        fetchTodaysBookingsCallCount += 1
        if shouldThrowOnFetch {
            throw NSError(domain: "test", code: 1)
        }
        return bookingsToReturn
    }

    func markBookingAsPaid(siteID: Int64, bookingID: Int64) async throws {
        markBookingAsPaidCallCount += 1
        markBookingAsPaidBookingID = bookingID
        if shouldThrowOnMarkAsPaid {
            throw NSError(domain: "test", code: 2)
        }
    }

    static func makeBooking(
        bookingID: Int64 = 1,
        orderID: Int64? = 100,
        productID: Int64 = 10,
        customerID: Int64 = 5,
        startDate: Date = Date(),
        cost: String = "50.00",
        statusKey: String = "unpaid"
    ) -> Booking {
        Booking(
            siteID: 123,
            bookingID: bookingID,
            orderID: orderID ?? 0,
            orderItemID: 1,
            productID: productID,
            resourceID: nil,
            parentID: nil,
            customerID: customerID,
            statusKey: statusKey,
            attendanceStatusKey: "booked",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600),
            allDay: false,
            dateCreated: Date(),
            dateModified: Date(),
            cost: cost,
            googleCalendarEventID: nil,
            note: nil,
            localTimezone: nil,
            currency: "USD",
            orderInfo: nil
        )
    }
}
```

### Step 4.3: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 4.4: Commit

```bash
git add Modules/Sources/Yosemite/PointOfSale/POSBookingService.swift Modules/Tests/PointOfSaleTests/Mocks/MockPOSBookingService.swift
git commit -m "feat(pos): add POSBookingService protocol for fetching bookings"
```

---

## Task 5: POSBookingListController

**Files:**
- Create: `Modules/Sources/PointOfSale/Controllers/POSBookingListController.swift`
- Test: `Modules/Tests/PointOfSaleTests/Controllers/POSBookingListControllerTests.swift`

### Step 5.1: Write the failing test

```swift
// POSBookingListControllerTests.swift
import Testing
@testable import PointOfSale
@testable import Yosemite

@MainActor
struct POSBookingListControllerTests {
    private let bookingService = MockPOSBookingService()
    private let currencySettings = MockPOSCurrencySettingsProviding()

    private func makeSUT() -> POSBookingListController {
        POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )
    }

    @Test func initial_state_is_loading() {
        let sut = makeSUT()
        #expect(sut.state.isLoading)
    }

    @Test func loadBookings_updates_state_to_loaded_with_bookings() async {
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100)
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()

        await sut.loadBookings()

        #expect(sut.state.bookings.count == 1)
        #expect(sut.state.bookings.first?.bookingID == 1)
    }

    @Test func loadBookings_updates_state_to_empty_when_no_bookings() async {
        bookingService.bookingsToReturn = []
        let sut = makeSUT()

        await sut.loadBookings()

        #expect(sut.state == .empty)
    }

    @Test func loadBookings_updates_state_to_error_on_failure() async {
        bookingService.shouldThrowOnFetch = true
        let sut = makeSUT()

        await sut.loadBookings()

        if case .error = sut.state {
            // Expected
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test func selectBooking_updates_selectedBooking() async {
        let booking = MockPOSBookingService.makeBooking()
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()
        await sut.loadBookings()

        sut.selectBooking(sut.state.bookings.first)

        #expect(sut.selectedBooking?.bookingID == booking.bookingID)
    }

    @Test func clearSelection_sets_selectedBooking_to_nil() async {
        let booking = MockPOSBookingService.makeBooking()
        bookingService.bookingsToReturn = [booking]
        let sut = makeSUT()
        await sut.loadBookings()
        sut.selectBooking(sut.state.bookings.first)

        sut.clearSelection()

        #expect(sut.selectedBooking == nil)
    }
}
```

### Step 5.2: Run test to verify it fails

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingListControllerTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build failure - `POSBookingListController` type not found

### Step 5.3: Write minimal implementation

```swift
// POSBookingListController.swift
import Foundation
import Yosemite
import Networking
import protocol WooFoundation.CurrencyFormatter

@MainActor
@Observable
public final class POSBookingListController {
    public private(set) var state: POSBookingListState = .loading
    public private(set) var selectedBooking: POSBooking?

    private let siteID: Int64
    private let bookingService: POSBookingServiceProtocol
    private let currencyFormatter: CurrencyFormatter

    public init(
        siteID: Int64,
        bookingService: POSBookingServiceProtocol,
        currencyFormatter: CurrencyFormatter
    ) {
        self.siteID = siteID
        self.bookingService = bookingService
        self.currencyFormatter = currencyFormatter
    }

    public func loadBookings() async {
        state = .loading
        do {
            let bookings = try await bookingService.fetchTodaysBookings(siteID: siteID)
            if bookings.isEmpty {
                state = .empty
            } else {
                let posBookings = bookings.map { mapToPOSBooking($0) }
                    .sorted { $0.startTime < $1.startTime }
                state = .loaded(posBookings)
            }
        } catch {
            state = .error(PointOfSaleErrorState(
                title: Localization.errorTitle,
                message: Localization.errorMessage,
                buttonText: Localization.retry
            ))
        }
    }

    public func refreshBookings() async {
        await loadBookings()
    }

    public func selectBooking(_ booking: POSBooking?) {
        selectedBooking = booking
    }

    public func clearSelection() {
        selectedBooking = nil
    }

    private func mapToPOSBooking(_ booking: Booking) -> POSBooking {
        let amount = currencyFormatter.formatAmount(Decimal(string: booking.cost) ?? 0) ?? booking.cost
        let isPaid = booking.statusKey == "paid" || booking.statusKey == "complete"
        let isCancelled = booking.statusKey == "cancelled"

        return POSBooking(
            bookingID: booking.bookingID,
            orderID: booking.orderID > 0 ? booking.orderID : nil,
            customerName: booking.orderInfo?.customerInfo?.billingAddress?.firstName ?? Localization.guest,
            serviceName: booking.orderInfo?.productInfo?.name ?? Localization.booking,
            startTime: booking.startDate,
            amount: amount,
            isPaid: isPaid,
            isCancelled: isCancelled
        )
    }

    private enum Localization {
        static let errorTitle = NSLocalizedString(
            "posBookingListController.errorTitle",
            value: "Couldn't load bookings",
            comment: "Error title when bookings fail to load in POS"
        )
        static let errorMessage = NSLocalizedString(
            "posBookingListController.errorMessage",
            value: "Please check your connection and try again.",
            comment: "Error message when bookings fail to load in POS"
        )
        static let retry = NSLocalizedString(
            "posBookingListController.retry",
            value: "Retry",
            comment: "Retry button text for booking list error"
        )
        static let guest = NSLocalizedString(
            "posBookingListController.guest",
            value: "Guest",
            comment: "Placeholder for booking without customer name"
        )
        static let booking = NSLocalizedString(
            "posBookingListController.booking",
            value: "Booking",
            comment: "Placeholder for booking without service name"
        )
    }
}
```

### Step 5.4: Run test to verify it passes

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingListControllerTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 5.5: Commit

```bash
git add Modules/Sources/PointOfSale/Controllers/POSBookingListController.swift Modules/Tests/PointOfSaleTests/Controllers/POSBookingListControllerTests.swift
git commit -m "feat(pos): add POSBookingListController for managing booking list state"
```

---

## Task 6: POSBookingPaymentController

**Files:**
- Create: `Modules/Sources/PointOfSale/Controllers/POSBookingPaymentController.swift`
- Test: `Modules/Tests/PointOfSaleTests/Controllers/POSBookingPaymentControllerTests.swift`

### Step 6.1: Write the failing test

```swift
// POSBookingPaymentControllerTests.swift
import Testing
import Combine
@testable import PointOfSale
@testable import Yosemite

@MainActor
struct POSBookingPaymentControllerTests {
    private let bookingService = MockPOSBookingService()
    private let cardPaymentFacade = MockCardPresentPaymentFacade()
    private let orderService = MockPOSOrderService()

    private func makeSUT(booking: POSBooking? = nil) -> POSBookingPaymentController {
        let testBooking = booking ?? POSBookingTests.makeBooking()
        return POSBookingPaymentController(
            siteID: 123,
            booking: testBooking,
            bookingService: bookingService,
            cardPaymentFacade: cardPaymentFacade,
            orderService: orderService
        )
    }

    @Test func initial_state_is_ready() {
        let sut = makeSUT()
        #expect(sut.paymentState == .ready)
    }

    @Test func collectCardPayment_transitions_to_processing() async {
        let sut = makeSUT()
        cardPaymentFacade.delayPayment = true

        Task {
            try? await sut.collectCardPayment()
        }

        // Give time for state to update
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.paymentState == .processing)
    }

    @Test func collectCardPayment_success_marks_booking_as_paid() async throws {
        let booking = POSBookingTests.makeBooking(bookingID: 42)
        let sut = makeSUT(booking: booking)
        cardPaymentFacade.shouldSucceed = true

        try await sut.collectCardPayment()

        #expect(bookingService.markBookingAsPaidCallCount == 1)
        #expect(bookingService.markBookingAsPaidBookingID == 42)
    }

    @Test func collectCardPayment_success_transitions_to_success_state() async throws {
        let sut = makeSUT()
        cardPaymentFacade.shouldSucceed = true

        try await sut.collectCardPayment()

        #expect(sut.paymentState == .success)
    }

    @Test func collectCardPayment_failure_transitions_to_error_state() async {
        let sut = makeSUT()
        cardPaymentFacade.shouldSucceed = false

        do {
            try await sut.collectCardPayment()
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }

        if case .error = sut.paymentState {
            // Expected
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test func cancelPayment_calls_facade_cancel() async throws {
        let sut = makeSUT()

        try await sut.cancelPayment()

        #expect(cardPaymentFacade.cancelPaymentCallCount == 1)
    }

    @Test func reset_returns_to_ready_state() async throws {
        let sut = makeSUT()
        cardPaymentFacade.shouldSucceed = false
        try? await sut.collectCardPayment()

        sut.reset()

        #expect(sut.paymentState == .ready)
    }
}
```

### Step 6.2: Run test to verify it fails

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingPaymentControllerTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build failure - `POSBookingPaymentController` type not found

### Step 6.3: Write minimal implementation

```swift
// POSBookingPaymentController.swift
import Foundation
import Combine
import Yosemite
import protocol WooFoundation.Analytics

@MainActor
@Observable
public final class POSBookingPaymentController {
    public private(set) var paymentState: POSBookingPaymentState = .ready

    public let booking: POSBooking

    private let siteID: Int64
    private let bookingService: POSBookingServiceProtocol
    private let cardPaymentFacade: CardPresentPaymentFacade
    private let orderService: POSOrderServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(
        siteID: Int64,
        booking: POSBooking,
        bookingService: POSBookingServiceProtocol,
        cardPaymentFacade: CardPresentPaymentFacade,
        orderService: POSOrderServiceProtocol
    ) {
        self.siteID = siteID
        self.booking = booking
        self.bookingService = bookingService
        self.cardPaymentFacade = cardPaymentFacade
        self.orderService = orderService

        observePaymentEvents()
    }

    public func collectCardPayment() async throws {
        guard let orderID = booking.orderID else {
            paymentState = .error(Localization.noOrderError)
            throw BookingPaymentError.noLinkedOrder
        }

        paymentState = .processing

        do {
            let order = try await fetchOrder(orderID: orderID)
            let result = try await cardPaymentFacade.collectPayment(
                for: order,
                using: .bluetoothScan,
                channel: .pointOfSale
            )

            switch result {
            case .success:
                try? await bookingService.markBookingAsPaid(siteID: siteID, bookingID: booking.bookingID)
                paymentState = .success
            case .cancellation:
                paymentState = .ready
            }
        } catch {
            paymentState = .error(error.localizedDescription)
            throw error
        }
    }

    public func cancelPayment() async throws {
        try await cardPaymentFacade.cancelPayment()
        paymentState = .ready
    }

    public func reset() {
        paymentState = .ready
    }

    private func fetchOrder(orderID: Int64) async throws -> Order {
        // Fetch order from store
        try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.retrieveOrderRemotely(siteID: siteID, orderID: orderID) { result in
                switch result {
                case .success(let order):
                    continuation.resume(returning: order)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    private func observePaymentEvents() {
        cardPaymentFacade.paymentEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handlePaymentEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handlePaymentEvent(_ event: CardPresentPaymentEvent) {
        switch event {
        case .show(let eventDetails):
            switch eventDetails {
            case .preparingForPayment, .tapSwipeOrInsertCard, .cardInserted:
                paymentState = .processing
            case .processing:
                paymentState = .processing
            case .paymentSuccess:
                paymentState = .success
            case .paymentError(let error):
                paymentState = .error(error.localizedDescription)
            default:
                break
            }
        case .idle:
            break
        }
    }

    private enum Localization {
        static let noOrderError = NSLocalizedString(
            "posBookingPaymentController.noOrderError",
            value: "This booking has no linked order",
            comment: "Error when trying to pay for a booking without a linked order"
        )
    }
}

public enum BookingPaymentError: Error {
    case noLinkedOrder
}
```

### Step 6.4: Run test to verify it passes

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingPaymentControllerTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 6.5: Commit

```bash
git add Modules/Sources/PointOfSale/Controllers/POSBookingPaymentController.swift Modules/Tests/PointOfSaleTests/Controllers/POSBookingPaymentControllerTests.swift
git commit -m "feat(pos): add POSBookingPaymentController for card payment flow"
```

---

## Task 7: POSBookingRowView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingRowView.swift`

### Step 7.1: Write the view

```swift
// POSBookingRowView.swift
import SwiftUI

struct POSBookingRowView: View {
    let booking: POSBooking
    let isSelected: Bool
    let timeFormatter: DateFormatter

    init(booking: POSBooking, isSelected: Bool, siteTimezone: TimeZone = .current) {
        self.booking = booking
        self.isSelected = isSelected

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = siteTimezone
        self.timeFormatter = formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                Text(booking.customerName)
                    .font(.posBodyLargeBold())
                    .foregroundStyle(Color.posOnSurface)

                Spacer()

                Text(booking.amount)
                    .font(.posBodyLargeBold())
                    .foregroundStyle(Color.posOnSurface)
            }

            HStack(spacing: POSSpacing.small) {
                statusBadge

                Text("·")
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(booking.serviceName)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text("·")
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(timeFormatter.string(from: booking.startTime))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
        .overlay(
            RoundedRectangle(cornerRadius: POSSpacing.small)
                .stroke(isSelected ? Color.posOnSurface : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        let config = statusConfiguration
        Text(config.text)
            .font(.posBodySmallBold())
            .foregroundStyle(config.foreground)
            .padding(.horizontal, POSSpacing.small)
            .padding(.vertical, POSSpacing.xSmall)
            .background(config.background)
            .clipShape(RoundedRectangle(cornerRadius: POSSpacing.xSmall))
    }

    private var statusConfiguration: (text: String, foreground: Color, background: Color) {
        switch booking.status {
        case .unpaid:
            return (Localization.unpaid, Color.posOnAlert, Color.posAlert)
        case .paid:
            return (Localization.paid, Color.posOnSuccess, Color.posSuccess)
        case .cancelled:
            return (Localization.cancelled, Color.posOnSurfaceVariantHighest, Color.posSurfaceContainerLow)
        case .noLinkedOrder:
            return (Localization.noOrder, Color.posOnError, Color.posError)
        }
    }

    private enum Localization {
        static let unpaid = NSLocalizedString("posBookingRow.unpaid", value: "Unpaid", comment: "Booking status badge")
        static let paid = NSLocalizedString("posBookingRow.paid", value: "Paid", comment: "Booking status badge")
        static let cancelled = NSLocalizedString("posBookingRow.cancelled", value: "Cancelled", comment: "Booking status badge")
        static let noOrder = NSLocalizedString("posBookingRow.noOrder", value: "No order", comment: "Booking status badge")
    }
}
```

### Step 7.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 7.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingRowView.swift
git commit -m "feat(pos): add POSBookingRowView for booking list items"
```

---

## Task 8: POSBookingListView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingListView.swift`

### Step 8.1: Write the view

```swift
// POSBookingListView.swift
import SwiftUI

struct POSBookingListView: View {
    @Environment(POSBookingListController.self) private var controller
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.siteTimezone) private var siteTimezone

    let onClose: () -> Void
    let onBookingSelected: (POSBooking) -> Void

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                showBackButton: true,
                onBackButtonTapped: onClose
            )

            content
        }
        .background(Color.posSurface)
        .task {
            await controller.loadBookings()
        }
        .refreshable {
            await controller.refreshBookings()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch controller.state {
        case .loading:
            loadingView
        case .loaded(let bookings):
            bookingsList(bookings)
        case .empty:
            emptyView
        case .error(let errorState):
            errorView(errorState)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: POSSpacing.medium) {
            ForEach(0..<5, id: \.self) { _ in
                POSGhostBookingRowView()
            }
        }
        .padding(POSSpacing.medium)
        Spacer()
    }

    @ViewBuilder
    private func bookingsList(_ bookings: [POSBooking]) -> some View {
        ScrollView {
            LazyVStack(spacing: POSSpacing.small) {
                ForEach(bookings) { booking in
                    Button {
                        analytics.track(.posBookingTapped)
                        controller.selectBooking(booking)
                        onBookingSelected(booking)
                    } label: {
                        POSBookingRowView(
                            booking: booking,
                            isSelected: controller.selectedBooking?.bookingID == booking.bookingID,
                            siteTimezone: siteTimezone
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(POSSpacing.medium)
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        POSListEmptyView(
            title: Localization.emptyTitle,
            subtitle: Localization.emptySubtitle,
            imageName: "calendar.badge.clock"
        )
    }

    @ViewBuilder
    private func errorView(_ errorState: PointOfSaleErrorState) -> some View {
        POSListErrorView(
            title: errorState.title,
            message: errorState.message,
            buttonTitle: errorState.buttonText
        ) {
            Task {
                await controller.loadBookings()
            }
        }
    }

    private enum Localization {
        static let title = NSLocalizedString("posBookingList.title", value: "Today's Bookings", comment: "Title for POS bookings list")
        static let emptyTitle = NSLocalizedString("posBookingList.emptyTitle", value: "No bookings today", comment: "Empty state title")
        static let emptySubtitle = NSLocalizedString("posBookingList.emptySubtitle", value: "Bookings for today will appear here", comment: "Empty state subtitle")
    }
}

// Ghost loading row
struct POSGhostBookingRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 60, height: 20)
            }
            HStack {
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 200, height: 16)
            }
        }
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
        .shimmering()
    }
}
```

### Step 8.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 8.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingListView.swift
git commit -m "feat(pos): add POSBookingListView with loading, empty, and error states"
```

---

## Task 9: POSBookingDetailView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingDetailView.swift`

### Step 9.1: Write the view

```swift
// POSBookingDetailView.swift
import SwiftUI

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void
    let onPayByCard: () -> Void
    let onPayByCash: () -> Void

    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = siteTimezone
        formatter.doesRelativeDateFormatting = true
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .compact {
                POSPageHeaderView(
                    title: Localization.title,
                    showBackButton: true,
                    onBackButtonTapped: onBack
                )
            }

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    bookingInfoSection
                    Divider()
                    totalSection
                    paymentActionsSection
                }
                .padding(POSSpacing.large)
            }
        }
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var bookingInfoSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(booking.customerName)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(booking.serviceName)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(dateFormatter.string(from: booking.startTime))
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    @ViewBuilder
    private var totalSection: some View {
        HStack {
            Text(Localization.total)
                .font(.posBodyLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Spacer()

            Text(booking.amount)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var paymentActionsSection: some View {
        switch booking.status {
        case .unpaid:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.payByCard) {
                    onPayByCard()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(Localization.payByCash) {
                    onPayByCash()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }

        case .paid:
            statusMessage(
                icon: "checkmark.circle.fill",
                text: Localization.paymentComplete,
                color: .posSuccess
            )

        case .cancelled:
            statusMessage(
                icon: "xmark.circle.fill",
                text: Localization.bookingCancelled,
                color: .posOnSurfaceVariantHighest
            )

        case .noLinkedOrder:
            statusMessage(
                icon: "exclamationmark.triangle.fill",
                text: Localization.noLinkedOrder,
                color: .posError
            )
        }
    }

    @ViewBuilder
    private func statusMessage(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: POSSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity)
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
    }

    private enum Localization {
        static let title = NSLocalizedString("posBookingDetail.title", value: "Booking", comment: "Title for booking detail view")
        static let total = NSLocalizedString("posBookingDetail.total", value: "Total", comment: "Total label")
        static let payByCard = NSLocalizedString("posBookingDetail.payByCard", value: "Pay by Card", comment: "Card payment button")
        static let payByCash = NSLocalizedString("posBookingDetail.payByCash", value: "Pay by Cash", comment: "Cash payment button")
        static let paymentComplete = NSLocalizedString("posBookingDetail.paymentComplete", value: "Payment Complete", comment: "Status for paid booking")
        static let bookingCancelled = NSLocalizedString("posBookingDetail.bookingCancelled", value: "Booking Cancelled", comment: "Status for cancelled booking")
        static let noLinkedOrder = NSLocalizedString("posBookingDetail.noLinkedOrder", value: "No order linked to this booking", comment: "Status for booking without order")
    }
}
```

### Step 9.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 9.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingDetailView.swift
git commit -m "feat(pos): add POSBookingDetailView with payment action buttons"
```

---

## Task 10: POSBookingPaymentView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift`

### Step 10.1: Write the view

```swift
// POSBookingPaymentView.swift
import SwiftUI

struct POSBookingPaymentView: View {
    @Environment(POSBookingPaymentController.self) private var controller
    @Environment(\.posAnalytics) private var analytics

    let onDismiss: () -> Void
    let onEmailReceipt: () -> Void

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            Spacer()

            statusContent

            Spacer()

            actionButtons
        }
        .padding(POSSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch controller.paymentState {
        case .ready:
            readyContent
        case .processing:
            processingContent
        case .success:
            successContent
        case .error(let message):
            errorContent(message)
        }
    }

    @ViewBuilder
    private var readyContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 64))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(Localization.tapInsertSwipe)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(controller.booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var processingContent: some View {
        VStack(spacing: POSSpacing.large) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .scaleEffect(2)

            Text(Localization.processing)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(controller.booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var successContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.posSuccess)

            Text(Localization.paymentSuccessful)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(controller.booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private func errorContent(_ message: String) -> some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.posError)

            Text(Localization.paymentFailed)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(message)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch controller.paymentState {
        case .ready:
            Button(Localization.cancel) {
                Task {
                    try? await controller.cancelPayment()
                    onDismiss()
                }
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))

        case .processing:
            EmptyView()

        case .success:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.emailReceipt) {
                    analytics.track(.posBookingEmailReceiptTapped)
                    onEmailReceipt()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))

                Button(Localization.done) {
                    analytics.track(.posBookingPaymentDoneTapped)
                    onDismiss()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }

        case .error:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.tryAgain) {
                    controller.reset()
                    Task {
                        try? await controller.collectCardPayment()
                    }
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(Localization.cancel) {
                    onDismiss()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
        }
    }

    private enum Localization {
        static let tapInsertSwipe = NSLocalizedString("posBookingPayment.tapInsertSwipe", value: "Tap, insert, or swipe card", comment: "Card reader instruction")
        static let processing = NSLocalizedString("posBookingPayment.processing", value: "Processing payment...", comment: "Payment processing message")
        static let paymentSuccessful = NSLocalizedString("posBookingPayment.success", value: "Payment Successful", comment: "Payment success message")
        static let paymentFailed = NSLocalizedString("posBookingPayment.failed", value: "Payment Failed", comment: "Payment failure message")
        static let cancel = NSLocalizedString("posBookingPayment.cancel", value: "Cancel", comment: "Cancel button")
        static let done = NSLocalizedString("posBookingPayment.done", value: "Done", comment: "Done button")
        static let tryAgain = NSLocalizedString("posBookingPayment.tryAgain", value: "Try Again", comment: "Try again button")
        static let emailReceipt = NSLocalizedString("posBookingPayment.emailReceipt", value: "Email Receipt", comment: "Email receipt button")
    }
}
```

### Step 10.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 10.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingPaymentView.swift
git commit -m "feat(pos): add POSBookingPaymentView for card payment flow"
```

---

## Task 11: POSBookingCashPaymentView

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingCashPaymentView.swift`

### Step 11.1: Write the view

```swift
// POSBookingCashPaymentView.swift
import SwiftUI

struct POSBookingCashPaymentView: View {
    let booking: POSBooking
    let onPaymentComplete: () -> Void
    let onDismiss: () -> Void
    let onEmailReceipt: () -> Void

    @Environment(\.posAnalytics) private var analytics
    @State private var tenderedAmount: String = ""
    @State private var showSuccess: Bool = false
    @State private var isProcessing: Bool = false

    private var bookingAmount: Decimal {
        // Parse amount from formatted string (e.g., "$50.00" -> 50.00)
        let cleanedAmount = booking.amount.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Decimal(string: cleanedAmount) ?? 0
    }

    private var tenderedDecimal: Decimal {
        Decimal(string: tenderedAmount) ?? 0
    }

    private var changeDue: Decimal {
        max(tenderedDecimal - bookingAmount, 0)
    }

    private var canComplete: Bool {
        tenderedDecimal >= bookingAmount
    }

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            Spacer()

            if showSuccess {
                successContent
            } else {
                cashEntryContent
            }

            Spacer()

            actionButtons
        }
        .padding(POSSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var cashEntryContent: some View {
        VStack(spacing: POSSpacing.large) {
            Text(Localization.totalDue)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                Text(Localization.amountTendered)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                TextField("0.00", text: $tenderedAmount)
                    .font(.system(size: 32, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.posOnSurface)
            }

            if tenderedDecimal > 0 && canComplete {
                VStack(spacing: POSSpacing.xSmall) {
                    Text(Localization.changeDue)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)

                    Text(formatCurrency(changeDue))
                        .font(.posBodyXLargeBold())
                        .foregroundStyle(Color.posSuccess)
                }
            }
        }
    }

    @ViewBuilder
    private var successContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.posSuccess)

            Text(Localization.paymentSuccessful)
                .font(.posBodyXLargeBold())
                .foregroundStyle(Color.posOnSurface)

            Text(booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if showSuccess {
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.emailReceipt) {
                    analytics.track(.posBookingCashEmailReceiptTapped)
                    onEmailReceipt()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))

                Button(Localization.done) {
                    analytics.track(.posBookingCashPaymentDoneTapped)
                    onPaymentComplete()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
        } else {
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.markAsPaid) {
                    completePayment()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal, state: isProcessing ? .loading : .idle))
                .disabled(!canComplete || isProcessing)

                Button(Localization.cancel) {
                    onDismiss()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .disabled(isProcessing)
            }
        }
    }

    private func completePayment() {
        analytics.track(.posBookingCashPaymentCompleteTapped)
        isProcessing = true

        // In the real implementation, this would call the booking service
        // to mark the booking as paid. For now, we just show success.
        Task { @MainActor in
            // Simulate network call
            try? await Task.sleep(nanoseconds: 500_000_000)
            showSuccess = true
            isProcessing = false
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSNumber) ?? "\(amount)"
    }

    private enum Localization {
        static let totalDue = NSLocalizedString("posBookingCash.totalDue", value: "Total Due", comment: "Label for total amount")
        static let amountTendered = NSLocalizedString("posBookingCash.amountTendered", value: "Amount Tendered", comment: "Label for cash amount")
        static let changeDue = NSLocalizedString("posBookingCash.changeDue", value: "Change Due", comment: "Label for change amount")
        static let markAsPaid = NSLocalizedString("posBookingCash.markAsPaid", value: "Mark as Paid", comment: "Button to complete cash payment")
        static let cancel = NSLocalizedString("posBookingCash.cancel", value: "Cancel", comment: "Cancel button")
        static let paymentSuccessful = NSLocalizedString("posBookingCash.success", value: "Payment Successful", comment: "Success message")
        static let done = NSLocalizedString("posBookingCash.done", value: "Done", comment: "Done button")
        static let emailReceipt = NSLocalizedString("posBookingCash.emailReceipt", value: "Email Receipt", comment: "Email receipt button")
    }
}
```

### Step 11.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 11.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingCashPaymentView.swift
git commit -m "feat(pos): add POSBookingCashPaymentView for cash payment flow"
```

---

## Task 12: POSBookingsContainerView (Coordinator)

**Files:**
- Create: `Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingsContainerView.swift`

### Step 12.1: Write the container view

```swift
// POSBookingsContainerView.swift
import SwiftUI

struct POSBookingsContainerView: View {
    @Environment(POSBookingListController.self) private var listController
    @Environment(\.posAnalytics) private var analytics

    @State private var selectedBooking: POSBooking?
    @State private var showingCardPayment: Bool = false
    @State private var showingCashPayment: Bool = false
    @State private var showingEmailReceipt: Bool = false
    @State private var paymentController: POSBookingPaymentController?

    let siteID: Int64
    let bookingService: POSBookingServiceProtocol
    let cardPaymentFacade: CardPresentPaymentFacade
    let orderService: POSOrderServiceProtocol
    let onSendReceipt: (Int64, String) async throws -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationSplitView {
            POSBookingListView(
                onClose: onClose,
                onBookingSelected: { booking in
                    selectedBooking = booking
                }
            )
        } detail: {
            if let booking = selectedBooking {
                POSBookingDetailView(
                    booking: booking,
                    onBack: { selectedBooking = nil },
                    onPayByCard: { startCardPayment(for: booking) },
                    onPayByCash: { startCashPayment(for: booking) }
                )
            } else {
                emptyDetailView
            }
        }
        .posFullScreenCover(isPresented: $showingCardPayment) {
            if let controller = paymentController {
                POSBookingPaymentView(
                    onDismiss: {
                        showingCardPayment = false
                        refreshAfterPayment()
                    },
                    onEmailReceipt: {
                        showingEmailReceipt = true
                    }
                )
                .environment(controller)
                .task {
                    try? await controller.collectCardPayment()
                }
            }
        }
        .posFullScreenCover(isPresented: $showingCashPayment) {
            if let booking = selectedBooking {
                POSBookingCashPaymentView(
                    booking: booking,
                    onPaymentComplete: {
                        showingCashPayment = false
                        refreshAfterPayment()
                    },
                    onDismiss: {
                        showingCashPayment = false
                    },
                    onEmailReceipt: {
                        showingEmailReceipt = true
                    }
                )
            }
        }
        .posSheet(isPresented: $showingEmailReceipt) {
            if let booking = selectedBooking, let orderID = booking.orderID {
                POSSendReceiptView(
                    isShowingSendReceiptView: $showingEmailReceipt
                ) { email in
                    try await onSendReceipt(orderID, email)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyDetailView: some View {
        VStack(spacing: POSSpacing.medium) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(Localization.selectBooking)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    private func startCardPayment(for booking: POSBooking) {
        analytics.track(.posBookingCardPaymentStarted)
        paymentController = POSBookingPaymentController(
            siteID: siteID,
            booking: booking,
            bookingService: bookingService,
            cardPaymentFacade: cardPaymentFacade,
            orderService: orderService
        )
        showingCardPayment = true
    }

    private func startCashPayment(for booking: POSBooking) {
        analytics.track(.posBookingCashPaymentStarted)
        showingCashPayment = true
    }

    private func refreshAfterPayment() {
        Task {
            await listController.refreshBookings()
            // Update selected booking if it was paid
            if let currentID = selectedBooking?.bookingID,
               let updated = listController.state.bookings.first(where: { $0.bookingID == currentID }) {
                selectedBooking = updated
            }
        }
    }

    private enum Localization {
        static let selectBooking = NSLocalizedString(
            "posBookingsContainer.selectBooking",
            value: "Select a booking to view details",
            comment: "Placeholder when no booking is selected"
        )
    }
}
```

### Step 12.2: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 12.3: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/Bookings/POSBookingsContainerView.swift
git commit -m "feat(pos): add POSBookingsContainerView to coordinate booking flows"
```

---

## Task 13: Add Bookings to Floating Menu

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/POSFloatingControlView.swift`

### Step 13.1: Read the current file

Read the file to understand current structure before modifying.

### Step 13.2: Add bookings menu item and state

Add to the view:

1. Add state variable:
```swift
@State private var showBookings: Bool = false
```

2. Add menu item in `menuOptions()` after the Orders button:
```swift
if featureFlags.isFeatureFlagEnabled(.pointOfSaleBookings) {
    Button {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingsMenuItemTapped())
        showBookings = true
    } label: {
        Label(
            title: { Text(Localization.bookings) },
            icon: { Image(systemName: "calendar") }
        )
    }
}
```

3. Add localization string:
```swift
static let bookings = NSLocalizedString(
    "pointOfSale.floatingControl.bookings",
    value: "Bookings",
    comment: "Menu item to open bookings in POS"
)
```

4. Add full screen cover for bookings presentation (similar to orders).

### Step 13.3: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 13.4: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/POSFloatingControlView.swift
git commit -m "feat(pos): add Bookings menu item to floating control"
```

---

## Task 14: Add Feature Flag

**Files:**
- Modify: `WooCommerce/Classes/Copiable/FeatureFlag+Copiable.swift` (or wherever FeatureFlag is defined)

### Step 14.1: Find and read the FeatureFlag file

Locate the FeatureFlag enum to understand its structure.

### Step 14.2: Add the new feature flag

```swift
case pointOfSaleBookings
```

### Step 14.3: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 14.4: Commit

```bash
git add <feature-flag-file>
git commit -m "feat(pos): add pointOfSaleBookings feature flag"
```

---

## Task 15: Analytics Events

**Files:**
- Modify: `WooCommerce/Classes/Analytics/WooAnalyticsEvent+PointOfSale.swift`

### Step 15.1: Read the current analytics file

### Step 15.2: Add booking analytics events

```swift
// MARK: - Bookings

static func bookingsMenuItemTapped() -> WooAnalyticsEvent {
    WooAnalyticsEvent(statName: .posBookingsMenuItemTapped, properties: [:])
}

static let posBookingTapped = WooAnalyticsStat.posBookingTapped
static let posBookingCardPaymentStarted = WooAnalyticsStat.posBookingCardPaymentStarted
static let posBookingCashPaymentStarted = WooAnalyticsStat.posBookingCashPaymentStarted
static let posBookingPaymentDoneTapped = WooAnalyticsStat.posBookingPaymentDoneTapped
static let posBookingEmailReceiptTapped = WooAnalyticsStat.posBookingEmailReceiptTapped
static let posBookingCashPaymentCompleteTapped = WooAnalyticsStat.posBookingCashPaymentCompleteTapped
static let posBookingCashPaymentDoneTapped = WooAnalyticsStat.posBookingCashPaymentDoneTapped
static let posBookingCashEmailReceiptTapped = WooAnalyticsStat.posBookingCashEmailReceiptTapped
```

### Step 15.3: Add to WooAnalyticsStat enum (if needed)

Add the corresponding stat cases.

### Step 15.4: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 15.5: Commit

```bash
git add WooCommerce/Classes/Analytics/WooAnalyticsEvent+PointOfSale.swift <other-files>
git commit -m "feat(pos): add analytics events for bookings feature"
```

---

## Task 16: Wire Up Dependencies in Entry Point

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift`
- Modify: `Modules/Sources/PointOfSale/Protocols/POSDependencyProviding.swift`

### Step 16.1: Add booking service to dependencies

In `POSDependencyProviding` or entry point, ensure `POSBookingServiceProtocol` is injectable.

### Step 16.2: Create and inject POSBookingListController

Similar to how `POSOrderListModel` is created, create the booking controller and inject via environment.

### Step 16.3: Build to verify compilation

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 16.4: Commit

```bash
git add Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift Modules/Sources/PointOfSale/Protocols/POSDependencyProviding.swift
git commit -m "feat(pos): wire up booking dependencies in entry point"
```

---

## Task 17: Integration Testing

**Files:**
- Create: `Modules/Tests/PointOfSaleTests/Integration/POSBookingsIntegrationTests.swift`

### Step 17.1: Write integration test

```swift
// POSBookingsIntegrationTests.swift
import Testing
@testable import PointOfSale
@testable import Yosemite

@MainActor
struct POSBookingsIntegrationTests {
    @Test func bookings_flow_from_list_to_payment() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100, statusKey: "unpaid")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProviding()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When - Load bookings
        await controller.loadBookings()

        // Then - Bookings loaded
        #expect(controller.state.bookings.count == 1)

        // When - Select booking
        let posBooking = controller.state.bookings.first!
        controller.selectBooking(posBooking)

        // Then - Booking selected and can collect payment
        #expect(controller.selectedBooking != nil)
        #expect(posBooking.canCollectPayment == true)
    }

    @Test func paid_booking_cannot_collect_payment() async throws {
        // Given
        let bookingService = MockPOSBookingService()
        let booking = MockPOSBookingService.makeBooking(bookingID: 1, orderID: 100, statusKey: "paid")
        bookingService.bookingsToReturn = [booking]

        let currencySettings = MockPOSCurrencySettingsProviding()
        let controller = POSBookingListController(
            siteID: 123,
            bookingService: bookingService,
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings.currencySettings)
        )

        // When
        await controller.loadBookings()

        // Then
        let posBooking = controller.state.bookings.first!
        #expect(posBooking.canCollectPayment == false)
        #expect(posBooking.status == .paid)
    }
}
```

### Step 17.2: Run integration tests

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -only-testing:PointOfSaleTests/POSBookingsIntegrationTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 17.3: Commit

```bash
git add Modules/Tests/PointOfSaleTests/Integration/POSBookingsIntegrationTests.swift
git commit -m "test(pos): add integration tests for bookings flow"
```

---

## Task 18: Final Verification

### Step 18.1: Run all POS tests

```bash
xcodebuild test -workspace WooCommerce.xcworkspace -scheme PointOfSale -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: All tests pass

### Step 18.2: Run full build

```bash
xcodebuild build -workspace WooCommerce.xcworkspace -scheme WooCommerce -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | xcpretty
```

Expected: Build succeeds

### Step 18.3: Create final summary commit

```bash
git log --oneline -15
```

Review commits and ensure all changes are committed.

---

## Summary

This plan creates the POS Bookings Payment feature with:

- **6 new models**: POSBooking, POSBookingStatus, POSBookingListState, POSBookingPaymentState
- **2 new controllers**: POSBookingListController, POSBookingPaymentController
- **6 new views**: POSBookingRowView, POSBookingListView, POSBookingDetailView, POSBookingPaymentView, POSBookingCashPaymentView, POSBookingsContainerView
- **1 new service**: POSBookingService in Yosemite
- **Comprehensive tests**: Unit tests for models and controllers, integration tests

All code follows existing POS patterns and conventions.
