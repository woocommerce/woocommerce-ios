import Foundation
import Testing
import Hardware
import Fakes
@testable import WooCommerce

/// Tests for the receipt-related `WooAnalyticsEvent.InPersonPayments` factory methods, focusing on the
/// `currency` and `payment_method_type` properties added for Android parity (WOOMOB-3538).
///
struct WooAnalyticsEvent_ReceiptTests {

    // MARK: - payment_method_type

    @Test func test_receiptPrintTapped_when_cardPresent_paymentMethod_then_payment_method_type_is_card() {
        // Given
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())

        // When
        let event = WooAnalyticsEvent.InPersonPayments.receiptPrintTapped(countryCode: .US,
                                                                          cardReaderModel: "WISEPAD_3",
                                                                          source: .local,
                                                                          currency: "USD",
                                                                          paymentMethod: paymentMethod)

        // Then
        #expect(event.statName == .receiptPrintTapped)
        #expect(event.properties["payment_method_type"] as? String == "card")
        #expect(event.properties["currency"] as? String == "USD")
    }

    @Test func test_receiptPrintTapped_when_interacPresent_paymentMethod_then_payment_method_type_is_card_interac() {
        // Given
        let paymentMethod = PaymentMethod.interacPresent(details: .fake())

        // When
        let event = WooAnalyticsEvent.InPersonPayments.receiptPrintTapped(countryCode: .CA,
                                                                          cardReaderModel: "WISEPAD_3",
                                                                          source: .local,
                                                                          currency: "CAD",
                                                                          paymentMethod: paymentMethod)

        // Then
        #expect(event.properties["payment_method_type"] as? String == "card_interac")
    }

    @Test func test_receiptPrintTapped_when_backend_receipt_after_card_payment_then_includes_payment_method_type() {
        // Given a backend receipt shown right after collecting a card payment, the payment method is known.
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())

        // When
        let event = WooAnalyticsEvent.InPersonPayments.receiptPrintTapped(countryCode: nil,
                                                                          cardReaderModel: nil,
                                                                          source: .backend,
                                                                          currency: "USD",
                                                                          paymentMethod: paymentMethod)

        // Then
        #expect(event.properties["source"] as? String == "backend")
        #expect(event.properties["currency"] as? String == "USD")
        #expect(event.properties["payment_method_type"] as? String == "card")
    }

    // MARK: - currency

    @Test func test_receiptViewTapped_when_backend_without_paymentMethod_then_includes_currency_and_omits_payment_method_type() {
        // Given, When
        let event = WooAnalyticsEvent.InPersonPayments.receiptViewTapped(countryCode: .GB,
                                                                         source: .backend,
                                                                         currency: "GBP")

        // Then
        #expect(event.statName == .receiptViewTapped)
        #expect(event.properties["currency"] as? String == "GBP")
        #expect(event.properties["source"] as? String == "backend")
        #expect(event.properties["payment_method_type"] == nil)
    }

    @Test func test_receiptEmailTapped_when_currency_and_paymentMethod_then_includes_both() {
        // Given, When
        let event = WooAnalyticsEvent.InPersonPayments.receiptEmailTapped(countryCode: .US,
                                                                         cardReaderModel: "WISEPAD_3",
                                                                         source: .local,
                                                                         currency: "USD",
                                                                         paymentMethod: .card)

        // Then
        #expect(event.statName == .receiptEmailTapped)
        #expect(event.properties["currency"] as? String == "USD")
        #expect(event.properties["payment_method_type"] as? String == "card")
    }

    @Test func test_receiptFetchFailed_when_currency_then_includes_currency() {
        // Given, When
        let event = WooAnalyticsEvent.InPersonPayments.receiptFetchFailed(error: NSError(domain: "test", code: 1),
                                                                         currency: "EUR")

        // Then
        #expect(event.statName == .receiptFetchFailed)
        #expect(event.properties["currency"] as? String == "EUR")
    }

    // MARK: - Omission when unavailable

    @Test func test_receiptPrintSuccess_when_no_currency_and_no_paymentMethod_then_omits_both_keys() {
        // Given, When
        let event = WooAnalyticsEvent.InPersonPayments.receiptPrintSuccess(countryCode: nil,
                                                                          cardReaderModel: nil,
                                                                          source: .backend)

        // Then
        #expect(event.properties["currency"] == nil)
        #expect(event.properties["payment_method_type"] == nil)
    }
}
