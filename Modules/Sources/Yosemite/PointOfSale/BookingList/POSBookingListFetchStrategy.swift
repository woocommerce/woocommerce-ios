import Foundation
import struct NetworkingCore.PagedItems

public protocol POSBookingListFetchStrategy {
    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking>
    var supportsCaching: Bool { get }
    var showsLoadingWithItems: Bool { get }
    var id: String { get }
}

extension POSBookingListFetchStrategy {
    public var id: String {
        String(describing: type(of: self))
    }
}

struct POSDefaultBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let siteID: Int64
    private let pageSize: Int
    private let filters: BookingFilters?
    let supportsCaching: Bool = true
    let showsLoadingWithItems: Bool = true

    var id: String {
        "POSDefaultBookingListFetchStrategy-\(filters?.startDateAfter ?? "none")"
    }

    init(bookingService: POSBookingServiceProtocol, siteID: Int64, filters: BookingFilters? = nil, pageSize: Int = 25) {
        self.bookingService = bookingService
        self.siteID = siteID
        self.filters = filters
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: nil
        )
    }
}

struct POSSearchBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let siteID: Int64
    private let searchTerm: String
    private let pageSize: Int
    private let filters: BookingFilters?
    let supportsCaching: Bool = false
    let showsLoadingWithItems: Bool = false

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
}
