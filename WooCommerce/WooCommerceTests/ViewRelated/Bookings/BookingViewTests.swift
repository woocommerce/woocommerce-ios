import XCTest
import Yosemite
@testable import WooCommerce

final class BookingViewTests: XCTestCase {
    func test_bookingItemHeaderStatusBadge_returnsBookingStatusWhenCancelled() {
        let booking = Booking.fake().copy(
            statusKey: "cancelled",
            attendanceStatusKey: "booked"
        )

        let badge = booking.bookingItemHeaderStatusBadge

        XCTAssertEqual(badge as? BookingStatus, .cancelled)
    }

    func test_bookingItemHeaderStatusBadge_returnsAttendanceStatusWhenNotCancelled() {
        let booking = Booking.fake().copy(
            statusKey: "paid",
            attendanceStatusKey: "unattended"
        )

        let badge = booking.bookingItemHeaderStatusBadge

        XCTAssertEqual(badge as? BookingAttendanceStatus, .unattended)
    }
}
