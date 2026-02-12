import Foundation
import struct Yosemite.Booking

extension Booking {
    var bookingItemHeaderStatusBadge: BookingBadgeable {
        if bookingStatus == .cancelled {
            return bookingStatus
        }
        return attendanceStatus
    }
}
