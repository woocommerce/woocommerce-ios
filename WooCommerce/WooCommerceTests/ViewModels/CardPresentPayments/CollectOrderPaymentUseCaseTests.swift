import Combine
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class CollectOrderPaymentUseCaseTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var alerts: MockOrderDetailsPaymentAlerts!
    private var useCase: CollectOrderPaymentUseCase!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        alerts = MockOrderDetailsPaymentAlerts()
        useCase = CollectOrderPaymentUseCase(siteID: 122,
                                             order: .fake().copy(total: "1.5"),
                                             formattedAmount: "1.5",
                                             paymentGatewayAccount: .fake().copy(gatewayID: Mocks.paymentGatewayAccount),
                                             rootViewController: .init(),
                                             alerts: alerts,
                                             configuration: Mocks.configuration,
                                             stores: stores,
                                             analytics: analytics)
    }

    override func tearDown() {
        useCase = nil
        alerts = nil
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_collectPayment_without_reader_connection_does_not_track_collectPaymentTapped_event() {
        // When
        useCase.collectPayment(backButtonTitle: "", onCollect: { _ in }, onCompleted: {})

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("card_present_collect_payment_tapped"))
    }

    func test_collectPayment_tracks_collectPaymentTapped_event() throws {
        // When
        mockCardPresentPaymentActions()
        useCase.collectPayment(backButtonTitle: "", onCollect: { _ in }, onCompleted: {})

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_present_collect_payment_tapped"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }

    func test_cancelling_readerIsReady_alert_triggers_onCompleted_and_tracks_collectPaymentCanceled_event_and_dispatches_cancel_action() throws {
        // Given
        assertEmpty(stores.receivedActions)

        // When
        mockCardPresentPaymentActions()
        let _: Void = waitFor { promise in
            self.useCase.collectPayment(backButtonTitle: "", onCollect: { _ in }, onCompleted: {
                promise(())
            })
            self.alerts.cancelReaderIsReadyAlert?()
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_present_collect_payment_canceled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)

        let action = try XCTUnwrap(stores.receivedActions.last as? CardPresentPaymentAction)
        switch action {
        case .cancelPayment(onCompletion: _):
            XCTAssertTrue(true)
        default:
            XCTFail("Primary button failed to dispatch .cancelPayment action")
        }
    }

    func test_collectPayment_processing_completion_tracks_collectInteracPaymentSuccess_event_when_payment_method_is_interac() throws {
        // Given
        let intent = MockPaymentIntent.mock(paymentMethod: .interacPresent)
        mockSuccessfulCardPresentPaymentActions(intent: intent)

        // When
        waitFor { promise in
            self.useCase.collectPayment(backButtonTitle: "", onCollect: { _ in
                promise(())
            }, onCompleted: {})
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_interac_collect_payment_success"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }

    func test_collectPayment_processing_completion_does_not_track_collectInteracPaymentSuccess_event_when_payment_method_is_not_interac() throws {
        // Given
        let intent = MockPaymentIntent.mock(paymentMethod: .cardPresent)
        mockSuccessfulCardPresentPaymentActions(intent: intent)

        // When
        waitFor { promise in
            self.useCase.collectPayment(backButtonTitle: "", onCollect: { _ in
                promise(())
            }, onCompleted: {})
        }

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("card_interac_collect_payment_success"))
    }

    // MARK: - Failure cases

    func test_collectPayment_with_below_minimum_amount_results_in_failure_and_tracks_collectPaymentFailed_event() throws {
        // Given
        let useCase = CollectOrderPaymentUseCase(siteID: 122,
                                                 order: .fake().copy(total: "0.49"),
                                                 formattedAmount: "0.49",
                                                 paymentGatewayAccount: .fake().copy(gatewayID: Mocks.paymentGatewayAccount),
                                                 rootViewController: .init(),
                                                 alerts: alerts,
                                                 configuration: Mocks.configuration,
                                                 stores: stores,
                                                 analytics: analytics)

        // When
        // Mocks card reader connection success since the minimum amount is only checked after reader connection success.
        mockCardPresentPaymentActions()
        var result: Result<Void, Error>? = nil
        let _: Void = waitFor { [weak self] promise in
            useCase.collectPayment(backButtonTitle: "", onCollect: { collectPaymentResult in
                result = collectPaymentResult
            }, onCompleted: {
                promise(())
            })
            // Dismisses error to complete the payment flow for `onCollect` to be triggered.
            self?.alerts.dismissErrorCompletion?()
        }

        // Then
        XCTAssertNotNil(result?.failure as? PaymentCaptureOrchestrator.NotValidAmountError)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_present_collect_payment_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }
}

private extension CollectOrderPaymentUseCaseTests {
    func mockCardPresentPaymentActions() {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .checkCardReaderConnected(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .cancelPayment(completion) = action {
                completion?(.success(()))
            }
        }
    }

    func mockSuccessfulCardPresentPaymentActions(intent: PaymentIntent) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .checkCardReaderConnected(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .collectPayment(_, _, _, _, onProcessingCompletion, onCompletion) = action {
                onProcessingCompletion(intent)
                onCompletion(.success(intent))
            } else if case let .captureOrderPayment(_, _, _, completion) = action {
                completion(.success(()))
            }
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
