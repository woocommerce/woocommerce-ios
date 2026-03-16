import Foundation
import Networking

// periphery: ignore
/// BookingAction: Defines all of the Actions supported by the BookingStore.
///
public enum BookingAction: Action {

    /// Synchronizes the Bookings matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more bookings to sync.
    ///
    case synchronizeBookings(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int = BookingsRemote.Default.pageSize,
                             filters: BookingFilters? = nil,
                             order: BookingsRemote.Order = .descending,
                             shouldClearCache: Bool = false,
                             onCompletion: (Result<Bool, Error>) -> Void)
    /// Synchronizes the Booking matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error in case of a failure or empty in case of success.
    ///
    case synchronizeBooking(siteID: Int64,
                            bookingID: Int64,
                            onCompletion: (Result<Void, Error>) -> Void)

    /// Checks if the store already has any bookings.
    /// Returns `false` if the store has no bookings.
    ///
    case checkIfStoreHasBookings(siteID: Int64,
                                 onCompletion: (Result<Bool, Error>) -> Void)

    /// Searches for bookings matching the specified criteria and search query.
    ///
    /// - Parameter onCompletion: called when search completes, returns an error or an array of bookings.
    ///
    case searchBookings(siteID: Int64,
                        searchQuery: String,
                        pageNumber: Int,
                        pageSize: Int = BookingsRemote.Default.pageSize,
                        filters: BookingFilters? = nil,
                        order: BookingsRemote.Order = .descending,
                        onCompletion: (Result<[Booking], Error>) -> Void)

    /// Fetches a booking resource by resource ID.
    ///
    /// - Parameter onCompletion: called when fetch completes, returns an error or the booking resource.
    ///
    case fetchResource(siteID: Int64,
                       resourceID: Int64,
                       onCompletion: (Result<BookingResource, Error>) -> Void)

    /// Synchronizes booking resources matching the specified criteria.
    ///
    /// - Parameter onCompletion: called when sync completes, returns an error or a boolean that indicates whether there might be more resources to sync.
    ///
    case synchronizeResources(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int = BookingsRemote.Default.pageSize,
                             onCompletion: (Result<Bool, Error>) -> Void)

    /// Updates a booking attendance status.
    ///
    /// - Parameter siteID: The site ID of the booking.
    /// - Parameter bookingID: The ID of the booking to be updated.
    /// - Parameter status: The new attendance status.
    /// - Parameter onCompletion: called when update completes, returns an error in case of a failure.
    ///
    case updateBookingAttendanceStatus(siteID: Int64,
                                       bookingID: Int64,
                                       status: BookingAttendanceStatus,
                                       onCompletion: (Error?) -> Void)

    /// Cancels a booking by updating its status to cancelled.
    ///
    /// - Parameter siteID: The site ID of the booking.
    /// - Parameter bookingID: The ID of the booking to be cancelled.
    /// - Parameter onCompletion: called when cancellation completes, returns an error in case of a failure.
    ///
    case cancelBooking(siteID: Int64,
                       bookingID: Int64,
                       onCompletion: (Error?) -> Void)

    /// Marks a booking as paid by updating its status to paid.
    ///
    /// - Parameter siteID: The site ID of the booking.
    /// - Parameter bookingID: The ID of the booking to be marked as paid.
    /// - Parameter onCompletion: called when the operation completes, returns an error in case of a failure.
    ///
    case markBookingAsPaid(siteID: Int64,
                           bookingID: Int64,
                           onCompletion: (Error?) -> Void)

    /// Updates a booking note.
    ///
    /// - Parameter siteID: The site ID of the booking.
    /// - Parameter bookingID: The ID of the booking to be updated.
    /// - Parameter note: The new note.
    /// - Parameter onCompletion: called when update completes, returns an error in case of a failure.
    ///
    case updateBookingNote(siteID: Int64,
                           bookingID: Int64,
                           note: String,
                           onCompletion: (Error?) -> Void)


    /// Fetches the booking location from the product endpoint and persists it on the booking.
    ///
    /// - Parameter siteID: The site ID.
    /// - Parameter bookingID: The ID of the booking to update with the location.
    /// - Parameter productID: The product ID to fetch the booking location from.
    /// - Parameter onCompletion: called when fetch completes, returns the location string or an error.
    ///
    case fetchProductBookingLocation(siteID: Int64,
                                     bookingID: Int64,
                                     productID: Int64,
                                     onCompletion: (Result<String?, Error>) -> Void)

    /// Clears the booking cache.
    ///
    /// - Parameter siteID: The site ID of the booking.
    /// - Parameter onCompletion: Called when clear completes.
    case clearBookingsCache(siteID: Int64,
                            onCompletion: () -> Void)
}
