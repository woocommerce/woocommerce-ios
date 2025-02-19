@testable import WooCommerce
import protocol WooFoundation.Analytics
import Testing

struct POSCollectOrderPaymentAnalyticsTests {
    private let analytics: Analytics
    private let analyticsProvider: MockAnalyticsProvider

    init() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    @Test func POSCollectOrderPaymentAnalyticsTests_when_successful_payment_then_tracks_event_and_properties() {
        // Given
        let sut = POSCollectOrderPaymentAnalytics(analytics: analytics)
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)
        let expectedEvent = "card_present_collect_payment_success"
        let expectedProperties = [
            "milliseconds_since_order_creation_success",
            "milliseconds_since_reader_ready_to_collect_payment",
            "milliseconds_since_card_tapped",
            "milliseconds_since_customer_interaction_started",
            "checkout_tap_count"
        ]

        // When
        sut.trackSuccessfulPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(analyticsProvider.receivedEvents.first(where: { $0 == expectedEvent }) != nil)
        #expect(expectedProperties.allSatisfy { key in
            analyticsProvider.receivedProperties.contains(where: { $0.keys.contains(key) })
        })
    }
}
