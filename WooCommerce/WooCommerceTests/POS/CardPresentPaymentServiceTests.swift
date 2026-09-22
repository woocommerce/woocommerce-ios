import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct CardPresentPaymentServiceTests {
    @MainActor
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
}
