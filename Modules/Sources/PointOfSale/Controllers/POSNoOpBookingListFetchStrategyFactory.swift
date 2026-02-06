import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import struct Yosemite.POSBooking
import struct NetworkingCore.PagedItems

struct POSNoOpBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> POSBookingListFetchStrategy {
        POSNoOpBookingListFetchStrategy()
    }

    func searchStrategy(searchTerm: String) -> POSBookingListFetchStrategy {
        POSNoOpBookingListFetchStrategy()
    }
}

private struct POSNoOpBookingListFetchStrategy: POSBookingListFetchStrategy {
    var supportsCaching: Bool { false }
    var showsLoadingWithItems: Bool { false }
    var id: String { "NoOp" }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        PagedItems(items: [], hasMorePages: false, totalItems: nil)
    }
}
