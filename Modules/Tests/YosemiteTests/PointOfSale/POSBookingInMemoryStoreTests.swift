import Testing
import Foundation
@testable import Yosemite

@MainActor
struct POSBookingInMemoryStoreTests {

    private let dateRange = POSBookingInMemoryStore.DateRange(
        startDateAfter: "2026-03-15T00:00:00Z",
        startDateBefore: "2026-03-15T23:59:59Z"
    )

    // MARK: - replaceBookings

    @Test func test_replaceBookings_stores_bookings() {
        // Given
        let store = POSBookingInMemoryStore()
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]

        // When
        store.replaceBookings(bookings, for: dateRange)

        // Then
        #expect(store.allBookings(for: dateRange) == bookings)
    }

    @Test func test_replaceBookings_clears_existing_bookings() {
        // Given
        let store = POSBookingInMemoryStore()
        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2)], for: dateRange)

        let newBookings = [makeBooking(id: 3)]

        // When
        store.replaceBookings(newBookings, for: dateRange)

        // Then
        #expect(store.allBookings(for: dateRange) == newBookings)
    }

    // MARK: - appendBookings

    @Test func test_appendBookings_adds_to_existing() {
        // Given
        let store = POSBookingInMemoryStore()
        store.replaceBookings([makeBooking(id: 1)], for: dateRange)

        // When
        store.appendBookings([makeBooking(id: 2)], for: dateRange)

        // Then
        let ids = store.allBookings(for: dateRange).map(\.id)
        #expect(ids == [1, 2])
    }

    @Test func test_appendBookings_deduplicates_by_id() {
        // Given
        let store = POSBookingInMemoryStore()
        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2)], for: dateRange)

        // When
        store.appendBookings([makeBooking(id: 2), makeBooking(id: 3)], for: dateRange)

        // Then
        let ids = store.allBookings(for: dateRange).map(\.id)
        #expect(ids == [1, 2, 3])
    }

    @Test func test_appendBookings_when_no_existing_data_then_stores_bookings() {
        // Given
        let store = POSBookingInMemoryStore()

        // When
        store.appendBookings([makeBooking(id: 1)], for: dateRange)

        // Then
        #expect(store.allBookings(for: dateRange).count == 1)
    }

    // MARK: - bookings with limit

    @Test func test_bookings_with_limit_returns_prefix() {
        // Given
        let store = POSBookingInMemoryStore()
        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2), makeBooking(id: 3)], for: dateRange)

        // When
        let result = store.bookings(for: dateRange, limit: 2)

        // Then
        #expect(result.count == 2)
        #expect(result.map(\.id) == [1, 2])
    }

    @Test func test_bookings_with_nil_limit_returns_all() {
        // Given
        let store = POSBookingInMemoryStore()
        store.replaceBookings([makeBooking(id: 1), makeBooking(id: 2), makeBooking(id: 3)], for: dateRange)

        // When
        let result = store.bookings(for: dateRange, limit: nil)

        // Then
        #expect(result.count == 3)
    }

    // MARK: - Isolation between date ranges

    @Test func test_different_date_ranges_are_isolated() {
        // Given
        let store = POSBookingInMemoryStore()
        let otherRange = POSBookingInMemoryStore.DateRange(
            startDateAfter: "2026-03-16T00:00:00Z",
            startDateBefore: "2026-03-16T23:59:59Z"
        )
        store.replaceBookings([makeBooking(id: 1)], for: dateRange)

        // When/Then
        #expect(store.allBookings(for: otherRange).isEmpty)
    }

    @Test func test_replace_on_one_date_does_not_affect_another() {
        // Given
        let store = POSBookingInMemoryStore()
        let otherRange = POSBookingInMemoryStore.DateRange(
            startDateAfter: "2026-03-16T00:00:00Z",
            startDateBefore: "2026-03-16T23:59:59Z"
        )
        store.replaceBookings([makeBooking(id: 1)], for: dateRange)
        store.replaceBookings([makeBooking(id: 2)], for: otherRange)

        // When
        store.replaceBookings([makeBooking(id: 3)], for: dateRange)

        // Then
        #expect(store.allBookings(for: dateRange).map(\.id) == [3])
        #expect(store.allBookings(for: otherRange).map(\.id) == [2])
    }

    // MARK: - Sorting

    @Test func test_allBookings_are_sorted_by_startDate_then_id() {
        // Given
        let store = POSBookingInMemoryStore()
        let earlyDate = Date(timeIntervalSince1970: 1000)
        let lateDate = Date(timeIntervalSince1970: 2000)
        let bookings = [
            makeBooking(id: 3, startDate: lateDate),
            makeBooking(id: 1, startDate: earlyDate),
            makeBooking(id: 2, startDate: earlyDate)
        ]
        store.replaceBookings(bookings, for: dateRange)

        // When
        let result = store.allBookings(for: dateRange)

        // Then - sorted by startDate ascending, then id ascending
        #expect(result.map(\.id) == [1, 2, 3])
    }

    @Test func test_bookings_with_limit_are_sorted_before_limiting() {
        // Given
        let store = POSBookingInMemoryStore()
        let earlyDate = Date(timeIntervalSince1970: 1000)
        let lateDate = Date(timeIntervalSince1970: 2000)
        store.replaceBookings([
            makeBooking(id: 3, startDate: lateDate),
            makeBooking(id: 1, startDate: earlyDate)
        ], for: dateRange)

        // When
        let result = store.bookings(for: dateRange, limit: 1)

        // Then - sorted first, then limited
        #expect(result.map(\.id) == [1])
    }

    // MARK: - Empty state

    @Test func test_allBookings_returns_empty_for_unknown_date_range() {
        // Given
        let store = POSBookingInMemoryStore()

        // Then
        #expect(store.allBookings(for: dateRange).isEmpty)
    }

    @Test func test_bookings_returns_empty_for_unknown_date_range() {
        // Given
        let store = POSBookingInMemoryStore()

        // Then
        #expect(store.bookings(for: dateRange, limit: 10).isEmpty)
    }
}

// MARK: - Helpers

private extension POSBookingInMemoryStoreTests {
    func makeBooking(id: Int64, startDate: Date = Date()) -> POSBooking {
        POSBooking(
            id: id,
            customerName: "Customer \(id)",
            serviceName: "Service \(id)",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600),
            formattedAmount: "$50.00",
            status: .confirmed,
            attendanceStatus: .unattended,
            orderID: id * 10,
            resourceName: nil,
            order: POSOrder(
                id: id * 10,
                number: "\(id * 10)",
                dateCreated: Date(),
                status: .completed,
                formattedTotal: "$50.00",
                formattedSubtotal: "$50.00",
                paymentMethodID: "cod",
                paymentMethodTitle: "Cash",
                formattedDiscountTotal: nil,
                formattedTotalTax: "$0.00",
                formattedPaymentTotal: "$50.00",
                datePaid: Date()
            )
        )
    }
}
