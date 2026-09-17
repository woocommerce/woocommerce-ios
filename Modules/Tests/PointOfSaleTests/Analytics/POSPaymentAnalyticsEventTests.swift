import Testing
import Fakes
import Yosemite
import WooFoundation
@testable import PointOfSale

struct POSPaymentAnalyticsEventTests {
    @Test(arguments: [("USD", "19.99", 1999), ("JPY", "1234", 1234), ("KWD", "12.345", 12345)])
    func test_success_events_when_order_currency_varies_then_report_gross_minor_units(currency: String, total: String, amount: Int) {
        // Given
        let order = Order.fake().copy(orderID: 42, currency: currency, total: total, paymentMethodID: "stripe")

        // When
        let events = [
            WooAnalyticsEvent.PointOfSale.cardPresentCollectPaymentSuccess(
                forGatewayID: "woocommerce_payments", countryCode: .US,
                paymentMethod: .cardPresent(details: .fake()), cardReaderModel: "TAP_TO_PAY_DEVICE",
                order: order, transport: "built_in",
                millisecondsSinceCustomerIteractionStarted: 0, millisecondsSinceOrderSyncSuccess: 0,
                millisecondsSinceReaderReadyToCollect: 0, millisecondsSinceCardTapped: 0, checkoutTapCount: 1),
            WooAnalyticsEvent.PointOfSale.cashCollectPaymentSuccess(order: order, countryCode: .US,
                                                                   millisecondsSinceCustomerIteractionStarted: 0),
            WooAnalyticsEvent.PointOfSale.scanToPayCollectPaymentSuccess(order: order, countryCode: .US,
                                                                        millisecondsSinceCustomerIteractionStarted: 0)
        ]

        // Then
        for event in events {
            #expect(event.properties["amount_normalized"] as? Int == amount)
            #expect(event.properties["currency"] as? String == currency)
            #expect(event.properties["order_id"] as? Int64 == 42)
            #expect(event.properties["country"] as? String == "US")
        }
        #expect(events[0].properties["plugin_slug"] as? String == "woocommerce_payments")
        #expect(events[0].properties["payment_method_type"] as? String == "card")
        #expect(events[0].properties["transport"] as? String == "built_in")
        #expect(events[0].properties["card_reader_model"] as? String == "TAP_TO_PAY_DEVICE")
        #expect(events[1].properties["payment_method_type"] as? String == "cash")
        #expect(events[1].properties["plugin_slug"] == nil)
        #expect(events[2].properties["payment_method_type"] as? String == "scan_to_pay")
        #expect(events[2].properties["plugin_slug"] as? String == "stripe")
    }

    @Test func test_interac_card_success_then_reports_value_on_canonical_event() {
        // Given
        let order = Order.fake().copy(orderID: 42, currency: "CAD", total: "19.99")

        // When
        let event = WooAnalyticsEvent.PointOfSale.cardPresentCollectPaymentSuccess(
            forGatewayID: "stripe", countryCode: .CA, paymentMethod: .interacPresent(details: .fake()), cardReaderModel: "WISEPAD_3",
            order: order, transport: "bluetooth", millisecondsSinceCustomerIteractionStarted: 0, millisecondsSinceOrderSyncSuccess: 0,
            millisecondsSinceReaderReadyToCollect: 0, millisecondsSinceCardTapped: 0, checkoutTapCount: 1)

        // Then
        #expect(event.statName == .collectPaymentSuccess)
        #expect(event.properties["amount_normalized"] as? Int == 1999)
        #expect(event.properties["payment_method_type"] as? String == "card_interac")
    }

    @Test(arguments: [("USD", "invalid"), ("unsupported", "19.99")])
    func test_success_when_amount_or_currency_is_invalid_then_does_not_fabricate_value(currency: String, total: String) {
        // Given
        let order = Order.fake().copy(currency: currency, total: total)

        // When
        let event = WooAnalyticsEvent.PointOfSale.cashCollectPaymentSuccess(
            order: order, countryCode: .US, millisecondsSinceCustomerIteractionStarted: 0)

        // Then
        #expect(event.properties["amount_normalized"] == nil)
        #expect(event.properties["currency"] as? String == currency)
    }

    @Test func test_scan_to_pay_when_gateway_is_unknown_then_does_not_attribute_to_card_gateway() {
        // Given
        let order = Order.fake().copy(currency: "USD", total: "10.00", paymentMethodID: "")

        // When
        let event = WooAnalyticsEvent.PointOfSale.scanToPayCollectPaymentSuccess(
            order: order, countryCode: .US, millisecondsSinceCustomerIteractionStarted: 0)

        // Then
        #expect(event.properties["plugin_slug"] as? String == "unknown")
    }

    @Test func test_mark_as_paid_success_then_reports_value_with_unknown_gateway() {
        // Given
        let order = Order.fake().copy(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: "stripe")

        // When
        let event = WooAnalyticsEvent.PointOfSale.markAsPaidSuccess(
            order: order, countryCode: .US, millisecondsSinceCustomerIteractionStarted: 0)

        // Then
        #expect(event.properties["amount_normalized"] as? Int == 1999)
        #expect(event.properties["currency"] as? String == "USD")
        #expect(event.properties["order_id"] as? Int64 == 42)
        #expect(event.properties["country"] as? String == "US")
        #expect(event.properties["payment_method_type"] as? String == "mark_as_paid")
        #expect(event.properties["plugin_slug"] as? String == "unknown")
    }

    @Test func test_noncanonical_success_events_then_do_not_report_payment_value() {
        // When
        let event = WooAnalyticsEvent.PointOfSale.interacCollectPaymentSuccess(forGatewayID: "stripe", countryCode: .CA, cardReaderModel: "WISEPAD_3")

        // Then
        #expect(event.properties["amount_normalized"] == nil)
        #expect(event.properties["currency"] == nil)
    }
}
