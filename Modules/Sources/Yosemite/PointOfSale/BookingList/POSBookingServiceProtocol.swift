import Foundation
import struct NetworkingCore.PagedItems

public enum POSBookingServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
}

public protocol POSBookingServiceProtocol: Sendable {
    func fetchBookings(siteID: Int64,
                       pageNumber: Int,
                       pageSize: Int,
                       searchQuery: String?) async throws -> PagedItems<POSBooking>
}
