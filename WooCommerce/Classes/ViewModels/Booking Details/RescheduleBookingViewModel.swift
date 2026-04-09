import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics

/// Input data for the booking reschedule flow.
struct BookingRescheduleInput {
    /// The booking to reschedule.
    let booking: Booking

    /// Duration of the booking in seconds, calculated from the product or from booking dates.
    let durationInSeconds: TimeInterval

    /// Resource IDs associated with the booking product.
    let resourceIDs: [Int64]
}

@Observable
final class RescheduleBookingViewModel {
    private let booking: Booking
    private let stores: StoresManager
    private let analytics: Analytics

    /// Duration of the booking in seconds.
    let durationInSeconds: TimeInterval

    /// Resource IDs associated with the booking product.
    let resourceIDs: [Int64]

    init(input: BookingRescheduleInput,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.booking = input.booking
        self.durationInSeconds = input.durationInSeconds
        self.resourceIDs = input.resourceIDs
        self.stores = stores
        self.analytics = analytics
        DDLogDebug("Duration: \(durationInSeconds), resourceIDs: \(resourceIDs)")
    }
}
