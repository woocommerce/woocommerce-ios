import Foundation
@testable import Networking

/// Mock for BookingsRemoteProtocol
///
final class MockBookingsRemote: BookingsRemoteProtocol {
    private var loadAllBookingsResult: Result<[Booking], Error>?
    private var loadBookingResult: Result<Booking?, Error>?
    private var fetchResourceResult: Result<BookingResource?, Error>?
    private var updateBookingResult: Result<Booking?, Error>?
    private var fetchResourcesResult: Result<[BookingResource], Error>?
    private var updateBookingNote: Result<Booking?, Error>?
    private var fetchBookingLocationResponseResult: Result<BookingLocationResponse, Error>?
    private var rescheduleBookingResult: Result<Booking?, Error>?

    func whenLoadingAllBookings(thenReturn result: Result<[Booking], Error>) {
        loadAllBookingsResult = result
    }

    func whenLoadingBooking(thenReturn result: Result<Booking?, Error>) {
        loadBookingResult = result
    }

    func whenUpdatingBooking(thenReturn result: Result<Booking?, Error>) {
        updateBookingResult = result
    }

    func whenFetchingResource(thenReturn result: Result<BookingResource?, Error>) {
        fetchResourceResult = result
    }

    func whenFetchingResources(thenReturn result: Result<[BookingResource], Error>) {
        fetchResourcesResult = result
    }

    func whenFetchingBookingLocationResponse(thenReturn result: Result<BookingLocationResponse, Error>) {
        fetchBookingLocationResponseResult = result
    }

    func whenReschedulingBooking(thenReturn result: Result<Booking?, Error>) {
        rescheduleBookingResult = result
    }

    func loadAllBookings(for siteID: Int64,
                         pageNumber: Int,
                         pageSize: Int,
                         filters: BookingFilters?,
                         searchQuery: String?,
                         order: BookingsRemote.Order) async throws -> [Booking] {
        guard let result = loadAllBookingsResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func loadBooking(bookingID: Int64, siteID: Int64) async throws -> Booking? {
        guard let result = loadBookingResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func fetchResource(resourceID: Int64, siteID: Int64) async throws -> BookingResource? {
        guard let result = fetchResourceResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func updateBooking(from siteID: Int64,
                       bookingID: Int64,
                       attendanceStatus: BookingAttendanceStatus?,
                       bookingStatus: BookingStatus?,
                       note: String?) async throws -> Booking? {
        guard let result = updateBookingResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func fetchResources(for siteID: Int64, pageNumber: Int, pageSize: Int, include: [Int64]?) async throws -> [BookingResource] {
        guard let result = fetchResourcesResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func fetchBookingLocationResponse(for siteID: Int64, productID: Int64) async throws -> BookingLocationResponse {
        guard let result = fetchBookingLocationResponseResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func rescheduleBooking(from siteID: Int64,
                           bookingID: Int64,
                           startDate: Date,
                           endDate: Date,
                           resourceID: Int64?) async throws -> Booking? {
        guard let result = rescheduleBookingResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }
}
