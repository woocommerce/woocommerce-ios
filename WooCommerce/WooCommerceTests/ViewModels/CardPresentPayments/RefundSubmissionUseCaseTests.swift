import Combine
import TestKit
import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

private typealias Dependencies = RefundSubmissionUseCase.Dependencies

final class RefundSubmissionUseCaseTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var alerts: MockOrderDetailsPaymentAlerts!
    private var cardReaderConnectionAlerts: MockCardReaderSettingsAlerts!
    private var knownCardReaderProvider: MockKnownReaderProvider!
    private var onboardingPresenter: MockCardPresentPaymentsOnboardingPresenter!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        alerts = MockOrderDetailsPaymentAlerts()
        cardReaderConnectionAlerts = MockCardReaderSettingsAlerts(mode: .continueSearching)
        knownCardReaderProvider = MockKnownReaderProvider()
        onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        onboardingPresenter = nil
        knownCardReaderProvider = nil
        cardReaderConnectionAlerts = nil
        alerts = nil
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_submitRefund_with_non_interac_payment_method_does_not_dispatch_CardPresentPaymentActions() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .cardPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockServerSideRefund(result: .success(()))

        // When
        waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}) { result in
                promise(())
            }
        }

        // Then
        XCTAssertFalse(stores.receivedActions.contains(where: { $0 is CardPresentPaymentAction }))
    }

    func test_submitRefund_with_interac_payment_method_dispatches_CardPresentPaymentActions() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))

        // When
        useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { _ in })

        // Then
        XCTAssertTrue(stores.receivedActions.contains(where: { $0 is CardPresentPaymentAction }))
    }

    func test_submitRefund_with_non_interac_payment_method_does_not_call_showOnboardingIfRequired() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .cardPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockServerSideRefund(result: .success(()))

        // When
        waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}) { result in
                promise(())
            }
        }

        // Then
        XCTAssertFalse(onboardingPresenter.spyShowOnboardingWasCalled)
    }

    func test_submitRefund_with_interac_payment_method_calls_showOnboardingIfRequired() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))

        // When
        useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { _ in })

        // Then
        XCTAssertTrue(onboardingPresenter.spyShowOnboardingWasCalled)
    }

    func test_submitRefund_without_a_paymentGatewayAccount_in_storage_returns_failure() {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: nil))
        mockCardPresentPaymentActions(clientSideRefundResult: .success(()))

        // When
        let result = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .unknownPaymentGatewayAccount)
    }

    func test_submitRefund_successfully_tracks_interacRefundSuccess_event_when_payment_method_is_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .success(()))
        mockServerSideRefund(result: .success(()))

        // When
        let result = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_success"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }

    func test_submitRefund_successfully_does_not_track_interacRefundSuccess_event_when_payment_method_is_not_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .unknown),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .success(()))
        mockServerSideRefund(result: .success(()))

        // When
        let result = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        XCTAssertFalse(analyticsProvider.receivedEvents.contains("interac_refund_success"))
    }

    func test_submitRefund_with_client_side_success_and_server_side_failure_tracks_interacRefundSuccess_event_when_payment_method_is_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .success(()))
        mockServerSideRefund(result: .failure(RefundSubmissionUseCase.RefundSubmissionError.cardReaderDisconnected))

        // When
        let result = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .cardReaderDisconnected)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_success"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }

    func test_submitRefund_with_client_side_failure_tracks_interacRefundFailed_event_when_payment_method_is_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .failure(RefundSubmissionUseCase.RefundSubmissionError.cardReaderDisconnected))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
            self.alerts.dismissErrorCompletion?()
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .cardReaderDisconnected)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }

    func test_submitRefund_with_client_side_retryable_failure_shows_non_retryable_error_alert() throws {
        // Given
        let shouldRetry = false
        let error = CardReaderServiceError.refundPayment(shouldRetry: shouldRetry)
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .failure(error))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
            self.alerts.dismissErrorCompletion?()
        }

        var theRightFailureResultWasReturned = false
        switch result {
        case let .failure(error):
            if let cardReaderServiceError = error as? CardReaderServiceError,
               case let .refundPayment(_, retry) = cardReaderServiceError {
                theRightFailureResultWasReturned = shouldRetry == retry
            }
        case .success():
            break
        }

        // Then
        XCTAssertTrue(theRightFailureResultWasReturned)
        XCTAssertTrue(self.alerts.nonRetryableErrorWasCalled)
    }

    func test_canceling_scanningForReader_alert_tracks_interacRefundCanceled_event_when_payment_method_is_interac() throws {
        // Given
        let siteID: Int64 = 863
        let useCase = createUseCase(details: .init(order: .fake().copy(siteID: siteID, total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(connectedCardReaders: [])
        // Payment gateway account is required for card reader connection.
        let paymentGatewayAccount = createPaymentGatewayAccount(siteID: siteID)
        storageManager.insertSamplePaymentGatewayAccount(readOnlyAccount: paymentGatewayAccount)

        // When
        cardReaderConnectionAlerts.update(mode: .cancelScanning)
        let result: Result<Void, Error> = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .cardReaderDisconnected)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_cancelled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "")
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }

    func test_canceling_readerIsReady_alert_tracks_interacRefundCanceled_event_when_payment_method_is_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .failure(RefundSubmissionUseCase.RefundSubmissionError.cardReaderDisconnected),
                                      cancelRefundResult: .success(()))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
            self.alerts.cancelReaderIsReadyAlert?()
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .canceledByUser)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_cancelled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }

    func test_canceling_tapOrInsertCard_alert_tracks_interacRefundCanceled_event_when_payment_method_is_interac() throws {
        // Given
        let useCase = createUseCase(details: .init(order: .fake().copy(total: "2.28"),
                                                   charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                    details: .init(brand: .visa,
                                                                   last4: "9969",
                                                                   funding: .credit,
                                                                   receipt: .init(accountType: .credit,
                                                                                  applicationPreferredName: "Stripe Credit",
                                                                                  dedicatedFileName: "A000000003101001")))),
                                                   amount: "2.28",
                                                   paymentGatewayAccount: createPaymentGatewayAccount(siteID: Mocks.siteID)))
        mockCardPresentPaymentActions(clientSideRefundResult: .failure(RefundSubmissionUseCase.RefundSubmissionError.cardReaderDisconnected),
                                      cancelRefundResult: .success(()),
                                      returnCardReaderMessage: .waitingForInput(""))

        // When
        let result: Result<Void, Error> = waitFor { promise in
            useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { result in
                promise(result)
            })
            self.alerts.cancelTapOrInsertCardAlert?()
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? RefundSubmissionUseCase.RefundSubmissionError, .canceledByUser)

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "interac_refund_cancelled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, "US")
        XCTAssertEqual(eventProperties["plugin_slug"] as? String, Mocks.paymentGatewayID)
    }
}

private extension RefundSubmissionUseCaseTests {
    func mockServerSideRefund(result: Result<Void, Error>) {
        stores.whenReceivingAction(ofType: RefundAction.self) { action in
            if case let .createRefund(_, _, _, completion) = action {
                switch result {
                case .success:
                    completion(.fake(), nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
    }

    /// Mocks successful card reader connection and allows mocking for subsequent actions - client-side refund, refund cancellation, and what message
    /// it returns to the card reader.
    /// Because `MockStoresManager.whenReceivingAction` has to include all actions for the same store in one call, default values
    /// are set to optional actions.
    /// - Parameters:
    ///   - connectedCardReaders: an array of connected card readers. Default value is one WisePad 3 reader.
    ///   - clientSideRefundResult: the result of client-side refund on the card reader in `CardPresentPaymentAction.refundPayment`. Default result is success.
    ///   - cancelRefundResult: the result of refund cancellation on the card reader. Default result is success.
    ///   - returnCardReaderMessage: optional message to refund during the client-side refund flow on the card reader in
    ///                             `CardPresentPaymentAction.refundPayment`.
    ///   - cancelCardReaderDiscoveryResult: the result of cancelling reader discovery in `CardPresentPaymentAction.cancelCardReaderDiscovery`.
    ///                                      Default result is success.
    func mockCardPresentPaymentActions(connectedCardReaders: [CardReader] = [MockCardReader.wisePad3()],
                                       clientSideRefundResult: Result<Void, Error> = .success(()),
                                       cancelRefundResult: Result<Void, Error> = .success(()),
                                       returnCardReaderMessage: CardReaderEvent? = nil,
                                       cancelCardReaderDiscoveryResult: Result<Void, Error> = .success(())) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                if connectedCardReaders.isEmpty {
                    // If there are no connected readers, we don't want the publisher to finish which is considered a reader is connected.
                    let subject = CurrentValueSubject<[CardReader], Never>([])
                    completion(subject.eraseToAnyPublisher())
                } else {
                    completion(Just<[CardReader]>(connectedCardReaders).eraseToAnyPublisher())
                }
            } else if case let .observeConnectedReaders(completion) = action {
                completion(connectedCardReaders)
            } else if case let .refundPayment(_, onCardReaderMessage, completion) = action {
                if let cardReaderMessage = returnCardReaderMessage {
                    onCardReaderMessage(cardReaderMessage)
                }
                completion?(clientSideRefundResult)
            } else if case let .cancelRefund(completion) = action {
                completion?(cancelRefundResult)
            } else if case let .cancelCardReaderDiscovery(completion) = action {
                completion(cancelCardReaderDiscoveryResult)
            }
        }
    }

    func createUseCase(details: RefundSubmissionUseCase.Details) -> RefundSubmissionUseCase {
        let dependencies = Dependencies(
            cardReaderConnectionAlerts: cardReaderConnectionAlerts,
            currencyFormatter: CurrencyFormatter(currencySettings: .init()),
            currencySettings: .init(),
            knownReaderProvider: knownCardReaderProvider,
            cardPresentPaymentsOnboardingPresenter:
                onboardingPresenter,
            stores: stores,
            storageManager: storageManager,
            analytics: analytics)

        return RefundSubmissionUseCase(
            details: details,
            rootViewController: .init(),
            alerts: alerts,
            cardPresentConfiguration: Mocks.configuration,
            dependencies: dependencies)
    }

    func createPaymentGatewayAccount(siteID: Int64) -> PaymentGatewayAccount {
        .fake()
        .copy(
            siteID: siteID,
            gatewayID: Mocks.paymentGatewayID,
            status: "complete",
            hasPendingRequirements: false,
            hasOverdueRequirements: false,
            isCardPresentEligible: true,
            isLive: true,
            isInTestMode: false
        )
    }
}

private extension RefundSubmissionUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayID: String = "woocommerce-payments"
        static let siteID: Int64 = 322
    }
}
