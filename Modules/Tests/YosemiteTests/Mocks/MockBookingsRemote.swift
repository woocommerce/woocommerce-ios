import Foundation
@testable import Networking

/// Mock for BookingsRemoteProtocol
///
final class MockBookingsRemote: BookingsRemoteProtocol {
    private var loadAllBookingsResult: Result<[Booking], Error>?
    private var loadBookingResult: Result<Booking?, Error>?

    func whenLoadingAllBookings(thenReturn result: Result<[Booking], Error>) {
        loadAllBookingsResult = result
    }

    func whenLoadingBooking(thenReturn result: Result<Booking?, Error>) {
        loadBookingResult = result
    }

    func loadAllBookings(for siteID: Int64,
                         pageNumber: Int,
                         pageSize: Int,
                         startDateBefore: String?,
                         startDateAfter: String?,
                         searchQuery: String?,
                         order: BookingsRemote.Order) async throws -> [Booking] {
        guard let result = loadAllBookingsResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func loadBooking(bookingID: Int64, siteID: Int64) async throws -> Networking.Booking? {
        guard let result = loadBookingResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }
}
