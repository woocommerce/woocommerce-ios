import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@Suite("BookingPaymentStatus resolver")
struct BookingPaymentStatusTests {

    // MARK: - Metadata-based resolution

    @Test("_payment_status 'paid' resolves to paid")
    func test_paymentStatusMetadata_paid_resolves_to_paid() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "paid")
        #expect(status == .paid)
    }

    @Test("_payment_status 'unpaid' resolves to unpaid")
    func test_paymentStatusMetadata_unpaid_resolves_to_unpaid() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "unpaid")
        #expect(status == .unpaid)
    }

    @Test("_payment_status 'failed' resolves to failed")
    func test_paymentStatusMetadata_failed_resolves_to_failed() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "failed")
        #expect(status == .failed)
    }

    @Test("_payment_status 'refunded' resolves to refunded")
    func test_paymentStatusMetadata_refunded_resolves_to_refunded() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "refunded")
        #expect(status == .refunded)
    }

    @Test("_payment_status 'partially_refunded' resolves to partiallyRefunded")
    func test_paymentStatusMetadata_partially_refunded_resolves_to_partiallyRefunded() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "partially_refunded")
        #expect(status == .partiallyRefunded)
    }

    @Test("_payment_status 'authorized' resolves to authorized")
    func test_paymentStatusMetadata_authorized_resolves_to_authorized() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "authorized")
        #expect(status == .authorized)
    }

    @Test("_payment_status 'authorization_voided' resolves to authorizationVoided")
    func test_paymentStatusMetadata_authorization_voided_resolves_to_authorizationVoided() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "authorization_voided")
        #expect(status == .authorizationVoided)
    }

    @Test("Unknown _payment_status value defaults to unpaid")
    func test_paymentStatusMetadata_unknown_value_defaults_to_unpaid() {
        let status = BookingPaymentStatus(paymentStatusMetadata: "some_future_value")
        #expect(status == .unpaid)
    }

    @Test("nil _payment_status defaults to unpaid")
    func test_paymentStatusMetadata_nil_defaults_to_unpaid() {
        let status = BookingPaymentStatus(paymentStatusMetadata: nil)
        #expect(status == .unpaid)
    }

    // MARK: - BookingBadgeable conformance

    @Test("BookingPaymentStatus conforms to BookingBadgeable with correct text")
    func test_bookingBadgeable_conformance() {
        #expect(BookingPaymentStatus.paid.text == "Paid")
        #expect(BookingPaymentStatus.unpaid.text == "Unpaid")
        #expect(BookingPaymentStatus.failed.text == "Failed")
        #expect(BookingPaymentStatus.refunded.text == "Refunded")
        #expect(BookingPaymentStatus.partiallyRefunded.text == "Partially Refunded")
        #expect(BookingPaymentStatus.authorized.text == "Authorized")
        #expect(BookingPaymentStatus.authorizationVoided.text == "Authorization Voided")
    }
}
