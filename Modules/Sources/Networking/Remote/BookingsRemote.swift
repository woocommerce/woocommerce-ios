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
                         filters: BookingFilters?,
                         searchQuery: String?,
                         order: BookingsRemote.Order) async throws -> [Booking]

    func loadBooking(bookingID: Int64,
                     siteID: Int64) async throws -> Booking?

    func updateBooking(
        from siteID: Int64,
        bookingID: Int64,
        attendanceStatus: BookingAttendanceStatus?,
        bookingStatus: BookingStatus?,
        paymentStatus: BookingPaymentStatus?,
        note: String?
    ) async throws -> Booking?

    func fetchResource(resourceID: Int64,
                       siteID: Int64) async throws -> BookingResource?

    func fetchResources(for siteID: Int64,
                        pageNumber: Int,
                        pageSize: Int) async throws -> [BookingResource]
}

/// Filters for booking queries
public struct BookingFilters {
    public let productIDs: [Int64]
    public let customerIDs: [Int64]
    public let resourceIDs: [Int64]
    public let startDateBefore: String?
    public let startDateAfter: String?
    public let attendanceStatuses: [String]
    public let paymentStatuses: [String]

    public init(
        productIDs: [Int64] = [],
        customerIDs: [Int64] = [],
        resourceIDs: [Int64] = [],
        startDateBefore: String? = nil,
        startDateAfter: String? = nil,
        attendanceStatuses: [String] = [],
        paymentStatuses: [String] = []
    ) {
        self.productIDs = productIDs
        self.customerIDs = customerIDs
        self.resourceIDs = resourceIDs
        self.startDateBefore = startDateBefore
        self.startDateAfter = startDateAfter
        self.attendanceStatuses = attendanceStatuses
        self.paymentStatuses = paymentStatuses
    }
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
    ///     - filters: Optional filters for bookings (products, customers, resources, dates, statuses).
    ///     - searchQuery: Search query to filter bookings.
    ///     - order: Sort order for bookings (ascending or descending).
    ///
    public func loadAllBookings(for siteID: Int64,
                                pageNumber: Int = Default.pageNumber,
                                pageSize: Int = Default.pageSize,
                                filters: BookingFilters? = nil,
                                searchQuery: String? = nil,
                                order: Order) async throws -> [Booking] {
        var parameters: [String: Any] = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.order: order.rawValue
        ]

        // Apply filters if provided
        if let filters {
            if filters.productIDs.isNotEmpty {
                parameters[ParameterKey.product] = filters.productIDs.map(String.init)
            }

            if filters.customerIDs.isNotEmpty {
                parameters[ParameterKey.customer] = filters.customerIDs.map(String.init)
            }

            if filters.resourceIDs.isNotEmpty {
                parameters[ParameterKey.resource] = filters.resourceIDs.map(String.init)
            }

            /// `start_date_before` filter doesn't include the date in the result,
            /// so move the time forward one second as a workaround.
            if let startDateBefore = filters.startDateBefore,
                let adjustedDate = Date.dateWithISO8601String(startDateBefore)?.addingTimeInterval(1) {
                parameters[ParameterKey.startDateBefore] = adjustedDate.ISO8601Format()
            }

            /// `start_date_after` filter doesn't include the date in the result,
            /// so move the time backward one second as a workaround.
            if let startDateAfter = filters.startDateAfter,
               let adjustedDate = Date.dateWithISO8601String(startDateAfter)?.addingTimeInterval(-1) {
                parameters[ParameterKey.startDateAfter] = adjustedDate.ISO8601Format()
            }

            if filters.attendanceStatuses.isNotEmpty {
                parameters[ParameterKey.attendanceStatus] = filters.attendanceStatuses
            }

            if filters.paymentStatuses.isNotEmpty {
                parameters[ParameterKey.paymentStatus] = filters.paymentStatuses
            }
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
        attendanceStatus: BookingAttendanceStatus?,
        bookingStatus: BookingStatus?,
        paymentStatus: BookingPaymentStatus? = nil,
        note: String?
    ) async throws -> Booking? {
        let path = "\(Path.bookings)/\(bookingID)"
        var parameters: [String: String] = [:]

        if let attendanceStatus {
            parameters[ParameterKey.attendanceStatus] = attendanceStatus.rawValue
        }

        if let bookingStatus {
            parameters[ParameterKey.status] = bookingStatus.rawValue
        } else if let paymentStatus {
            parameters[ParameterKey.status] = paymentStatus.rawValue
        }

        if let note {
            parameters[ParameterKey.note] = note
        }

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

    /// Retrieves all of the `BookingResources` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote booking resources.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of resources to be retrieved per page.
    ///
    public func fetchResources(
        for siteID: Int64,
        pageNumber: Int = Default.pageNumber,
        pageSize: Int = Default.pageSize
    ) async throws -> [BookingResource] {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize)
        ]

        let path = Path.resources
        let request = JetpackRequest(
            wooApiVersion: .wcBookings,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )
        let mapper = ListMapper<BookingResource>(siteID: siteID)

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
        static let product: String         = "product"
        static let customer: String        = "customer"
        static let resource: String        = "resource"
        static let attendanceStatus        = "attendance_status"
        static let paymentStatus           = "booking_status" // to be updated later when payment filtering is supported
        static let status: String          = "status"
        static let note: String            = "note"
    }
}
