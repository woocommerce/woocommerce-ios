import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import protocol Yosemite.POSBookingServiceProtocol
import struct Yosemite.PagedItems
import enum Yosemite.BookingAttendanceStatus
import struct Yosemite.BookingFilters

final class MockPOSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    var defaultStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var searchStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var bookingService: POSBookingServiceProtocol = MockPOSBookingService()

    func defaultStrategy(filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        defaultStrategyResult
    }

    func searchStrategy(searchTerm: String, filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        searchStrategyResult
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

    func fetchBookings(siteID: Int64, pageNumber: Int, pageSize: Int, filters: BookingFilters?, searchQuery: String?) async throws -> PagedItems<POSBooking> {
        try fetchBookingsResult.get()
    }

    func cancelBooking(bookingID: Int64) async throws {
        cancelBookingCallCount += 1
        lastCancelledBookingID = bookingID
        if let error = cancelBookingError {
            throw error
        }
    }

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws {
        updateAttendanceCallCount += 1
        lastUpdatedAttendanceBookingID = bookingID
        lastUpdatedAttendanceStatus = status
        if let error = updateAttendanceError {
            throw error
        }
    }
}

final class MockPOSBookingListFetchStrategy: POSBookingListFetchStrategy {
    var fetchBookingsResult: Result<PagedItems<POSBooking>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
    var supportsCaching: Bool = true
    var showsLoadingWithItems: Bool = true
    var id: String = "MockPOSBookingListFetchStrategy"

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try fetchBookingsResult.get()
    }
}
