import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.BookingFilters
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus

@MainActor
final class MockPOSBookingListController: POSSearchingBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState = .loading([])
    var selectedBooking: POSBooking?
    var selectedDate: Date = Date()

    // MARK: - Spy properties

    var syncBookingsCalled = false
    var loadBookingsCalled = false
    var refreshBookingsCalled = false
    var loadNextBookingsCalled = false
    var selectBookingCalledWith: POSBooking??
    var selectDateCalledWith: Date?
    var cancelBookingCalledWith: Int64?
    var updateAttendanceStatusCalledWith: (bookingID: Int64, status: BookingAttendanceStatus)?
    var updateBookingCalledWith: Int64?
    var updateBookingNoteCalledWith: (bookingID: Int64, note: String)?
    var searchBookingsCalledWith: String?
    var clearSearchBookingsCalled = false

    // MARK: - Optimistic update tracking

    var updateBookingOptimisticallyCalledWith: Int64?
    /// Set this before calling the method under test to capture the optimistic update result.
    var bookingForOptimisticUpdate: POSBooking?
    private(set) var optimisticUpdateResult: POSBooking?

    // MARK: - POSBookingListControllerProtocol

    func syncBookings() {
        syncBookingsCalled = true
    }

    func loadBookings() async {
        loadBookingsCalled = true
    }

    func refreshBookings() async {
        refreshBookingsCalled = true
    }

    func loadNextBookings() async {
        loadNextBookingsCalled = true
    }

    func selectBooking(_ booking: POSBooking?) {
        selectBookingCalledWith = booking
        selectedBooking = booking
    }

    func selectDate(_ date: Date) async {
        selectDateCalledWith = date
    }

    func goToPreviousDay() async {}

    func goToNextDay() async {}

    func cancelBooking(bookingID: Int64) async throws {
        cancelBookingCalledWith = bookingID
    }

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws {
        updateAttendanceStatusCalledWith = (bookingID, status)
    }

    func updateBooking(bookingID: Int64) async throws {
        updateBookingCalledWith = bookingID
    }

    func updateBookingOptimistically(bookingID: Int64, optimisticUpdate: (POSBooking) -> POSBooking) async {
        updateBookingOptimisticallyCalledWith = bookingID
        if let booking = bookingForOptimisticUpdate {
            optimisticUpdateResult = optimisticUpdate(booking)
        }
    }

    func updateBookingNote(bookingID: Int64, note: String) async throws {
        updateBookingNoteCalledWith = (bookingID, note)
    }

    // MARK: - POSSearchingBookingListControllerProtocol

    func searchBookings(searchTerm: String) async {
        searchBookingsCalledWith = searchTerm
    }

    func clearSearchBookings() {
        clearSearchBookingsCalled = true
    }
}
