import Foundation
import struct Yosemite.Booking
import enum Yosemite.BookingPaymentStatus

extension Booking {
    var bookingItemHeaderStatusBadge: BookingBadgeable {
        if bookingStatus == .cancelled {
            return bookingStatus
        }
        return attendanceStatus
    }

    var paymentStatusBadge: BookingPaymentStatus {
        BookingPaymentStatus(orderStatusKey: orderInfo?.statusKey ?? "",
                             datePaid: orderInfo?.datePaid)
    }
}
