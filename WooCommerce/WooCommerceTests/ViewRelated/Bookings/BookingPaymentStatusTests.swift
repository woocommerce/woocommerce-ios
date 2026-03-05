import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@Suite("BookingPaymentStatus resolver")
struct BookingPaymentStatusTests {

    @Test("Order status refunded resolves to refunded")
    func test_refunded_order_status_resolves_to_refunded() {
        let status = BookingPaymentStatus(orderStatusKey: "refunded", datePaid: nil)
        #expect(status == .refunded)
    }

    @Test("datePaid set resolves to paid")
    func test_datePaid_set_resolves_to_paid() {
        let status = BookingPaymentStatus(orderStatusKey: "processing", datePaid: Date())
        #expect(status == .paid)
    }

    @Test("Failed order status resolves to failed")
    func test_failed_order_status_resolves_to_failed() {
        let status = BookingPaymentStatus(orderStatusKey: "failed", datePaid: nil)
        #expect(status == .failed)
    }

    @Test("Cancelled order status resolves to failed")
    func test_cancelled_order_status_resolves_to_failed() {
        let status = BookingPaymentStatus(orderStatusKey: "cancelled", datePaid: nil)
        #expect(status == .failed)
    }

    @Test("Pending order with no datePaid resolves to unpaid")
    func test_pending_order_with_no_datePaid_resolves_to_unpaid() {
        let status = BookingPaymentStatus(orderStatusKey: "pending", datePaid: nil)
        #expect(status == .unpaid)
    }

    @Test("refundTotal exceeding total resolves to refunded")
    func test_refundTotal_exceeding_total_resolves_to_refunded() {
        let status = BookingPaymentStatus(orderStatusKey: "processing",
                                          datePaid: Date(),
                                          refundTotal: 50,
                                          total: 50)
        #expect(status == .refunded)
    }

    @Test("Partial refund resolves to partiallyRefunded")
    func test_partial_refund_resolves_to_partiallyRefunded() {
        let status = BookingPaymentStatus(orderStatusKey: "processing",
                                          datePaid: Date(),
                                          refundTotal: 10,
                                          total: 50)
        #expect(status == .partiallyRefunded)
    }

    @Test("BookingPaymentStatus conforms to BookingBadgeable")
    func test_bookingBadgeable_conformance() {
        let status: BookingBadgeable = BookingPaymentStatus.paid
        #expect(status.text == "Paid")
        #expect(BookingPaymentStatus.unpaid.text == "Unpaid")
        #expect(BookingPaymentStatus.failed.text == "Failed")
        #expect(BookingPaymentStatus.refunded.text == "Refunded")
        #expect(BookingPaymentStatus.partiallyRefunded.text == "Partially Refunded")
    }
}
