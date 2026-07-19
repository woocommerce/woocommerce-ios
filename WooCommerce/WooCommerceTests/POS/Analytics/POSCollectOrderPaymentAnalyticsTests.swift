@testable import WooCommerce
import protocol WooFoundation.Analytics
import struct Yosemite.CardPresentPaymentsConfiguration
import enum WooFoundation.CountryCode
import Foundation
import Testing

struct POSCollectOrderPaymentAnalyticsTests {
    private let analytics: MockPOSAnalytics

    private final class TestClock {
        var now: TimeInterval = 0
    }

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

    @Test func analytics_when_successful_card_payment_has_unset_timing_markers_then_reports_zero_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)

        // When
        clock.now = 1000
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_order_sync_success", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_reader_ready_to_collect_payment", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "0.0")
    }

    @Test func analytics_when_successful_card_payment_then_reports_correct_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)

        // When
        clock.now = 1000 // customer interaction started
        sut.trackCustomerInteractionStarted()
        clock.now = 1001 // order synced
        sut.trackOrderSyncSuccess()
        clock.now = 1002 // reader ready
        sut.trackCardReaderReady()
        clock.now = 1003 // card tapped
        sut.trackCardReaderTapped()
        clock.now = 1005 // payment success
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "card_present_collect_payment_success") == "5000.0")
        #expect(property("milliseconds_since_order_sync_success", in: "card_present_collect_payment_success") == "4000.0")
        #expect(property("milliseconds_since_reader_ready_to_collect_payment", in: "card_present_collect_payment_success") == "3000.0")
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "2000.0")
    }

    @Test func test_track_card_reader_tapped_when_processing_event_repeats_then_preserves_first_card_tapped_timestamp() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)

        // When
        clock.now = 1000
        sut.trackCustomerInteractionStarted()
        clock.now = 1001
        sut.trackCardReaderTapped()
        clock.now = 1004
        sut.trackCardReaderTapped()
        clock.now = 1006
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "5000.0")
    }

    @Test func test_track_card_reader_tapped_when_success_and_new_customer_interaction_occur_then_records_new_card_tapped_timestamp() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)

        // When
        clock.now = 1000
        sut.trackCustomerInteractionStarted()
        clock.now = 1001
        sut.trackCardReaderTapped()
        clock.now = 1002
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        clock.now = 2000
        sut.trackCustomerInteractionStarted()
        clock.now = 2001
        sut.trackCardReaderTapped()
        clock.now = 2004
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(properties("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == ["1000.0", "3000.0"])
    }

    @Test func test_track_card_reader_ready_when_order_sync_succeeded_then_tracks_waiting_time_in_seconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })

        // When
        clock.now = 500 // customer interaction started (resets counters)
        sut.trackCustomerInteractionStarted()
        clock.now = 510 // order synced
        sut.trackOrderSyncSuccess()
        clock.now = 513 // reader ready -> waiting_time is tracked in seconds: 513 - 510
        sut.trackCardReaderReady()

        // Then
        #expect(property("waiting_time", in: "reader_ready_for_card_payment") == "3.0")
    }

    @Test func analytics_when_successful_cash_payment_then_reports_correct_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })

        // When
        clock.now = 2000 // customer interaction started
        sut.trackCustomerInteractionStarted()
        clock.now = 2001 // cash payment success -> floor((2001 - 2000) * 1000) = 1000
        sut.trackSuccessfulCashPayment()

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "cash_collect_payment_success") == "1000.0")
    }
}

private extension POSCollectOrderPaymentAnalyticsTests {
    func property(_ key: String, in eventName: String) -> String? {
        analytics.events.first(where: { $0.eventName == eventName })?.properties[key] as? String
    }

    func properties(_ key: String, in eventName: String) -> [String] {
        analytics.events.compactMap { event in
            guard event.eventName == eventName else {
                return nil
            }
            return event.properties[key] as? String
        }
    }
}
