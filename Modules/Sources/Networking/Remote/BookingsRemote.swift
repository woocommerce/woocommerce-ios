// periphery:ignore:all
import Foundation

/// Protocol for `BookingsRemote` mainly used for mocking.
///
/// The required methods are intentionally incomplete. Feel free to add the other ones.
///
public protocol BookingsRemoteProtocol {
    func loadAllBookings(for siteID: Int64,
                         pageNumber: Int,
                         pageSize: Int,
                         startDateBefore: String?,
                         startDateAfter: String?,
                         searchQuery: String?,
                         order: BookingsRemote.Order) async throws -> [Booking]

    func loadBooking(bookingID: Int64,
                     siteID: Int64) async throws -> Booking?

    func updateBooking(
        from siteID: Int64,
        bookingID: Int64,
        attendanceStatus: BookingAttendanceStatus
    ) async throws -> Booking?

    func fetchResource(resourceID: Int64,
                       siteID: Int64) async throws -> BookingResource?
}

/// Booking: Remote Endpoints
///
public final class BookingsRemote: Remote, BookingsRemoteProtocol {

    // MARK: - Bookings

    /// Retrieves all of the `Bookings` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote bookings.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of bookings to be retrieved per page.
    ///     - startDateBefore: Filter bookings with start date before this timestamp.
    ///     - startDateAfter: Filter bookings with start date after this timestamp.
    ///     - searchQuery: Search query to filter bookings.
    ///     - order: Sort order for bookings (ascending or descending).
    ///
    public func loadAllBookings(for siteID: Int64,
                                pageNumber: Int = Default.pageNumber,
                                pageSize: Int = Default.pageSize,
                                startDateBefore: String? = nil,
                                startDateAfter: String? = nil,
                                searchQuery: String? = nil,
                                order: Order) async throws -> [Booking] {
        var parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.order: order.rawValue
        ]

        if let startDateBefore = startDateBefore {
            parameters[ParameterKey.startDateBefore] = startDateBefore
        }

        if let startDateAfter = startDateAfter {
            parameters[ParameterKey.startDateAfter] = startDateAfter
        }

        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            parameters[ParameterKey.search] = searchQuery
        }

        let path = Path.bookings
        let request = JetpackRequest(wooApiVersion: .wcBookings, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = ListMapper<Booking>(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    public func loadBooking(
        bookingID: Int64,
        siteID: Int64
    ) async throws -> Booking? {
        let path = "\(Path.bookings)/\(bookingID)"
        let request = JetpackRequest(
            wooApiVersion: .wcBookings,
            method: .get,
            siteID: siteID,
            path: path,
            availableAsRESTRequest: true
        )

        let mapper = BookingMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }

    public func updateBooking(
        from siteID: Int64,
        bookingID: Int64,
        attendanceStatus: BookingAttendanceStatus
    ) async throws -> Booking? {
        let path = "\(Path.bookings)/\(bookingID)"
        let parameters = [
            ParameterKey.attendanceStatus: attendanceStatus.rawValue
        ]
        let request = JetpackRequest(
            wooApiVersion: .wcBookings,
            method: .put,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )

        let mapper = BookingMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    public func fetchResource(
        resourceID: Int64,
        siteID: Int64
    ) async throws -> BookingResource? {
        let path = "\(Path.resources)/\(resourceID)"
        let request = JetpackRequest(
            wooApiVersion: .wcBookings,
            method: .get,
            siteID: siteID,
            path: path,
            availableAsRESTRequest: true
        )

        let mapper = BookingResourceMapper(siteID: siteID)

        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants
//
public extension BookingsRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = Remote.Default.firstPageNumber
    }

    enum Order: String {
        case ascending = "asc"
        case descending = "desc"
    }

    private enum Path {
        static let bookings = "bookings"
        static let resources = "resources/team-members"
    }

    private enum ParameterKey {
        static let page: String            = "page"
        static let perPage: String         = "per_page"
        static let startDateBefore: String = "start_date_before"
        static let startDateAfter: String  = "start_date_after"
        static let search: String          = "search"
        static let order: String           = "order"
        static let attendanceStatus        = "attendance_status"
    }
}
