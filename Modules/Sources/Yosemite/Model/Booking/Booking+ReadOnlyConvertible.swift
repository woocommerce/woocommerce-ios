import Foundation
import Storage

// MARK: - Storage.Booking: ReadOnlyConvertible
//
extension Storage.Booking: ReadOnlyConvertible {

    /// Updates the Storage.Booking with the a ReadOnly.
    ///
    public func update(with booking: Yosemite.Booking) {
        siteID = booking.siteID
        bookingID = booking.bookingID
        allDay = booking.allDay
        cost = booking.cost
        customerID = booking.customerID

        /// Falling to back to existing values in case if new values are absent
        /// Booking returned when sending a `PUT` request to `bookings/{booking_id}`
        /// doesn't contain `date_created` and `date_modified` values.
        dateCreated = booking.dateCreated ?? dateCreated
        dateModified = booking.dateModified ?? dateModified

        endDate = booking.endDate
        googleCalendarEventID = booking.googleCalendarEventID
        orderID = booking.orderID
        orderItemID = booking.orderItemID
        parentID = booking.parentID
        productID = booking.productID
        resourceID = booking.resourceID
        startDate = booking.startDate
        statusKey = booking.statusKey
        attendanceStatusKey = booking.attendanceStatusKey
        localTimezone = booking.localTimezone
        currency = booking.currency
        note = booking.note
        location = booking.location
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Booking {
        Booking(siteID: siteID,
                bookingID: bookingID,
                allDay: allDay,
                cost: cost ?? "",
                customerID: customerID,
                dateCreated: dateCreated ?? Date(),
                dateModified: dateModified ?? Date(),
                endDate: endDate ?? Date(),
                googleCalendarEventID: googleCalendarEventID,
                orderID: orderID,
                orderItemID: orderItemID,
                parentID: parentID,
                productID: productID,
                resourceID: resourceID,
                startDate: startDate ?? Date(),
                statusKey: statusKey ?? "",
                attendanceStatusKey: attendanceStatusKey ?? "",
                localTimezone: localTimezone ?? "",
                currency: currency ?? "USD",
                orderInfo: orderInfo?.toReadOnly(),
                note: note ?? "",
                location: location)
    }
}

extension Yosemite.Booking: ReadOnlyType {
    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageBooking = storageEntity as? Storage.Booking else {
            return false
        }

        return siteID == Int(storageBooking.siteID) && bookingID == Int(storageBooking.bookingID)
    }
}
