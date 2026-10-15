import Foundation
import Testing
@testable import PointOfSale
import Yosemite
@testable import WooCommerce

@MainActor
struct POSCheckoutTimingTests {
    private let analytics = MockPOSAnalytics()
    private let clock = TestClock()
    private let order = POSPaymentAnalyticsOrder(orderID: 42, currency: "USD", total: "19.99", paymentMethodID: "")

    @Test(arguments: Fixture.allCases)
    func test_terminal_event_when_shared_scenario_runs_then_matches_cross_platform_contract(fixture: Fixture) throws {
        // Given
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(fixture.strategy)
        sut.trackCheckoutTapped()
        if fixture != .failureBeforeSync {
            clock.milliseconds = fixture == .immediateZero ? 0 : 100
            sut.trackOrderSyncSuccess()
            sut.prepareForCardPayment(order: order)
        }

        // When
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

        // Then
        let actual = try timingProperties()
        var expected: [String: Any] = fixture.expectedTimings
        expected["sync_strategy"] = fixture.strategy.rawValue
        #expect(NSDictionary(dictionary: actual).isEqual(to: expected))
        for (key, value) in actual where key != "sync_strategy" {
            #expect(value is Int, "\(key) must be an integer")
        }
    }

    @Test func test_callbacks_when_repeated_then_preserve_first_confirmation_and_omit_reader_ready() throws {
        // Given
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 150
        sut.trackCardReaderReady()
        clock.milliseconds = 200
        sut.trackProcessingCompletion(intent: .fake())

        // When
        clock.milliseconds = 225
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 250
        succeed(sut)

        // Then
        let actual = try timingProperties()
        #expect(actual["pos_time_since_reader_ready_ms"] == nil)
        #expect(actual["pos_time_since_payment_confirmed_ms"] as? Int == 50)
    }

    @Test(arguments: [false, true])
    func test_retry_when_attempt_ends_or_new_attempt_starts_then_clears_only_payment_stages(cancel: Bool) throws {
        // Given
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        clock.milliseconds = 100
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: order)
        clock.milliseconds = 150
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())

        // When
        clock.milliseconds = 200
        if cancel {
            sut.trackPaymentCancelation(cancelationSource: .reader)
            let canceled = try timingProperties()
            #expect(canceled["pos_time_since_reader_ready_ms"] == nil)
            #expect(canceled["pos_time_since_payment_confirmed_ms"] as? Int == 50)
        } else {
            sut.prepareForCardPayment(order: order)
        }
        clock.milliseconds = 350
        sut.trackPaymentFailure(with: TestError())

        // Then
        let actual = try timingProperties()
        #expect(actual["pos_time_since_checkout_started_ms"] as? Int == 350)
        #expect(actual["pos_time_since_order_sync_completed_ms"] as? Int == 250)
        #expect(actual["pos_time_since_reader_ready_ms"] == nil)
        #expect(actual["pos_time_since_payment_confirmed_ms"] == nil)
    }

    @Test(arguments: [false, true])
    func test_success_when_another_terminal_event_arrives_then_checkout_context_is_closed(cash: Bool) throws {
        // Given
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: order)
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())
        if cash {
            sut.trackSuccessfulCashPayment(order: order)
        } else {
            succeed(sut)
        }

        // When
        clock.milliseconds = 250
        sut.trackCardReaderReady()
        sut.trackProcessingCompletion(intent: .fake())
        succeed(sut)

        // Then
        let actual = try timingProperties()
        #expect(Set(actual.keys) == ["sync_strategy"])
    }

    @Test(arguments: [false, true])
    func test_scoped_success_when_another_payment_started_then_closes_only_its_own_context(newCheckout: Bool) throws {
        // Given
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(.localCatalog)
        sut.trackCheckoutTapped()
        clock.milliseconds = 100
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: order)
        let previousPayment = sut.scopedToPayment()
        clock.milliseconds = 500
        sut.setCatalogSyncStrategy(.remote)
        if newCheckout {
            sut.trackCheckoutTapped()
        }
        let nextOrder = POSPaymentAnalyticsOrder(orderID: 84, currency: "GBP", total: "12.34", paymentMethodID: "")
        sut.prepareForCardPayment(order: nextOrder)

        // When
        clock.milliseconds = 600
        previousPayment.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 650
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 700
        previousPayment.trackSuccessfulCardPayment(capturedPaymentData: .init(paymentMethod: .cardPresent(details: .fake()), receiptParameters: nil))
        let previous = try timingProperties()
        let previousEvent = try #require(analytics.events.last)
        clock.milliseconds = 800
        succeed(sut)

        // Then
        #expect(previousEvent.properties["order_id"] as? Int64 == 42)
        #expect(previousEvent.properties["amount_normalized"] as? Int == 1999)
        #expect(previousEvent.properties["currency"] as? String == "USD")
        #expect(analytics.events.last?.properties["order_id"] as? Int64 == 84)
        #expect(analytics.events.last?.properties["amount_normalized"] as? Int == 1234)
        #expect(analytics.events.last?.properties["currency"] as? String == "GBP")
        #expect(previous["sync_strategy"] as? String == "local_catalog")
        #expect(previous["pos_time_since_checkout_started_ms"] as? Int == 700)
        #expect(previous["pos_time_since_order_sync_completed_ms"] as? Int == 600)
        #expect(previous["pos_time_since_payment_confirmed_ms"] as? Int == 100)
        let current = try timingProperties()
        #expect(current["sync_strategy"] as? String == (newCheckout ? "remote" : "local_catalog"))
        #expect(current["pos_time_since_checkout_started_ms"] as? Int == (newCheckout ? 300 : 800))
        #expect(current["pos_time_since_order_sync_completed_ms"] as? Int == (newCheckout ? nil : 700))
        #expect(current["pos_time_since_payment_confirmed_ms"] as? Int == 150)
    }

    @Test func test_cash_completion_when_another_checkout_starts_then_preserves_both_contexts() async throws {
        // Given
        let sut = makeTracker()
        sut.setCatalogSyncStrategy(.localCatalog)
        sut.trackCheckoutTapped()
        clock.milliseconds = 100
        sut.trackOrderSyncSuccess()
        let cashHandler = MockDeferredPOSCashPaymentHandler()
        let orderController = PointOfSalePreviewOrderController(orderState: .loaded(
            .init(cartTotal: "$19.99", orderTotal: "$19.99", taxTotal: "$0.00", orderTotalDecimal: 19.99),
            .fake().copy(orderID: 42, currency: "USD", total: "19.99")))
        let model = POSPaymentModel(
            cardPresentPaymentService: CardPresentPaymentPreviewService(),
            orderProvider: POSCartPaymentOrderProvider(orderController: orderController),
            cashPaymentHandler: cashHandler,
            scanToPayHandler: POSCartScanToPayHandler(orderController: orderController),
            markAsPaidHandler: POSCartMarkAsPaidHandler(orderController: orderController),
            receiptSender: POSReceiptSenderPreview(), configuration: .cart(onNewOrder: {}, onEditOrder: {}),
            analytics: analytics, collectOrderPaymentAnalyticsTracker: sut, celebration: MockPaymentCaptureCelebration())
        var paymentTask: Task<Void, Error>?
        await withCheckedContinuation { started in
            cashHandler.onStarted = { started.resume() }
            paymentTask = Task { try await model.collectCashPayment(changeDueAmount: nil) }
        }
        let heldCash = try #require(cashHandler.completion)
        let task = try #require(paymentTask)

        // When
        clock.milliseconds = 500
        sut.setCatalogSyncStrategy(.remote)
        sut.trackCheckoutTapped()
        clock.milliseconds = 600
        sut.trackOrderSyncSuccess()
        sut.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: 84, currency: "GBP", total: "12.34", paymentMethodID: ""))
        clock.milliseconds = 650
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 700
        heldCash.resume()
        try await task.value
        let cash = try timingProperties()
        let cashEvent = try #require(analytics.events.last)
        clock.milliseconds = 800
        succeed(sut)

        // Then
        #expect(cashEvent.properties["order_id"] as? Int64 == 42)
        #expect(cashEvent.properties["amount_normalized"] as? Int == 1999)
        #expect(cash["sync_strategy"] as? String == "local_catalog")
        #expect(cash["pos_time_since_checkout_started_ms"] as? Int == 700)
        #expect(cash["pos_time_since_order_sync_completed_ms"] as? Int == 600)
        #expect(cash["pos_time_since_payment_confirmed_ms"] == nil)
        let current = try timingProperties()
        #expect(current["sync_strategy"] as? String == "remote")
        #expect(current["pos_time_since_checkout_started_ms"] as? Int == 300)
        #expect(current["pos_time_since_order_sync_completed_ms"] as? Int == 200)
        #expect(current["pos_time_since_payment_confirmed_ms"] as? Int == 150)
    }

    @Test func test_confirmation_when_no_checkout_started_then_omits_elapsed_fields() throws {
        // Given
        let sut = makeTracker()

        // When
        sut.trackProcessingCompletion(intent: .fake())
        clock.milliseconds = 50
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(Set(try timingProperties().keys) == ["sync_strategy"])
    }

    @Test(arguments: [false, true])
    func test_payment_after_success_when_no_new_checkout_started_then_omits_elapsed_fields(cash: Bool) throws {
        // Given
        let sut = makeTracker()
        sut.trackCheckoutTapped()
        sut.prepareForCardPayment(order: order)
        succeed(sut)

        // When
        clock.milliseconds = 100
        if cash {
            let completion = sut.captureCashSuccess()
            completion(order)
        } else {
            sut.prepareForCardPayment(order: order)
            succeed(sut)
        }

        // Then
        #expect(Set(try timingProperties().keys) == ["sync_strategy"])
    }

    @Test func test_timing_when_wall_clock_changes_then_uses_only_continuous_clock() throws {
        // Given
        let sut = makeTracker()
        clock.wallTime = 1000
        sut.trackCheckoutTapped()

        // When
        clock.wallTime = -10_000
        clock.milliseconds = 123
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(try timingProperties()["pos_time_since_checkout_started_ms"] as? Int == 123)
    }

    @Test func test_timing_when_injected_clock_moves_backwards_then_omits_negative_duration() throws {
        // Given
        let sut = makeTracker()
        clock.milliseconds = 100
        sut.trackCheckoutTapped()

        // When
        clock.milliseconds = 50
        sut.trackPaymentFailure(with: TestError())

        // Then
        #expect(try timingProperties()["pos_time_since_checkout_started_ms"] == nil)
    }

    @Test func test_event_snapshot_when_stage_is_missing_or_negative_then_removes_previous_value_and_preserves_zero() {
        // Given
        let original = WooAnalyticsEvent(statName: .collectPaymentSuccess, properties: [
            "order_id": 42,
            "milliseconds_since_card_tapped": "17.0",
            "pos_time_since_checkout_started_ms": 500,
            "pos_time_since_order_sync_completed_ms": 400,
            "pos_time_since_payment_confirmed_ms": 300
        ])

        // When
        let event = WooAnalyticsEvent.PointOfSale.withCheckoutTiming(
            original, syncStrategy: .remote,
            millisecondsSinceCheckoutStarted: -1,
            millisecondsSinceOrderSyncCompleted: nil,
            millisecondsSincePaymentConfirmed: 0)

        // Then
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
            case .cancelAfterReaderReady: values = [200, 100, nil, nil]
            case .cashSuccess: values = [300, 200, nil, nil]
            }
            let keys = ["pos_time_since_checkout_started_ms", "pos_time_since_order_sync_completed_ms",
                        "pos_time_since_reader_ready_ms", "pos_time_since_payment_confirmed_ms"]
            return Dictionary(uniqueKeysWithValues: zip(keys, values).compactMap { key, value in value.map { (key, $0) } })
        }
    }
}
