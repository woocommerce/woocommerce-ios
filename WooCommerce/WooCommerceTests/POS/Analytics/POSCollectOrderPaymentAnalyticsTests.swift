@testable import WooCommerce
import protocol WooFoundation.Analytics
import struct Yosemite.CardPresentPaymentsConfiguration
import enum Yosemite.CardReaderServiceError
import typealias Yosemite.PaymentIntent
import enum WooFoundation.CountryCode
import struct Yosemite.Order
import enum Yosemite.OrderAction
import struct Yosemite.PaymentGatewayAccount
import struct PointOfSale.POSPaymentAnalyticsOrder
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

    @Test(arguments: [false, true], [false, true]) @MainActor
    func test_cancel_completion_when_another_payment_starts_then_preserves_active_confirmation(newCheckout: Bool, oldPaymentConfirms: Bool) throws {
        // Given
        var now = 0
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, catalogSyncStrategy: .localCatalog,
                                                             configuration: configuration, monotonicMilliseconds: { now })
        let paymentOrder = POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: "")
        tracker.trackCheckoutTapped()
        now = 100
        tracker.trackOrderSyncSuccess()
        tracker.prepareForCardPayment(order: paymentOrder)
        now = 150
        tracker.trackCardReaderReady()
        let order = Order.fake().copy(orderID: 42, currency: "USD", total: "19.99")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case .retrieveOrderRemotely(_, _, let completion) = action {
                completion(.success(order))
            }
        }
        let preflight = MockCardPresentPaymentPreflightController()
        let receipts = MockReceiptEligibilityUseCase()
        receipts.isEligibleForBackendReceipts = false
        let orchestrator = MockPaymentCaptureOrchestrator()
        var completeCancellation: ((Result<Void, Error>) -> Void)?
        orchestrator.mockCancelPaymentHandler = { completeCancellation = $0 }
        let alerts = MockCardPresentPaymentAlertsPresenter()
        orchestrator.mockCollectPaymentHandler = { onPreparingReader, _, _, _, _, _, _ in
            alerts.onPresentCalled = { viewModel in
                alerts.onPresentCalled = nil
                viewModel.didTapSecondaryButton(in: nil)
            }
            onPreparingReader()
        }
        let useCase = CollectOrderPaymentUseCase<TapToPayCardReaderPaymentAlertsProvider,
                                                BluetoothCardReaderPaymentAlertsProvider,
                                                MockCardPresentPaymentAlertsPresenter>(
            siteID: order.siteID, order: order, formattedAmount: "$19.99", rootViewController: MockViewControllerPresenting(),
            configuration: configuration, stores: stores,
            paymentOrchestrator: orchestrator, alertsPresenter: alerts,
            tapToPayAlertsProvider: TapToPayCardReaderPaymentAlertsProvider(),
            bluetoothAlertsProvider: BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment),
            preflightController: preflight, analyticsTracker: tracker, receiptEligibilityUseCase: receipts)
        useCase.collectPayment(using: .bluetoothScan, channel: .pos, onFailure: { _ in }, onCancel: {},
                               onPaymentCompletion: {}, onCompleted: {})
        preflight.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: "stripe")
        let heldCancellation = try #require(completeCancellation)

        // When
        now = 500
        if newCheckout {
            tracker.trackCheckoutTapped()
            now = 600
            tracker.trackOrderSyncSuccess()
        }
        tracker.prepareForCardPayment(order: paymentOrder)
        now = 650
        tracker.trackCardReaderReady()
        if oldPaymentConfirms {
            now = 675
            let heldConfirmation = try #require(orchestrator.spyProcessingCompletion)
            heldConfirmation(.fake())
        }
        now = 700
        tracker.trackProcessingCompletion(intent: .fake())
        now = 750
        withExtendedLifetime(useCase) { heldCancellation(.success(())) }
        let canceled = try #require(analytics.events.last { $0.eventName == "card_present_collect_payment_canceled" })
        now = 800
        tracker.trackSuccessfulCardPayment(capturedPaymentData: .init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil))

        // Then
        #expect(canceled.properties["sync_strategy"] == nil)
        #expect(!canceled.properties.keys.contains { ($0 as? String)?.hasPrefix("pos_time_since_") == true })
        let succeeded = try #require(analytics.events.last)
        #expect(succeeded.properties["sync_strategy"] as? String == "local_catalog")
        #expect(succeeded.properties["pos_time_since_checkout_started_ms"] as? Int == (newCheckout ? 300 : 800))
        #expect(succeeded.properties["pos_time_since_order_sync_completed_ms"] as? Int == (newCheckout ? 200 : 700))
        #expect(succeeded.properties["pos_time_since_reader_ready_ms"] == nil)
        #expect(succeeded.properties["pos_time_since_payment_confirmed_ms"] as? Int == 100)
    }

    @Test @MainActor func test_card_success_when_all_stages_start_at_zero_then_emits_integer_timings() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, currentTimestamp: { 0 }, monotonicMilliseconds: { 0 })
        sut.trackCheckoutTapped()
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())

        // When
        sut.trackSuccessfulCardPayment(capturedPaymentData: .init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil))

        // Then
        let properties = analytics.events.last?.properties
        #expect(properties?["pos_timing_version"] == nil)
        #expect(properties?["sync_strategy"] as? String == "unknown")
        #expect(properties?["pos_time_since_checkout_started_ms"] as? Int == 0)
        #expect(properties?["pos_time_since_order_sync_completed_ms"] as? Int == 0)
        #expect(properties?["pos_time_since_reader_ready_ms"] == nil)
        #expect(properties?["pos_time_since_payment_confirmed_ms"] as? Int == 0)
    }

    @Test(arguments: [false, true]) @MainActor
    func test_card_terminal_event_when_checkout_has_no_stages_then_omits_unset_timings(isCancellation: Bool) {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, currentTimestamp: { 0 }, monotonicMilliseconds: { 0 })
        sut.trackCheckoutTapped()

        // When
        if isCancellation {
            sut.trackPaymentCancelation(cancelationSource: .reader)
        } else {
            sut.trackPaymentFailure(with: TestError())
        }

        // Then
        let properties = analytics.events.last?.properties
        #expect(properties?["pos_timing_version"] == nil)
        #expect(properties?["sync_strategy"] as? String == (isCancellation ? nil : "unknown"))
        #expect(properties?["pos_time_since_checkout_started_ms"] as? Int == (isCancellation ? nil : 0))
        #expect(properties?["pos_time_since_order_sync_completed_ms"] == nil)
        #expect(properties?["pos_time_since_reader_ready_ms"] == nil)
        #expect(properties?["pos_time_since_payment_confirmed_ms"] == nil)
    }

    @Test(arguments: [true, false]) @MainActor
    func test_card_collection_when_capture_completes_then_tracks_value_only_on_success(captureSucceeds: Bool) {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, configuration: configuration)
        let order = Order.fake().copy(orderID: 42, currency: "USD", total: "19.99")
        let account = PaymentGatewayAccount.fake().copy(gatewayID: "stripe")
        tracker.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        let preflight = MockCardPresentPaymentPreflightController()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case .retrieveOrderRemotely(_, _, let completion) = action {
                completion(.success(order))
            }
        }
        let receipts = MockReceiptEligibilityUseCase()
        receipts.isEligibleForBackendReceipts = false
        let orchestrator = MockPaymentCaptureOrchestrator()
        orchestrator.mockCollectPaymentHandler = { _, _, _, _, _, _, completion in
            #expect(!analytics.events.contains { $0.eventName == "card_present_collect_payment_success" })
            if captureSucceeds {
                completion(.success(.init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)))
            } else {
                completion(.failure(NSError(domain: "capture", code: 1)))
            }
        }
        let useCase = CollectOrderPaymentUseCase<TapToPayCardReaderPaymentAlertsProvider,
                                                BluetoothCardReaderPaymentAlertsProvider,
                                                MockCardPresentPaymentAlertsPresenter>(
            siteID: order.siteID, order: order, formattedAmount: "$19.99", rootViewController: MockViewControllerPresenting(),
            configuration: configuration, stores: stores,
            paymentOrchestrator: orchestrator, alertsPresenter: MockCardPresentPaymentAlertsPresenter(),
            tapToPayAlertsProvider: TapToPayCardReaderPaymentAlertsProvider(),
            bluetoothAlertsProvider: BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment),
            preflightController: preflight, analyticsTracker: tracker, receiptEligibilityUseCase: receipts)

        // When
        useCase.collectPayment(using: .bluetoothScan, channel: .pos, onFailure: { _ in }, onCancel: {},
                               onPaymentCompletion: {}, onCompleted: {})
        preflight.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: account.gatewayID)

        // Then
        #expect(orchestrator.spyDidCallCollectPayment)
        let successes = analytics.events.filter { $0.eventName == "card_present_collect_payment_success" }
        #expect(successes.count == (captureSucceeds ? 1 : 0))
        if captureSucceeds {
            #expect(successes.first?.properties["amount_normalized"] as? Int == 1999)
        }
    }

    @Test(arguments: [false, true], ["stripe", "woocommerce_payments"]) @MainActor
    func test_card_success_when_reader_and_gateway_vary_then_tracks_checkout_value_and_reader_transport(tapToPay: Bool, gateway: String) {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US))
        let order = POSPaymentAnalyticsOrder(orderID: 42, currency: "KWD", total: "12.345", paymentMethodID: "")
        sut.prepareForCardPayment(order: order)
        let reader = tapToPay ? MockCardReader.tapToPay() : MockCardReader.wisePad3()
        sut.preflightResultReceived(.completed(reader, PaymentGatewayAccount.fake().copy(gatewayID: gateway)))

        // When
        sut.trackSuccessfulCardPayment(capturedPaymentData: .init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil))

        // Then
        let event = analytics.events.first { $0.eventName == "card_present_collect_payment_success" }
        #expect(event?.properties["amount_normalized"] as? Int == 12345)
        #expect(event?.properties["currency"] as? String == "KWD")
        #expect(event?.properties["order_id"] as? Int64 == 42)
        #expect(event?.properties["plugin_slug"] as? String == gateway)
        #expect(event?.properties["transport"] as? String == (tapToPay ? "built_in" : "bluetooth"))
        #expect(event?.properties["card_reader_model"] as? String == (tapToPay ? "TAP_TO_PAY_DEVICE" : "WISEPAD_3"))
    }

    @Test @MainActor func test_scan_success_then_tracks_order_gateway_and_currency() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US))
        sut.preflightResultReceived(.completed(MockCardReader.wisePad3(), PaymentGatewayAccount.fake().copy(gatewayID: "woocommerce_payments")))
        let order = POSPaymentAnalyticsOrder(orderID: 42, currency: "EUR", total: "15.00", paymentMethodID: "stripe")

        // When
        sut.trackSuccessfulScanToPayPayment(order: order)

        // Then
        let event = analytics.events.first { $0.eventName == "scan_to_pay_collect_payment_success" }
        #expect(event?.properties["amount_normalized"] as? Int == 1500)
        #expect(event?.properties["currency"] as? String == "EUR")
        #expect(event?.properties["plugin_slug"] as? String == "stripe")
        #expect(event?.properties["country"] as? String == "US")
        #expect(event?.properties["payment_method_type"] as? String == "scan_to_pay")
    }

    @Test @MainActor func analytics_when_successful_payment_then_tracks_event_and_properties() {
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
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(analytics.events.contains(where: { $0.eventName == expectedEvent }))
        #expect(expectedProperties.allSatisfy { key in
            analytics.events.map(\.properties).contains(where: { $0.keys.contains(key) })
        })
    }

    @Test @MainActor func test_track_successful_card_payment_when_timing_markers_are_unset_then_reports_zero_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil)

        // When
        clock.now = 1000
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_order_sync_success", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_reader_ready_to_collect_payment", in: "card_present_collect_payment_success") == "0.0")
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "0.0")
    }

    @Test @MainActor func test_track_successful_card_payment_when_timing_markers_are_set_then_reports_correct_elapsed_milliseconds() {
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
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "card_present_collect_payment_success") == "5000.0")
        #expect(property("milliseconds_since_order_sync_success", in: "card_present_collect_payment_success") == "4000.0")
        #expect(property("milliseconds_since_reader_ready_to_collect_payment", in: "card_present_collect_payment_success") == "3000.0")
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "2000.0")
    }

    @Test @MainActor func test_track_card_reader_tapped_when_processing_event_repeats_then_preserves_first_card_tapped_timestamp() {
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
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "5000.0")
    }

    @Test @MainActor func test_track_card_reader_tapped_when_success_and_new_customer_interaction_occur_then_records_new_card_tapped_timestamp() {
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
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        clock.now = 2000
        sut.trackCustomerInteractionStarted()
        clock.now = 2001
        sut.trackCardReaderTapped()
        clock.now = 2004
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(properties("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == ["1000.0", "3000.0"])
    }

    @Test @MainActor func test_track_payment_failure_when_card_reader_was_tapped_then_next_attempt_records_new_card_tapped_timestamp() {
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
        sut.trackPaymentFailure(with: TestError())

        clock.now = 1005
        sut.trackCardReaderTapped()
        clock.now = 1008
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "3000.0")
    }

    @Test @MainActor func test_track_payment_cancelation_when_card_reader_was_tapped_then_next_attempt_records_new_card_tapped_timestamp() {
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
        sut.trackPaymentCancelation(cancelationSource: .other)

        clock.now = 1005
        sut.trackCardReaderTapped()
        clock.now = 1008
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
        sut.trackSuccessfulCardPayment(capturedPaymentData: capturedPaymentData)

        // Then
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_success") == "3000.0")
    }

    @Test @MainActor func test_track_card_reader_ready_when_order_sync_succeeded_then_tracks_waiting_time_in_seconds() {
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

    @Test @MainActor func test_track_card_reader_ready_when_order_sync_never_succeeded_then_reports_zero_waiting_time() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })

        // When
        clock.now = 1_786_307_015 // customer interaction started (resets the order sync marker)
        sut.trackCustomerInteractionStarted()
        clock.now = 1_786_307_018 // reader ready before any order sync
        sut.trackCardReaderReady()

        // Then
        #expect(property("waiting_time", in: "reader_ready_for_card_payment") == "0.0")
    }

    @Test @MainActor func test_track_successful_cash_payment_when_customer_interaction_started_then_reports_correct_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })

        // When
        clock.now = 2000 // customer interaction started
        sut.trackCustomerInteractionStarted()
        clock.now = 2001 // cash payment success -> floor((2001 - 2000) * 1000) = 1000
        sut.trackSuccessfulCashPayment(order: POSPaymentAnalyticsOrder(orderID: 0, currency: "USD", total: "19.99", paymentMethodID: ""))

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "cash_collect_payment_success") == "1000.0")
    }

    @Test @MainActor func test_track_payment_failure_then_tracks_event_with_error_and_properties() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, configuration: configuration)
        let expectedEvent = "card_present_collect_payment_failed"
        let expectedProperties = [
            "card_reader_model",
            "country",
            "plugin_slug",
            "milliseconds_since_customer_interaction_started",
            "milliseconds_since_order_sync_success",
            "milliseconds_since_reader_ready_to_collect_payment",
            "milliseconds_since_card_tapped",
            "checkout_tap_count"
        ]

        // When
        sut.trackPaymentFailure(with: TestError())

        // Then
        let trackedEvent = analytics.events.first(where: { $0.eventName == expectedEvent })
        #expect(trackedEvent != nil)
        #expect(trackedEvent?.error is TestError)
        #expect(expectedProperties.allSatisfy { trackedEvent?.properties.keys.contains($0) == true })
    }

    @Test @MainActor func test_track_payment_failure_when_error_carries_interac_payment_method_then_reports_payment_method_type() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .CA))
        let error = CardReaderServiceError.paymentCaptureWithPaymentMethod(underlyingError: .paymentDeclinedByCardReader,
                                                                          paymentMethod: .interacPresent(details: .fake()))

        // When
        sut.trackPaymentFailure(with: error)

        // Then
        #expect(property("payment_method_type", in: "card_present_collect_payment_failed") == "card_interac")
    }

    @Test @MainActor func test_track_payment_failure_when_error_carries_no_payment_method_then_omits_payment_method_type() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US))

        // When
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(property("payment_method_type", in: "card_present_collect_payment_failed") == nil)
    }

    @Test(arguments: [false, true]) @MainActor
    func test_track_payment_cancelation_when_timing_stages_vary_then_preserves_metadata_without_timings(stagesReached: Bool) throws {
        // Given
        let clock = TestClock()
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, configuration: configuration, currentTimestamp: { clock.now })
        if stagesReached {
            clock.now = 1000
            sut.trackCustomerInteractionStarted()
            sut.trackCheckoutTapped()
            sut.trackOrderSyncSuccess()
            sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: ""))
            sut.trackCardReaderReady()
            sut.trackCardReaderTapped()
            sut.trackProcessingCompletion(intent: .fake())
            clock.now = 1005
        }

        // When
        sut.trackPaymentCancelation(cancelationSource: .paymentWaitingForInput)

        // Then
        let event = try #require(analytics.events.last)
        #expect(event.eventName == "card_present_collect_payment_canceled")
        #expect(event.properties["cancellation_source"] as? String == "payment_waiting_for_input")
        #expect(event.properties["country"] as? String == "US")
        #expect(event.properties["checkout_tap_count"] as? String == (stagesReached ? "1" : "0"))
        #expect(event.properties["sync_strategy"] == nil)
        #expect(!event.properties.keys.contains {
            guard let key = $0 as? String else { return false }
            return key.hasPrefix("milliseconds_since_") || key.hasPrefix("pos_time_since_")
        })
    }

    @Test @MainActor func test_track_payment_failure_when_timing_markers_are_set_then_reports_correct_elapsed_milliseconds() {
        // Given
        let clock = TestClock()
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US),
                                                         currentTimestamp: { clock.now })

        // When
        clock.now = 1000 // customer interaction started
        sut.trackCustomerInteractionStarted()
        clock.now = 1002 // reader ready
        sut.trackCardReaderReady()
        clock.now = 1003 // card tapped
        sut.trackCardReaderTapped()
        clock.now = 1005 // payment failed
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(property("milliseconds_since_customer_interaction_started", in: "card_present_collect_payment_failed") == "5000.0")
        #expect(property("milliseconds_since_reader_ready_to_collect_payment", in: "card_present_collect_payment_failed") == "3000.0")
        #expect(property("milliseconds_since_card_tapped", in: "card_present_collect_payment_failed") == "2000.0")
    }

    @Test @MainActor func test_track_processing_completion_when_payment_method_is_interac_then_tracks_interac_success() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .CA))
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))])

        // When
        sut.trackProcessingCompletion(intent: intent)

        // Then
        #expect(property("country", in: "card_interac_collect_payment_success") == "CA")
    }

    @Test @MainActor func test_track_processing_completion_when_payment_method_is_not_interac_then_tracks_nothing() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US))
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])

        // When
        sut.trackProcessingCompletion(intent: intent)

        // Then
        #expect(analytics.events.isEmpty)
    }

    @Test @MainActor func test_track_payment_failure_when_checkout_retried_then_preserves_checkout_tap_count() {
        // Given
        let sut = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                                         configuration: CardPresentPaymentsConfiguration(country: .US))

        // When
        sut.trackCheckoutTapped()
        sut.trackPaymentFailure(with: TestError())
        sut.trackCheckoutTapped()
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(properties("checkout_tap_count", in: "card_present_collect_payment_failed") == ["1", "2"])
    }
}

private extension POSCollectOrderPaymentAnalyticsTests {
    struct TestError: Error { }

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
