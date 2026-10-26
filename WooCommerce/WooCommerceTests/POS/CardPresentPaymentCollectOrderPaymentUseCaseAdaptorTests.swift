import Combine
import os
import PointOfSale
import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct CardPresentPaymentCollectOrderPaymentUseCaseAdaptorTests {
    @Test func test_cancellation_when_cancelled_on_main_actor_then_event_action_runs_synchronously() async throws {
        // Given
        let events = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let (paymentTask, preflightController) = await startPayment(events: events)
        var cancellationActionCount = 0
        events.send(.show(eventDetails: .scanningForReaders(endSearch: {
            cancellationActionCount += 1
        })))

        // When
        paymentTask.cancel()

        // Then: assert before any suspension could run a queued cancellation action.
        #expect(cancellationActionCount == 1)

        // Finish the suspended payment independently, even if the assertion fails.
        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)
        #expect(result == .cancellation)
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

        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)
        #expect(result == .cancellation)
        #expect(cancelUpdateCount == 1)
        #expect(tryAgainCount == 0)
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

        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)
        #expect(result == .cancellation)
        #expect(cancelUpdateCount == 1)
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

        let result = try await finishWithCancellation(paymentTask, preflightController: preflightController)
        #expect(result == .cancellation)
        #expect(cancelCount == 1)
    }

    @Test func test_cancellation_when_cancelled_while_validating_order_then_stale_validation_presents_no_payment_error() async throws {
        // Given
        let alertsPresenter = CardPresentPaymentsAlertPresenterAdaptor()
        var presentedEvents: [CardPresentPaymentEvent] = []
        let pendingValidation = OSAllocatedUnfairLock<(@MainActor @Sendable () -> Void)?>(initialState: nil)
        let order = Order.fake().copy(siteID: 123, orderID: 456, currency: "USD", total: "10.00")
        var retrieveOrderCompletion: ((Result<Order, Error>) -> Void)?
        let stores = makeStores()
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case .retrieveOrderRemotely(_, _, let completion) = action {
                retrieveOrderCompletion = completion
            }
        }
        let (paymentTask, preflightController) = await startPayment(events: PassthroughSubject(),
                                                                     order: order,
                                                                     stores: stores,
                                                                     alertsPresenter: alertsPresenter,
                                                                     scheduleOrderValidation: { operation in
                                                                         pendingValidation.withLock { $0 = operation }
                                                                     })
        preflightController.completeConnection(reader: MockCardReader.bbposChipper2XBT(), gatewayID: WCPayAccount.gatewayID)
        let completeOrderRetrieval = try #require(retrieveOrderCompletion)

        // When
        let subscription = alertsPresenter.paymentEventPublisher.sink { event in
            presentedEvents.append(event)
        }
        defer { subscription.cancel() }

        paymentTask.cancel()
        completeOrderRetrieval(.success(order))
        let handleValidation = try #require(pendingValidation.withLock { $0 })
        handleValidation()

        // Then
        let leakedPaymentErrorDismissals = presentedEvents.compactMap { event -> (@MainActor @Sendable () -> Void)? in
            guard case .show(.paymentError(_, _, let dismiss)) = event else { return nil }
            return dismiss
        }
        #expect(leakedPaymentErrorDismissals.isEmpty)

        leakedPaymentErrorDismissals.forEach { $0() }
        let result = try await paymentTask.value
        #expect(result == .cancellation)
    }
}

private extension CardPresentPaymentCollectOrderPaymentUseCaseAdaptorTests {
    func makeStores() -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case .cancelReconnection(let completion):
                completion(.success(()))
            case .cancelPayment(let completion):
                completion?(.failure(CardReaderServiceError.paymentCancellation(underlyingError: .noActivePaymentIntent)))
            default:
                break
            }
        }
        return stores
    }

    /// Starts the real collect flow and returns once it is waiting on the reader connection.
    func startPayment(events: PassthroughSubject<CardPresentPaymentEvent, Never>,
                      order: Order = Order.fake().copy(siteID: 123, orderID: 456, currency: "USD", total: "10.00"),
                      stores: MockStoresManager? = nil,
                      alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor? = nil,
                      scheduleOrderValidation: @escaping @Sendable (@escaping @MainActor @Sendable () -> Void) -> Void = { operation in
                          Task { @MainActor in operation() }
                      })
    async -> (Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>, MockCardPresentPaymentPreflightController) {
        let stores = stores ?? makeStores()
        let alertsPresenter = alertsPresenter ?? CardPresentPaymentsAlertPresenterAdaptor()
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let adaptor = CardPresentPaymentCollectOrderPaymentUseCaseAdaptor(
            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
            paymentEventPublisher: events.merge(with: alertsPresenter.paymentEventPublisher).eraseToAnyPublisher(),
            stores: stores,
            collectOrderPaymentAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker(),
            applicationStateProvider: { .active },
            scheduleOrderValidation: scheduleOrderValidation
        )
        let preflightController = MockCardPresentPaymentPreflightController()
        let paymentTask = await withCheckedContinuation { continuation in
            let task = adaptor.collectPaymentTask(
                for: order,
                using: .bluetooth,
                siteID: 123,
                preflightController: preflightController,
                configuration: CardPresentPaymentsConfiguration(country: .US),
                alertsPresenter: alertsPresenter,
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
