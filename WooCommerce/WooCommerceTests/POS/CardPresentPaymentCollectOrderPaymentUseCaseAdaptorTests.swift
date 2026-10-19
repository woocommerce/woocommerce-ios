import Combine
import PointOfSale
import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct CardPresentPaymentCollectOrderPaymentUseCaseAdaptorTests {
    @Test func test_cancellation_when_cancelled_on_main_actor_then_event_action_runs_synchronously() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .cancelReconnection(let completion) = action {
                completion(.success(()))
            }
        }
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let adaptor = CardPresentPaymentCollectOrderPaymentUseCaseAdaptor(
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
            paymentEventPublisher: events.eraseToAnyPublisher(),
            stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker()
        )
        let preflightController = MockCardPresentPaymentPreflightController()
        let paymentTask = await withCheckedContinuation { continuation in
            let task = adaptor.collectPaymentTask(
                for: Order.fake().copy(siteID: 123, orderID: 456, currency: "USD", total: "10.00"),
                using: .bluetooth,
                siteID: 123,
                preflightController: preflightController,
                configuration: CardPresentPaymentsConfiguration(country: .US),
                alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor(),
                paymentEventSubject: events,
                channel: .storeManagement
            )
            preflightController.onStart = {
                continuation.resume(returning: task)
            }
        }
        var cancellationActionCount = 0
        events.send(.show(eventDetails: .scanningForReaders(endSearch: {
            cancellationActionCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then: assert before any suspension could run a queued cancellation action.
        #expect(cancellationActionCount == 1)

        // Finish the suspended payment independently, even if the assertion fails.
        preflightController.cancelConnection(readerModel: nil, gatewayID: nil, source: .foundReader)
        let result = try await paymentTask.value
        guard case .cancellation = result else {
            Issue.record("Expected payment cancellation")
            return
        }
        #expect(cancellationActionCount == 1)
    }
}
