import Foundation
import struct NetworkingCore.PagedItems
import class Networking.BookingsRemote

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
    private let order: BookingsRemote.Order
    let supportsCaching: Bool = true
    let showsLoadingWithItems: Bool = true

    var id: String {
        "POSDefaultBookingListFetchStrategy-\(order.rawValue)"
    }

    init(bookingService: POSBookingServiceProtocol, siteID: Int64, order: BookingsRemote.Order = .ascending, pageSize: Int = 25) {
        self.bookingService = bookingService
        self.siteID = siteID
        self.order = order
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            searchQuery: nil,
            order: order
        )
    }
}

struct POSSearchBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let siteID: Int64
    private let searchTerm: String
    private let pageSize: Int
    private let order: BookingsRemote.Order
    let supportsCaching: Bool = false
    let showsLoadingWithItems: Bool = false

    var id: String {
        "POSSearchBookingListFetchStrategy-\(order.rawValue)"
    }

    init(bookingService: POSBookingServiceProtocol, siteID: Int64, searchTerm: String, order: BookingsRemote.Order = .ascending, pageSize: Int = 25) {
        self.bookingService = bookingService
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.order = order
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            searchQuery: searchTerm,
            order: order
        )
    }
}
