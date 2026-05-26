import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics

/// Represents a booking's duration as a value and calendar unit.
/// Uses `Calendar` to compute end dates, correctly handling DST and varying month lengths.
struct BookingDuration {
    let value: Int
    let unit: Booking.DurationUnit

    /// Computes the end date by adding this duration to the given start date using `Calendar`.
    func endDate(from startDate: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: unit.calendarComponent, value: value, to: startDate)
    }
}

/// Input data for the booking reschedule flow.
struct BookingRescheduleInput {
    /// The booking to reschedule.
    let booking: Booking

    /// Duration of the booking, as a structured value and unit.
    let duration: BookingDuration

    /// Resource IDs associated with the booking product.
    let resourceIDs: [Int64]
}

@Observable
final class RescheduleBookingViewModel {
    private let booking: Booking
    private let stores: StoresManager
    private let analytics: Analytics

    /// Duration of the booking, as a structured value and unit.
    let duration: BookingDuration

    /// Resource IDs associated with the booking product.
    let resourceIDs: [Int64]

    init(input: BookingRescheduleInput,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.booking = input.booking
        self.duration = input.duration
        self.resourceIDs = input.resourceIDs
        self.stores = stores
        self.analytics = analytics
        DDLogDebug("Duration: \(duration.value) \(duration.unit.rawValue)(s), resourceIDs: \(resourceIDs)")
    }
}
