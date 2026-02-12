import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.POSOrder
import enum NetworkingCore.OrderStatusEnum
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus

struct POSBookingListStateTests {

    // MARK: - bookings computed property

    @Test func test_bookings_returns_bookings_when_loading() {
        // Given
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]
        let state = POSBookingListState.loading(bookings)

        // Then
        #expect(state.bookings == bookings)
    }

    @Test func test_bookings_returns_bookings_when_loaded() {
        // Given
        let bookings = [makeBooking(id: 1)]
        let state = POSBookingListState.loaded(bookings, hasMoreItems: true)

        // Then
        #expect(state.bookings == bookings)
    }

    @Test func test_bookings_returns_bookings_when_inlineError() {
        // Given
        let bookings = [makeBooking(id: 1)]
        let state = POSBookingListState.inlineError(bookings,
                                                     error: .errorOnLoadingBookings(),
                                                     context: .refresh)

        // Then
        #expect(state.bookings == bookings)
    }

    @Test func test_bookings_returns_empty_when_error() {
        // Given
        let state = POSBookingListState.error(.errorOnLoadingBookings())

        // Then
        #expect(state.bookings.isEmpty)
    }

    @Test func test_bookings_returns_empty_when_empty() {
        // Given
        let state = POSBookingListState.empty

        // Then
        #expect(state.bookings.isEmpty)
    }

    // MARK: - isLoading computed property

    @Test func test_isLoading_returns_true_when_loading() {
        let state = POSBookingListState.loading([])
        #expect(state.isLoading)
    }

    @Test func test_isLoading_returns_false_when_loaded() {
        let state = POSBookingListState.loaded([], hasMoreItems: false)
        #expect(!state.isLoading)
    }

    @Test func test_isLoading_returns_false_when_empty() {
        let state = POSBookingListState.empty
        #expect(!state.isLoading)
    }

    @Test func test_isLoading_returns_false_when_error() {
        let state = POSBookingListState.error(.errorOnLoadingBookings())
        #expect(!state.isLoading)
    }

    // MARK: - isEmpty computed property

    @Test func test_isEmpty_returns_true_when_loading_with_no_bookings() {
        let state = POSBookingListState.loading([])
        #expect(state.isEmpty)
    }

    @Test func test_isEmpty_returns_false_when_loading_with_bookings() {
        let state = POSBookingListState.loading([makeBooking(id: 1)])
        #expect(!state.isEmpty)
    }

    @Test func test_isEmpty_returns_false_when_loaded() {
        let state = POSBookingListState.loaded([makeBooking(id: 1)], hasMoreItems: false)
        #expect(!state.isEmpty)
    }

    @Test func test_isEmpty_returns_true_when_empty() {
        let state = POSBookingListState.empty
        #expect(state.isEmpty)
    }

    @Test func test_isEmpty_returns_true_when_error() {
        let state = POSBookingListState.error(.errorOnLoadingBookings())
        #expect(state.isEmpty)
    }

    // MARK: - updatingBookings

    @Test func test_updatingBookings_updates_loaded_state() {
        // Given
        let original = POSBookingListState.loaded([makeBooking(id: 1)], hasMoreItems: true)
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        #expect(result == .loaded(updated, hasMoreItems: true))
    }

    @Test func test_updatingBookings_updates_loading_state() {
        // Given
        let original = POSBookingListState.loading([makeBooking(id: 1)])
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        #expect(result == .loading(updated))
    }

    @Test func test_updatingBookings_updates_inlineError_state() {
        // Given
        let error = PointOfSaleErrorState.errorOnLoadingBookings()
        let original = POSBookingListState.inlineError([makeBooking(id: 1)], error: error, context: .refresh)
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        #expect(result == .inlineError(updated, error: error, context: .refresh))
    }

    @Test func test_updatingBookings_returns_same_state_when_empty() {
        // Given
        let original = POSBookingListState.empty

        // When
        let result = original.updatingBookings(with: [makeBooking(id: 1)])

        // Then
        #expect(result == .empty)
    }

    @Test func test_updatingBookings_returns_same_state_when_error() {
        // Given
        let error = PointOfSaleErrorState.errorOnLoadingBookings()
        let original = POSBookingListState.error(error)

        // When
        let result = original.updatingBookings(with: [makeBooking(id: 1)])

        // Then
        #expect(result == .error(error))
    }
}

// MARK: - Helpers

private extension POSBookingListStateTests {
    func makeBooking(id: Int64) -> POSBooking {
        POSBooking(
            id: id,
            customerName: "Customer \(id)",
            serviceName: "Service \(id)",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            formattedAmount: "$50.00",
            status: .confirmed,
            attendanceStatus: .unattended,
            orderID: id * 10,
            resourceName: nil,
            order: makeOrder(id: id * 10)
        )
    }

    func makeOrder(id: Int64) -> POSOrder {
        POSOrder(
            id: id,
            number: "\(id)",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$50.00",
            formattedSubtotal: "$50.00",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$50.00"
        )
    }
}
