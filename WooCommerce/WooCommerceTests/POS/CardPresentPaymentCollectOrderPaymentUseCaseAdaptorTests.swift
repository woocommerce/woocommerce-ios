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

    @Test func test_cancellation_when_cancelled_on_main_actor_during_payment_step_then_cancel_payment_runs_synchronously() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var cancelPaymentCount = 0
        events.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {
            cancelPaymentCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then: assert before any suspension could run a queued cancellation action.
        #expect(cancelPaymentCount == 1)

        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)
        #expect(result == .cancellation)
        #expect(cancelPaymentCount == 1)
    }

    @Test func test_cancellation_when_new_payment_event_arrives_after_cancel_then_only_cancelled_step_is_cancelled() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var cancelledStepCount = 0
        events.send(.show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {
            cancelledStepCount += 1
        })))

        // When
        paymentTask.cancel()
        var laterStepCount = 0
        events.send(.show(eventDetails: .cardInserted(cancelPayment: {
            laterStepCount += 1
        })))
        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)

        // Then
        #expect(cancelledStepCount == 1)
        #expect(laterStepCount == 0)
        #expect(result == .cancellation)
    }

    @Test func test_cancellation_when_reader_update_failed_then_cancels_update() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var tryAgainCount = 0
        var cancelUpdateCount = 0
        events.send(.show(eventDetails: .updateFailed(tryAgain: {
            tryAgainCount += 1
        }, cancelUpdate: {
            cancelUpdateCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then
        #expect(cancelUpdateCount == 1)
        #expect(tryAgainCount == 0)
        _ = try await finishWithCancellation(paymentTask, preflightController: preflightController)
    }

    @Test func test_cancellation_when_reader_update_in_progress_then_cancels_update() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var cancelUpdateCount = 0
        events.send(.show(eventDetails: .updateProgress(requiredUpdate: true, progress: 0.5, cancelUpdate: {
            cancelUpdateCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then
        #expect(cancelUpdateCount == 1)
        _ = try await finishWithCancellation(paymentTask, preflightController: preflightController)
    }

    @Test func test_cancellation_when_location_required_then_runs_cancel() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var cancelCount = 0
        events.send(.show(eventDetails: .locationRequired(cancel: {
            cancelCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then
        #expect(cancelCount == 1)
        _ = try await finishWithCancellation(paymentTask, preflightController: preflightController)
    }
}

private extension CardPresentPaymentCollectOrderPaymentUseCaseAdaptorTests {
    /// Starts the real collect flow and returns once it is waiting on the reader connection.
    func startPayment(events: PassthroughSubject<CardPresentPaymentEvent, Never>)
    async -> (Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>, MockCardPresentPaymentPreflightController) {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .cancelReconnection(let completion) = action {
                completion(.success(()))
            }
        }
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
        return (paymentTask, preflightController)
    }

    /// Cancels the reader connection, which makes the use case report the cancellation and resume the payment.
    func finishWithCancellation(_ paymentTask: Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>,
                                preflightController: MockCardPresentPaymentPreflightController)
    async throws -> CardPresentPaymentAdaptedCollectOrderPaymentResult {
        preflightController.cancelConnection(readerModel: nil, gatewayID: nil, source: .foundReader)
        return try await paymentTask.value
    }
}
