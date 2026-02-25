import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import protocol Yosemite.POSBookingServiceProtocol
import struct Yosemite.PagedItems
import enum Yosemite.BookingAttendanceStatus
import struct Yosemite.BookingFilters
import enum Yosemite.BookingStatus

final class MockPOSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    var defaultStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var searchStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var bookingService: POSBookingServiceProtocol = MockPOSBookingService()

    var lastSearchTerm: String?
    var searchStrategyCallCount = 0
    var defaultStrategyCallCount = 0
    var lastDefaultStrategyFilters: BookingFilters?
    var onDefaultStrategyCalled: (() -> Void)?

    func defaultStrategy(filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        defaultStrategyCallCount += 1
        lastDefaultStrategyFilters = filters
        onDefaultStrategyCalled?()
        return defaultStrategyResult
    }

    func searchStrategy(searchTerm: String, filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        lastSearchTerm = searchTerm
        searchStrategyCallCount += 1
        return searchStrategyResult
    }
}

final class MockPOSBookingService: POSBookingServiceProtocol {
    var fetchBookingsResult: Result<PagedItems<POSBooking>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
    var cancelBookingError: Error?
    var cancelBookingCallCount = 0
    var lastCancelledBookingID: Int64?
    var updateAttendanceError: Error?
    var updateAttendanceCallCount = 0
    var lastUpdatedAttendanceBookingID: Int64?
    var lastUpdatedAttendanceStatus: BookingAttendanceStatus?

    var fetchBookingResult: Result<POSBooking, Error>?
    var fetchBookingCallCount = 0
    var lastFetchedBookingID: Int64?

    func fetchBookings(siteID: Int64, pageNumber: Int, pageSize: Int, filters: BookingFilters?, searchQuery: String?) async throws -> PagedItems<POSBooking> {
        try fetchBookingsResult.get()
    }

    func fetchBooking(bookingID: Int64) async throws -> POSBooking {
        fetchBookingCallCount += 1
        lastFetchedBookingID = bookingID
        guard let result = fetchBookingResult else {
            throw NSError(domain: "MockPOSBookingService", code: 0)
        }
        return try result.get()
    }

    var cancelBookingStatusResult: BookingStatus = .cancelled

    func cancelBooking(bookingID: Int64) async throws -> BookingStatus {
        cancelBookingCallCount += 1
        lastCancelledBookingID = bookingID
        if let error = cancelBookingError {
            throw error
        }
        return cancelBookingStatusResult
    }

    var updateAttendanceStatusResult: BookingAttendanceStatus?

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws -> BookingAttendanceStatus {
        updateAttendanceCallCount += 1
        lastUpdatedAttendanceBookingID = bookingID
        lastUpdatedAttendanceStatus = status
        if let error = updateAttendanceError {
            throw error
        }
        return updateAttendanceStatusResult ?? status
    }

    var updateBookingNoteError: Error?
    var updateBookingNoteCallCount = 0
    var lastUpdatedNoteBookingID: Int64?
    var lastUpdatedNote: String?

    func updateBookingNote(bookingID: Int64, note: String) async throws -> String {
        updateBookingNoteCallCount += 1
        lastUpdatedNoteBookingID = bookingID
        lastUpdatedNote = note
        if let error = updateBookingNoteError {
            throw error
        }
        return note
    }
}

final class MockPOSBookingListFetchStrategy: POSBookingListFetchStrategy {
    var fetchBookingsResult: Result<PagedItems<POSBooking>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
    var localBookings: [POSBooking] = []
    var showsCachedDataWhileLoading: Bool = true
    var id: String = "MockPOSBookingListFetchStrategy"
    var onFetchBookingsCalled: ((Int) -> Void)?

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        onFetchBookingsCalled?(pageNumber)
        return try fetchBookingsResult.get()
    }

    func fetchLocalBookings() -> [POSBooking] {
        localBookings
    }
}
