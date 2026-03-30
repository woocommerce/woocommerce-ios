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

    // MARK: - paymentStatusBadge

    func test_paymentStatusBadge_when_orderInfo_has_paid_metadata_then_returns_paid() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "processing",
                                         datePaid: Date(),
                                         paymentStatusMetadata: "paid",
                                         paymentInfo: nil,
                                         customerInfo: nil,
                                         productInfo: nil)
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When / Then
        XCTAssertEqual(booking.paymentStatusBadge, .paid)
    }

    func test_paymentStatusBadge_when_no_orderInfo_then_returns_unpaid() {
        // Given
        let booking = Booking.fake().copy(orderInfo: nil)

        // When / Then
        XCTAssertEqual(booking.paymentStatusBadge, .unpaid)
    }

    func test_paymentStatusBadge_when_orderInfo_has_no_metadata_then_returns_unpaid() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "processing",
                                         datePaid: nil,
                                         paymentInfo: nil,
                                         customerInfo: nil,
                                         productInfo: nil)
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When / Then
        XCTAssertEqual(booking.paymentStatusBadge, .unpaid)
    }

}
