import Foundation
import Networking

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
                             onCompletion: (Result<Bool, Error>) -> Void)
}
