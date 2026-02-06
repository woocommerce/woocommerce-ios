import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import struct Yosemite.PagedItems

final class MockPOSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    var defaultStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()
    var searchStrategyResult: POSBookingListFetchStrategy = MockPOSBookingListFetchStrategy()

    func defaultStrategy() -> POSBookingListFetchStrategy {
        defaultStrategyResult
    }

    func searchStrategy(searchTerm: String) -> POSBookingListFetchStrategy {
        searchStrategyResult
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
