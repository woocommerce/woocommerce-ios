import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import protocol Yosemite.POSBookingServiceProtocol
import struct Yosemite.PagedItems
import class Networking.BookingsRemote

final class MockPOSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    var defaultStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var searchStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var bookingService: POSBookingServiceProtocol = MockPOSBookingService()

    var lastDefaultStrategyOrder: BookingsRemote.Order?
    var lastSearchStrategyOrder: BookingsRemote.Order?

    func defaultStrategy(order: BookingsRemote.Order) -> POSBookingListFetchStrategy {
        lastDefaultStrategyOrder = order
        return defaultStrategyResult
    }

    func searchStrategy(searchTerm: String, order: BookingsRemote.Order) -> POSBookingListFetchStrategy {
        lastSearchStrategyOrder = order
        return searchStrategyResult
    }
}

final class MockPOSBookingService: POSBookingServiceProtocol {
    var fetchBookingsResult: Result<PagedItems<POSBooking>, Error> = .success(PagedItems(items: [], hasMorePages: false, totalItems: nil))
    var cancelBookingError: Error?
    var cancelBookingCallCount = 0
    var lastCancelledBookingID: Int64?

    var lastFetchOrder: BookingsRemote.Order?

    func fetchBookings(siteID: Int64, pageNumber: Int, pageSize: Int, searchQuery: String?, order: BookingsRemote.Order) async throws -> PagedItems<POSBooking> {
        lastFetchOrder = order
        return try fetchBookingsResult.get()
    }

    func cancelBooking(bookingID: Int64) async throws {
        cancelBookingCallCount += 1
        lastCancelledBookingID = bookingID
        if let error = cancelBookingError {
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
