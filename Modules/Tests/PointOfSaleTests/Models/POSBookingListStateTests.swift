import XCTest
@testable import PointOfSale
import struct Yosemite.POSBooking
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

final class POSBookingListStateTests: XCTestCase {

    // MARK: - bookings computed property

    func test_bookings_returns_bookings_when_loading() {
        // Given
        let bookings = [makeBooking(id: 1), makeBooking(id: 2)]
        let state = POSBookingListState.loading(bookings)

        // Then
        XCTAssertEqual(state.bookings, bookings)
    }

    func test_bookings_returns_bookings_when_loaded() {
        // Given
        let bookings = [makeBooking(id: 1)]
        let state = POSBookingListState.loaded(bookings, hasMoreItems: true)

        // Then
        XCTAssertEqual(state.bookings, bookings)
    }

    func test_bookings_returns_bookings_when_inlineError() {
        // Given
        let bookings = [makeBooking(id: 1)]
        let state = POSBookingListState.inlineError(bookings,
                                                     error: .errorOnLoadingBookings(),
                                                     context: .refresh)

        // Then
        XCTAssertEqual(state.bookings, bookings)
    }

    func test_bookings_returns_empty_when_error() {
        // Given
        let state = POSBookingListState.error(.errorOnLoadingBookings())

        // Then
        XCTAssertTrue(state.bookings.isEmpty)
    }

    func test_bookings_returns_empty_when_empty() {
        // Given
        let state = POSBookingListState.empty

        // Then
        XCTAssertTrue(state.bookings.isEmpty)
    }

    // MARK: - isLoading computed property

    func test_isLoading_returns_true_when_loading() {
        let state = POSBookingListState.loading([])
        XCTAssertTrue(state.isLoading)
    }

    func test_isLoading_returns_false_when_loaded() {
        let state = POSBookingListState.loaded([], hasMoreItems: false)
        XCTAssertFalse(state.isLoading)
    }

    func test_isLoading_returns_false_when_empty() {
        let state = POSBookingListState.empty
        XCTAssertFalse(state.isLoading)
    }

    func test_isLoading_returns_false_when_error() {
        let state = POSBookingListState.error(.errorOnLoadingBookings())
        XCTAssertFalse(state.isLoading)
    }

    // MARK: - isEmpty computed property

    func test_isEmpty_returns_true_when_loading_with_no_bookings() {
        let state = POSBookingListState.loading([])
        XCTAssertTrue(state.isEmpty)
    }

    func test_isEmpty_returns_false_when_loading_with_bookings() {
        let state = POSBookingListState.loading([makeBooking(id: 1)])
        XCTAssertFalse(state.isEmpty)
    }

    func test_isEmpty_returns_false_when_loaded() {
        let state = POSBookingListState.loaded([makeBooking(id: 1)], hasMoreItems: false)
        XCTAssertFalse(state.isEmpty)
    }

    func test_isEmpty_returns_true_when_empty() {
        let state = POSBookingListState.empty
        XCTAssertTrue(state.isEmpty)
    }

    func test_isEmpty_returns_true_when_error() {
        let state = POSBookingListState.error(.errorOnLoadingBookings())
        XCTAssertTrue(state.isEmpty)
    }

    // MARK: - updatingBookings

    func test_updatingBookings_updates_loaded_state() {
        // Given
        let original = POSBookingListState.loaded([makeBooking(id: 1)], hasMoreItems: true)
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        XCTAssertEqual(result, .loaded(updated, hasMoreItems: true))
    }

    func test_updatingBookings_updates_loading_state() {
        // Given
        let original = POSBookingListState.loading([makeBooking(id: 1)])
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        XCTAssertEqual(result, .loading(updated))
    }

    func test_updatingBookings_updates_inlineError_state() {
        // Given
        let error = PointOfSaleErrorState.errorOnLoadingBookings()
        let original = POSBookingListState.inlineError([makeBooking(id: 1)], error: error, context: .refresh)
        let updated = [makeBooking(id: 2)]

        // When
        let result = original.updatingBookings(with: updated)

        // Then
        XCTAssertEqual(result, .inlineError(updated, error: error, context: .refresh))
    }

    func test_updatingBookings_returns_same_state_when_empty() {
        // Given
        let original = POSBookingListState.empty

        // When
        let result = original.updatingBookings(with: [makeBooking(id: 1)])

        // Then
        XCTAssertEqual(result, .empty)
    }

    func test_updatingBookings_returns_same_state_when_error() {
        // Given
        let error = PointOfSaleErrorState.errorOnLoadingBookings()
        let original = POSBookingListState.error(error)

        // When
        let result = original.updatingBookings(with: [makeBooking(id: 1)])

        // Then
        XCTAssertEqual(result, .error(error))
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
            attendanceStatus: .booked,
            orderID: id * 10,
            resourceName: nil
        )
    }
}
