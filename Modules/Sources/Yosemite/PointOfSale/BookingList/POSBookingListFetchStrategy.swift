import Foundation
import struct NetworkingCore.PagedItems

public protocol POSBookingListFetchStrategy {
    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking>
    @MainActor func fetchLocalBookings() -> [POSBooking]
    var showsCachedDataWhileLoading: Bool { get }
    var id: String { get }
}

extension POSBookingListFetchStrategy {
    public var id: String {
        String(describing: type(of: self))
    }
}

struct POSDefaultBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let store: POSBookingInMemoryStore
    private let siteID: Int64
    private let pageSize: Int
    private let filters: BookingFilters?
    let showsCachedDataWhileLoading: Bool = true

    var id: String {
        "POSDefaultBookingListFetchStrategy-\(filters?.startDateAfter ?? "none")"
    }

    init(bookingService: POSBookingServiceProtocol,
         store: POSBookingInMemoryStore,
         siteID: Int64,
         filters: BookingFilters? = nil,
         pageSize: Int = 25) {
        self.bookingService = bookingService
        self.store = store
        self.siteID = siteID
        self.filters = filters
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        guard let filters, let dateRange = dateRange(from: filters) else {
            return PagedItems(items: [], hasMorePages: false, totalItems: nil)
        }

        let pagedItems = try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: nil
        )

        let allBookings = await MainActor.run {
            if pageNumber == 1 {
                store.replaceBookings(pagedItems.items, for: dateRange)
            } else {
                store.appendBookings(pagedItems.items, for: dateRange)
            }
            return store.allBookings(for: dateRange)
        }
        return PagedItems(items: allBookings, hasMorePages: pagedItems.hasMorePages, totalItems: nil)
    }

    @MainActor
    func fetchLocalBookings() -> [POSBooking] {
        guard let filters, let dateRange = dateRange(from: filters) else { return [] }
        return store.bookings(for: dateRange, limit: pageSize)
    }
}

private extension POSDefaultBookingListFetchStrategy {
    func dateRange(from filters: BookingFilters) -> POSBookingInMemoryStore.DateRange? {
        guard let after = filters.startDateAfter,
              let before = filters.startDateBefore else {
            return nil
        }
        return POSBookingInMemoryStore.DateRange(startDateAfter: after, startDateBefore: before)
    }
}

struct POSSearchBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let siteID: Int64
    private let searchTerm: String
    private let pageSize: Int
    private let filters: BookingFilters?
    let showsCachedDataWhileLoading: Bool = false

    var id: String {
        "POSSearchBookingListFetchStrategy-\(searchTerm)-\(filters?.startDateAfter ?? "none")"
    }

    init(bookingService: POSBookingServiceProtocol, siteID: Int64, searchTerm: String, filters: BookingFilters? = nil, pageSize: Int = 25) {
        self.bookingService = bookingService
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.filters = filters
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: searchTerm
        )
    }

    @MainActor
    func fetchLocalBookings() -> [POSBooking] {
        []
    }
}
