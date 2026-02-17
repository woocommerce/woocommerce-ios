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

    func cancelBooking(bookingID: Int64) async throws -> BookingStatus

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws -> BookingAttendanceStatus
}
