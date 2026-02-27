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

    func test_paymentStatusBadge_when_orderInfo_has_datePaid_then_returns_paid() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "processing",
                                         datePaid: Date(),
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

    // MARK: - isEligibleForMarkAsPaid

    func test_isEligibleForMarkAsPaid_when_payment_status_is_unpaid_then_returns_true() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "pending",
                                         datePaid: nil,
                                         paymentInfo: nil,
                                         customerInfo: nil,
                                         productInfo: nil)
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When / Then
        XCTAssertTrue(booking.isEligibleForMarkAsPaid)
    }

    func test_isEligibleForMarkAsPaid_when_payment_status_is_paid_then_returns_false() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "processing",
                                         datePaid: Date(),
                                         paymentInfo: nil,
                                         customerInfo: nil,
                                         productInfo: nil)
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When / Then
        XCTAssertFalse(booking.isEligibleForMarkAsPaid)
    }

    func test_isEligibleForMarkAsPaid_when_payment_status_is_refunded_then_returns_false() {
        // Given
        let orderInfo = BookingOrderInfo(statusKey: "refunded",
                                         datePaid: nil,
                                         paymentInfo: nil,
                                         customerInfo: nil,
                                         productInfo: nil)
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When / Then
        XCTAssertFalse(booking.isEligibleForMarkAsPaid)
    }
}
