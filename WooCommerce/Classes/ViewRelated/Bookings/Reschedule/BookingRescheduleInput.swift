import Foundation
import Yosemite

/// Input data for the booking reschedule flow.
struct BookingRescheduleInput {
    /// The booking to reschedule.
    let booking: Booking

    /// Duration of the booking in seconds, calculated from the product or from booking dates.
    let durationInSeconds: TimeInterval

    /// Resource IDs associated with the booking product.
    let resourceIDs: [Int64]
}
