import Foundation
import Testing
@testable import PointOfSale
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSCheckoutTimingTests {
    private let analytics = MockPOSAnalytics()
    private let clock = TestClock()
    private let order = POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: "")

    @Test(arguments: Fixture.allCases)
    func test_terminal_event_when_shared_scenario_runs_then_matches_cross_platform_contract(fixture: Fixture) throws {
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(fixture.strategy)
        sut.trackCheckoutTapped()
        if fixture != .failureBeforeSync {
            clock.milliseconds = fixture == .immediateZero ? 0 : 100
            sut.trackOrderSyncSuccess()
            sut.prepareForCardPayment(order: order)
        }

        switch fixture {
        case .allStagesSuccess, .failureAfterConfirmation, .cashSuccess:
            clock.milliseconds = 150
            sut.trackCardReaderReady()
            clock.milliseconds = 200
            sut.trackProcessingCompletion(intent: .fake())
        case .immediateZero:
            sut.trackCardReaderReady()
            sut.trackProcessingCompletion(intent: .fake())
        case .unchangedOrderNewCheckout:
            clock.milliseconds = 500
            sut.trackCheckoutTapped()
            sut.prepareForCardPayment(order: order)
            clock.milliseconds = 510
            sut.trackCardReaderReady()
            clock.milliseconds = 520
            sut.trackProcessingCompletion(intent: .fake())
        case .directRetryBeforeReader, .alreadyConfirmedIntentReused:
            clock.milliseconds = 150
            sut.trackCardReaderReady()
            clock.milliseconds = 200
            sut.trackProcessingCompletion(intent: .fake())
            clock.milliseconds = 250
            sut.trackPaymentFailure(with: TestError())
            if fixture == .alreadyConfirmedIntentReused {
                clock.milliseconds = 400
                sut.trackProcessingCompletion(intent: .fake())
            }
        case .cancelAfterReaderReady:
            clock.milliseconds = 150
            sut.trackCardReaderReady()
        case .failureBeforeSync:
            break
        }
        clock.milliseconds = fixture.terminalMilliseconds
        switch fixture {
        case .failureBeforeSync, .failureAfterConfirmation, .directRetryBeforeReader:
            sut.trackPaymentFailure(with: TestError())
        case .cancelAfterReaderReady:
            sut.trackPaymentCancelation(cancelationSource: .reader)
        case .cashSuccess:
            sut.trackSuccessfulCashPayment(order: order)
        default:
            succeed(sut)
        }

        let actual = try timingProperties()
        var expected: [String: Any] = fixture.expectedTimings
        if fixture != .cancelAfterReaderReady {
            expected["sync_strategy"] = fixture.strategy.rawValue
        }
        #expect(NSDictionary(dictionary: actual).isEqual(to: expected))
        if fixture == .cancelAfterReaderReady {
            let cancellation = try #require(analytics.events.last)
            #expect(!cancellation.properties.keys.contains { ($0 as? String)?.hasPrefix("milliseconds_since_") == true })
        }
        for (key, value) in actual where key != "sync_strategy" {
            #expect(value is Int, "\(key) must be an integer")
        }
    }

    @Test func test_callbacks_when_repeated_then_preserve_first_confirmation_and_omit_reader_ready() throws {
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 150
        sut.trackCardReaderReady()
        clock.milliseconds = 200
        sut.trackProcessingCompletion(intent: .fake())

        clock.milliseconds = 225
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 250
        succeed(sut)

        let actual = try timingProperties()
        #expect(actual["pos_time_since_reader_ready_ms"] == nil)
        #expect(actual["pos_time_since_payment_confirmed_ms"] as? Int == 50)
    }

    @Test(arguments: [false, true])
    func test_card_outcome_when_confirmation_is_recorded_then_consumes_only_confirmation(success: Bool) throws {
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        clock.milliseconds = 100
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 150
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 200
        if success {
            succeed(sut)
        } else {
            sut.trackPaymentFailure(with: TestError())
        }
        #expect(try timingProperties()["pos_time_since_payment_confirmed_ms"] as? Int == 50)
        clock.milliseconds = 350
        sut.trackPaymentFailure(with: TestError())
        let actual = try timingProperties()
        #expect(actual["pos_time_since_checkout_started_ms"] as? Int == 350)
        #expect(actual["pos_time_since_order_sync_completed_ms"] as? Int == 250)
        #expect(actual["pos_time_since_payment_confirmed_ms"] == nil)
    }

    @Test func test_cash_outcome_when_card_is_confirmed_then_preserves_confirmation_for_card_outcome() throws {
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 100
        sut.trackOrderSyncSuccess()
        clock.milliseconds = 150
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 200
        sut.trackSuccessfulCashPayment(order: order)
        #expect(try timingProperties()["pos_time_since_payment_confirmed_ms"] == nil)
        clock.milliseconds = 250
        succeed(sut)
        #expect(try timingProperties()["pos_time_since_payment_confirmed_ms"] as? Int == 100)
    }

    @Test func test_cash_completion_when_checkout_changes_during_async_payment_then_reads_fresh_snapshot() async throws {
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        let handler = MockDeferredPOSCashPaymentHandler()
        let orderController = PointOfSalePreviewOrderController(orderState: .loaded(
            .init(cartTotal: "$19.99", orderTotal: "$19.99", taxTotal: "$0.00", orderTotalDecimal: 19.99),
            .fake().copy(orderID: 42, currency: "USD", total: "19.99")))
        let model = POSPaymentModel(
            cardPresentPaymentService: CardPresentPaymentPreviewService(),
            orderProvider: POSCartPaymentOrderProvider(orderController: orderController),
            cashPaymentHandler: handler,
            scanToPayHandler: POSCartScanToPayHandler(orderController: orderController),
            markAsPaidHandler: POSCartMarkAsPaidHandler(orderController: orderController),
            receiptSender: POSReceiptSenderPreview(), configuration: .cart(onNewOrder: {}, onEditOrder: {}),
            analytics: analytics, collectOrderPaymentAnalyticsTracker: sut, celebration: MockPaymentCaptureCelebration())
        handler.onComplete = {
            clock.milliseconds = 500
            sut.setCatalogSyncStrategy(.remote)
            sut.trackCheckoutTapped()
            clock.milliseconds = 600
            sut.trackOrderSyncSuccess()
            sut.prepareForCardPayment(order: order)
            clock.milliseconds = 650
            sut.trackProcessingCompletion(intent: .fake())
            clock.milliseconds = 700
        }
        try await model.collectCashPayment(changeDueAmount: nil)
        let cash = try timingProperties()
        #expect(cash["sync_strategy"] as? String == "remote")
        #expect(cash["pos_time_since_checkout_started_ms"] as? Int == 200)
        #expect(cash["pos_time_since_order_sync_completed_ms"] as? Int == 100)
        #expect(cash["pos_time_since_payment_confirmed_ms"] == nil)
        clock.milliseconds = 800
        succeed(sut)
        #expect(try timingProperties()["pos_time_since_payment_confirmed_ms"] as? Int == 150)
    }

    @Test func test_new_checkout_when_previous_stages_exist_then_clears_sync_and_confirmation() throws {
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.trackOrderSyncSuccess()
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 100
        sut.trackCheckoutTapped()
        clock.milliseconds = 150
        sut.trackPaymentFailure(with: TestError())
        let actual = try timingProperties()
        #expect(actual["pos_time_since_checkout_started_ms"] as? Int == 50)
        #expect(actual["pos_time_since_order_sync_completed_ms"] == nil)
        #expect(actual["pos_time_since_payment_confirmed_ms"] == nil)
    }

    @Test(arguments: [false, true])
    func test_reset_when_previous_stages_exist_then_omits_all_elapsed_fields(newCustomer: Bool) throws {
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(.localCatalog)
        sut.trackCheckoutTapped()
        sut.trackOrderSyncSuccess()
        sut.trackProcessingCompletion(intent: .fake())
        if newCustomer {
            sut.trackCustomerInteractionStarted()
        } else {
            sut.resetCheckoutTiming()
        }
        clock.milliseconds = 150
        sut.trackPaymentFailure(with: TestError())
        #expect(Set(try timingProperties().keys) == ["sync_strategy"])
    }

    @Test func test_outcome_when_state_changes_after_preparation_then_reads_fresh_shared_snapshot() throws {
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(.localCatalog)
        sut.trackCheckoutTapped()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 100
        sut.setCatalogSyncStrategy(.remote)
        sut.trackCheckoutTapped()
        clock.milliseconds = 150
        sut.trackOrderSyncSuccess()
        clock.milliseconds = 175
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 200
        sut.preflightResultReceived(.completed(MockCardReader.tapToPay(), .fake().copy(gatewayID: "woocommerce-payments")))
        clock.milliseconds = 250
        succeed(sut)
        let actual = try timingProperties()
        #expect(actual["sync_strategy"] as? String == "remote")
        #expect(actual["pos_time_since_checkout_started_ms"] as? Int == 150)
        #expect(actual["pos_time_since_order_sync_completed_ms"] as? Int == 100)
        #expect(actual["pos_time_since_payment_confirmed_ms"] as? Int == 75)
        #expect(analytics.events.last?.properties["transport"] as? String == "built_in")
        #expect(analytics.events.last?.properties["plugin_slug"] as? String == "woocommerce-payments")
    }

    @Test func test_strategy_when_selected_source_changes_then_keeps_checkout_source_until_next_checkout() throws {
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(.localCatalog)
        sut.trackCheckoutTapped()
        sut.setCatalogSyncStrategy(.remote)
        sut.trackPaymentFailure(with: TestError())
        #expect(try timingProperties()["sync_strategy"] as? String == "local_catalog")
        sut.trackCheckoutTapped()
        sut.trackPaymentFailure(with: TestError())
        #expect(try timingProperties()["sync_strategy"] as? String == "remote")
    }

    @Test func test_confirmation_when_no_checkout_started_then_omits_elapsed_fields() throws {
        let sut = makeTracker()

        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 50
        sut.trackPaymentFailure(with: TestError())

        #expect(Set(try timingProperties().keys) == ["sync_strategy"])
    }

    @Test func test_timing_when_wall_clock_changes_then_uses_only_continuous_clock() throws {
        let sut = makeTracker()
        clock.wallTime = 1000
        sut.trackCheckoutTapped()

        clock.wallTime = -10_000
        clock.milliseconds = 123
        sut.trackPaymentFailure(with: TestError())

        #expect(try timingProperties()["pos_time_since_checkout_started_ms"] as? Int == 123)
    }

    @Test func test_timing_when_injected_clock_moves_backwards_then_omits_negative_duration() throws {
        let sut = makeTracker()
        clock.milliseconds = 100
        sut.trackCheckoutTapped()

        clock.milliseconds = 50
        sut.trackPaymentFailure(with: TestError())

        #expect(try timingProperties()["pos_time_since_checkout_started_ms"] == nil)
    }

    @Test func test_event_snapshot_when_stage_is_missing_or_negative_then_removes_previous_value_and_preserves_zero() {
        let original = WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
            "order_id": 42,
            "milliseconds_since_card_tapped": "17.0",
            "pos_time_since_checkout_started_ms": 500,
            "pos_time_since_order_sync_completed_ms": 400,
            "pos_time_since_payment_confirmed_ms": 300
        ])

        let event = WooAnalyticsEvent.PointOfSale.withCheckoutTiming(
            original, syncStrategy: .remote,
            millisecondsSinceCheckoutStarted: -1,
            millisecondsSinceOrderSyncCompleted: nil,
            millisecondsSincePaymentConfirmed: 0)

        #expect(event.statName == original.statName)
        #expect(event.properties["order_id"] as? Int == 42)
        #expect(event.properties["milliseconds_since_card_tapped"] as? String == "17.0")
        #expect(Set(event.properties.keys) == ["order_id", "milliseconds_since_card_tapped",
                                               "sync_strategy", "pos_time_since_payment_confirmed_ms"])
        #expect(event.properties["pos_timing_version"] == nil)
        #expect(event.properties["sync_strategy"] as? String == "remote")
        #expect(event.properties["pos_time_since_checkout_started_ms"] == nil)
        #expect(event.properties["pos_time_since_order_sync_completed_ms"] == nil)
        #expect(event.properties["pos_time_since_payment_confirmed_ms"] as? Int == 0)
        #expect(original.properties["pos_time_since_checkout_started_ms"] as? Int == 500)
        #expect(original.properties["pos_time_since_order_sync_completed_ms"] as? Int == 400)
        #expect(original.properties["pos_time_since_payment_confirmed_ms"] as? Int == 300)
    }

    private func makeTracker() -> POSCollectOrderPaymentAnalyticsAdaptor {
        POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics,
                                              currentTimestamp: { clock.wallTime },
                                              monotonicMilliseconds: { clock.milliseconds })
    }

    private func succeed(_ tracker: POSCollectOrderPaymentAnalyticsAdaptor) {
        tracker.trackSuccessfulCardPayment(capturedPaymentData: .init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil))
    }

    private func timingProperties() throws -> [String: Any] {
        let event = try #require(analytics.events.last)
        return Dictionary(uniqueKeysWithValues: event.properties.compactMap { key, value in
            guard let key = key as? String,
                  key.hasPrefix("pos_time_") || key == "pos_timing_version" || key == "sync_strategy" else { return nil }
            return (key, value)
        })
    }

    private final class TestClock {
        var milliseconds = 0
        var wallTime: TimeInterval = 0
    }

    private struct TestError: Error {}

    enum Fixture: String, CaseIterable {
        case allStagesSuccess = "all_stages_success"
        case failureBeforeSync = "failure_before_sync"
        case immediateZero = "immediate_event_zero_is_valid"
        case unchangedOrderNewCheckout = "unchanged_order_new_checkout"
        case directRetryBeforeReader = "direct_retry_before_reader"
        case alreadyConfirmedIntentReused = "already_confirmed_intent_reused"
        case cancelAfterReaderReady = "cancel_after_reader_ready"
        case failureAfterConfirmation = "failure_after_confirmation"
        case cashSuccess = "cash_success_card_stages_always_absent"

        var strategy: POSCheckoutCatalogStrategy {
            switch self {
            case .failureBeforeSync, .cashSuccess: .remote
            case .immediateZero: .unknown
            default: .localCatalog
            }
        }

        var terminalMilliseconds: Int {
            switch self {
            case .allStagesSuccess, .failureAfterConfirmation: 250
            case .failureBeforeSync: 25
            case .immediateZero: 0
            case .unchangedOrderNewCheckout: 550
            case .directRetryBeforeReader: 350
            case .alreadyConfirmedIntentReused: 450
            case .cancelAfterReaderReady: 200
            case .cashSuccess: 300
            }
        }

        var expectedTimings: [String: Int] {
            let values: [Int?]
            switch self {
            case .allStagesSuccess, .failureAfterConfirmation: values = [250, 150, nil, 50]
            case .failureBeforeSync: values = [25, nil, nil, nil]
            case .immediateZero: values = [0, 0, nil, 0]
            case .unchangedOrderNewCheckout: values = [50, nil, nil, 30]
            case .directRetryBeforeReader: values = [350, 250, nil, nil]
            case .alreadyConfirmedIntentReused: values = [450, 350, nil, 50]
            case .cancelAfterReaderReady: values = [nil, nil, nil, nil]
            case .cashSuccess: values = [300, 200, nil, nil]
            }
            let keys = ["pos_time_since_checkout_started_ms", "pos_time_since_order_sync_completed_ms",
                        "pos_time_since_reader_ready_ms", "pos_time_since_payment_confirmed_ms"]
            return Dictionary(uniqueKeysWithValues: zip(keys, values).compactMap { key, value in value.map { (key, $0) } })
        }
    }
}
