import Codegen
import Combine
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class CollectOrderPaymentUseCaseTests: XCTestCase {
    private let defaultSiteID: Int64 = 122
    private let defaultOrderID: Int64 = 322

    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var alerts: MockOrderDetailsPaymentAlerts!
    private var onboardingPresenter: MockCardPresentPaymentsOnboardingPresenter!
    private var mockPreflightController: MockCardPresentPaymentPreflightController!
    private var mockAnalyticsTracker: MockCardPaymentAnalyticsTracker!
    private var useCase: CollectOrderPaymentUseCase!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        mockAnalyticsTracker = MockCardPaymentAnalyticsTracker()
        onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()

        alerts = MockOrderDetailsPaymentAlerts() // Update to CardPresentPaymentAlertsPresenting
        mockPreflightController = MockCardPresentPaymentPreflightController()
        useCase = CollectOrderPaymentUseCase(siteID: defaultSiteID,
                                             order: .fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5"),
                                             formattedAmount: "1.5",
                                             rootViewController: .init(),
                                             onboardingPresenter: onboardingPresenter,
                                             configuration: Mocks.configuration,
                                             stores: stores,
                                             paymentCaptureCelebration: MockPaymentCaptureCelebration(),
                                             preflightController: mockPreflightController,
                                             analyticsTracker: mockAnalyticsTracker,
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

    func test_cancelling_reader_connection_triggers_onCancel_and_tracks_collectPaymentCanceled_event() throws {
        // Given
        assertEmpty(stores.receivedActions)

        // When
//        mockCardPresentPaymentActions()
//        throw XCTSkip("Until we mock preflight, nothing will trigger `onCancel` yet in tests")

        let _: Void = waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.cancelConnection(readerModel: Mocks.cardReaderModel, gatewayID: Mocks.paymentGatewayAccount, source: .foundReader)
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_present_collect_payment_canceled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }

    func test_collectPayment_processing_completion_tracks_collectInteracPaymentSuccess_event_when_payment_method_is_interac() throws {
        // Given
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)

        // When
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` in tests")
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onCompleted: {
                promise(())
            })
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
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)

        // When
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` yet in tests")
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onCompleted: {
                promise(())
            })
        }

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("card_interac_collect_payment_success"))
    }

    // MARK: Success alert actions
    func test_emailing_receipt_from_collectPayment_success_alert_tracks_receiptEmailTapped_event() throws {
        // Given
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)

        // When
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` yet in tests")
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onCompleted: {
                promise(())
            })
        }
        alerts.emailReceiptFromSuccessAlert?()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_tapped"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
    }

    // MARK: - Failure cases

    func test_collectPayment_with_below_minimum_amount_results_in_failure_and_tracks_collectPaymentFailed_event() throws {
        // Given
        let useCase = CollectOrderPaymentUseCase(siteID: 122,
                                                 order: .fake().copy(total: "0.49"),
                                                 formattedAmount: "0.49",
                                                 rootViewController: .init(),
                                                 onboardingPresenter: onboardingPresenter,
                                                 configuration: Mocks.configuration,
                                                 stores: stores,
                                                 paymentCaptureCelebration: MockPaymentCaptureCelebration(),
                                                 analytics: analytics)

        // When
        // Mocks card reader connection success since the minimum amount is only checked after reader connection success.
        mockCardPresentPaymentActions()
        var result: Error? = nil
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` yet in tests")
        let _: Void = waitFor { [weak self] promise in
            useCase.collectPayment(
                using: .bluetoothScan,
                onFailure: { error in
                    result = error
                },
                onCancel: {},
                onCompleted: {
                    promise(())
                })
            // Dismisses error to complete the payment flow for `onCollect` to be triggered.
            self?.alerts.dismissErrorCompletion?()
        }

        // Then
        XCTAssertNotNil(result as? CollectOrderPaymentUseCase.NotValidAmountError)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "card_present_collect_payment_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }

    func test_collectPayment_with_interac_dispatches_markOrderAsPaidLocally_after_successful_client_side_capture() throws {
        // Given
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .markOrderAsPaidLocally(siteID, orderID, _, _) = action {
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
            }
        }

        // When
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` yet in tests")
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onCompleted: {
                promise(())
            })
        }

        // Then
        let action = try XCTUnwrap(markOrderAsPaidLocallyAction)
        XCTAssertEqual(action.siteID, defaultSiteID)
        XCTAssertEqual(action.orderID, defaultOrderID)
    }

    func test_collectPayment_with_noninterac_does_not_dispatch_markOrderAsPaidLocally_after_successful_client_side_capture() throws {
        // Given
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .markOrderAsPaidLocally(siteID, orderID, _, _) = action {
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
            }
        }

        // When
        throw XCTSkip("Until we mock preflight, nothing will trigger `onCompleted` yet in tests")
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onCompleted: {
                promise(())
            })
        }

        // Then
        XCTAssertNil(markOrderAsPaidLocallyAction)
    }
}

private extension CollectOrderPaymentUseCaseTests {
    func mockCardPresentPaymentActions() {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .cancelPayment(completion) = action {
                completion?(.success(()))
            } else if case let .collectPayment(_, _, _, onCardReaderMessage, _, _) = action {
                onCardReaderMessage(.waitingForInput([]))
            }
        }

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .synchronizeSystemPlugins(_, let completion):
                completion(.success(()))
            default:
                break
            }
        }
    }

    func mockSuccessfulCardPresentPaymentActions(intent: PaymentIntent) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .collectPayment(_, _, _, _, onProcessingCompletion, onCompletion) = action {
                onProcessingCompletion(intent)
                onCompletion(.success(intent))
            }
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US")
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
