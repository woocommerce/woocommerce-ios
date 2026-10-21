import Testing
import PointOfSale
import Yosemite
@testable import WooCommerce

@MainActor
struct CardPresentPaymentServiceTests {
    @Test func test_initialization_when_publisher_callbacks_are_omitted_then_completes() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))

        // When
        _ = await CardPresentPaymentService(
            siteID: 123,
            stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker()
        )

        // Then
        let actions = stores.receivedActions.compactMap { $0 as? CardPresentPaymentAction }
        #expect(actions.count == 3)
        #expect(actions.contains { action in
            if case .publishCardReaderConnections = action { return true }
            return false
        })
        #expect(actions.contains { action in
            if case .observeCardReaderUpdateState = action { return true }
            return false
        })
        #expect(actions.contains { action in
            if case .observeCardReaderReconnectionState = action { return true }
            return false
        })
    }

    @Test func test_cancel_when_service_has_no_task_then_preserves_other_collection_confirmation() async {
        let analytics = MockPOSAnalytics()
        var milliseconds = 0
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { milliseconds })
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores, collectOrderPaymentAnalyticsTracker: tracker)
        tracker.trackCheckoutTapped()
        tracker.trackProcessingCompletion(intent: .fake())
        let cancel: () -> Void = service.cancelPayment
        cancel()
        milliseconds = 100
        tracker.trackPaymentFailure(with: CancellationError())
        #expect(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] as? Int == 100)
    }

    @Test func test_async_cancel_when_sdk_request_starts_then_clears_confirmation_before_callback() async throws {
        let analytics = MockPOSAnalytics()
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { 0 })
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let service = await CardPresentPaymentService(siteID: 123, stores: stores, collectOrderPaymentAnalyticsTracker: tracker)
        tracker.trackCheckoutTapped()
        tracker.trackProcessingCompletion(intent: .fake())
        var receivedCancellation = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case .cancelPayment(let complete) = action else { return }
            receivedCancellation = true
            tracker.trackPaymentFailure(with: CancellationError())
            #expect(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] == nil)
            complete?(.success(()))
        }
        try await service.cancelPayment()
        #expect(receivedCancellation)
    }
}
