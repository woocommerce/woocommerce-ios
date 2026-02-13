import Foundation
import struct NetworkingCore.PagedItems
import class Networking.BookingsRemote

public enum POSBookingServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol POSBookingServiceProtocol: Sendable {
    func fetchBookings(siteID: Int64,
                       pageNumber: Int,
                       pageSize: Int,
                       searchQuery: String?,
                       order: BookingsRemote.Order) async throws -> PagedItems<POSBooking>

    func cancelBooking(bookingID: Int64) async throws
}
