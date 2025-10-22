import Foundation
import Networking

extension BookingDetailsViewModel {
    final class AttendanceContent {
        private(set) var value = ""

        func update(with booking: Booking) {
            value = booking.attendanceStatus.localizedTitle
        }
    }
}
