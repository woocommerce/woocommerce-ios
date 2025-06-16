import Foundation
import Testing
@testable import WooCommerce
import Yosemite

struct ShippingLabelHelpersTests {

    @Test func refundDuration_is_correct_for_dhl() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: WooShippingCarrier.dhlExpress.rawValue)

        // Then
        #expect(shippingLabel.refundDuration == 31)
    }

    @Test(arguments: [
        WooShippingCarrier.upsdap,
        WooShippingCarrier.usps,
        WooShippingCarrier.dhlEcommerce,
        WooShippingCarrier.dhlEcommerceAsia
    ])
    func refundDuration_is_correct_for_non_dhl(carrier: WooShippingCarrier) {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: carrier.rawValue)

        // Then
        #expect(shippingLabel.refundDuration == 14)
    }

    @Test func hasExpired_is_true_for_label_with_status_anonymized() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(status: .anonymized)

        // Then
        #expect(shippingLabel.hasExpired)
    }

    @Test func hasExpired_is_true_for_label_with_usedDate() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(usedDate: Date())

        // Then
        #expect(shippingLabel.hasExpired)
    }

    @Test func hasExpired_is_true_for_label_with_passed_expiryDate() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(expiryDate: Date(timeIntervalSinceNow: -1))

        // Then
        #expect(shippingLabel.hasExpired)
    }

    @Test func hasExpired_is_false_for_label_with_non_anonymized_status_no_usedDate_and_expiryDate_has_not_passed() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(status: .purchased,
                                                      usedDate: nil,
                                                      expiryDate: Date(timeIntervalSinceNow: 60*60))

        // Then
        #expect(shippingLabel.hasExpired == false)
    }

    @Test(arguments: [
        ShippingLabel.fake().copy(status: .anonymized),
        ShippingLabel.fake().copy(usedDate: Date()),
        ShippingLabel.fake().copy(expiryDate: Date(timeIntervalSinceNow: -1))
    ])
    func isRefundable_is_false_for_expired_labels(label: ShippingLabel) {
        // Then
        #expect(label.isRefundable == false)
    }

    @Test func isRefundable_is_false_for_label_created_more_than_30_days_ago() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(dateCreated: Date(timeIntervalSinceNow: -60*60*24*30 - 1))

        // Then
        #expect(shippingLabel.isRefundable == false)
    }

    @Test func isRefundable_is_false_for_USPS_label_with_no_tracking_number() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: WooShippingCarrier.usps.rawValue,
                                                      trackingNumber: "")

        // Then
        #expect(shippingLabel.isRefundable == false)
    }

    @Test(arguments: [
        ShippingLabel.fake().copy(dateCreated: Date()),
        ShippingLabel.fake().copy(carrierID: WooShippingCarrier.usps.rawValue, trackingNumber: "2890890"),
        ShippingLabel.fake().copy(carrierID: WooShippingCarrier.dhlExpress.rawValue, trackingNumber: "")
    ])
    func isRefundable_is_true_for_other_cases(label: ShippingLabel) {
        // Then
        #expect(label.isRefundable)
    }

    @Test(arguments: [
        ShippingLabel.fake().copy(commercialInvoiceURL: nil),
        ShippingLabel.fake().copy(commercialInvoiceURL: "")
    ])
    func hasCustomsForm_is_false_when_commercialInvoiceURL_is_nil_or_empty(label: ShippingLabel) {
        // Then
        #expect(label.hasCustomsForm == false)
    }

    @Test func hasCustomsForm_is_true_when_commercialInvoiceURL_is_not_empty() {
        // Given
        let label = ShippingLabel.fake().copy(commercialInvoiceURL: "https://example.com/form.pdf")

        // Then
        #expect(label.hasCustomsForm)
    }
}
