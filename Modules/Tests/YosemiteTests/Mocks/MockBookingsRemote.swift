import Foundation
@testable import Networking

/// Mock for BookingsRemoteProtocol
///
final class MockBookingsRemote: BookingsRemoteProtocol {
    private var loadAllBookingsResult: Result<[Booking], Error>?

    func whenLoadingAllBookings(thenReturn result: Result<[Booking], Error>) {
        loadAllBookingsResult = result
    }

    func loadAllBookings(for siteID: Int64,
                         pageNumber: Int,
                         pageSize: Int,
                         startDateBefore: String?,
                         startDateAfter: String?) async throws -> [Booking] {
        guard let result = loadAllBookingsResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }
}
