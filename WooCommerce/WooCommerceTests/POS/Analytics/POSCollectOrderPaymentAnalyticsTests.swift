@testable import WooCommerce
import protocol WooFoundation.Analytics
import struct Yosemite.CardPresentPaymentsConfiguration
import enum WooFoundation.CountryCode
import Testing

struct POSCollectOrderPaymentAnalyticsTests {
    private let analytics: MockPOSAnalytics

    init() {
        analytics = MockPOSAnalytics()
    }

    @Test func analytics_when_successful_payment_then_tracks_event_and_properties() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, configuration: configuration)
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)
        let expectedEvent = "card_present_collect_payment_success"
        let expectedProperties = [
            "milliseconds_since_order_sync_success",
            "milliseconds_since_reader_ready_to_collect_payment",
            "milliseconds_since_card_tapped",
            "milliseconds_since_customer_interaction_started",
            "checkout_tap_count",
            "card_reader_model",
            "country",
            "payment_method_type",
            "plugin_slug"
        ]

        // When
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(analytics.events.contains(where: { $0.eventName == expectedEvent }))
        #expect(expectedProperties.allSatisfy { key in
            analytics.events.map(\.properties).contains(where: { $0.keys.contains(key) })
        })
    }
}
