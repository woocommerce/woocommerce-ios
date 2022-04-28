import Combine
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class RefundSubmissionUseCaseTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var alerts: MockOrderDetailsPaymentAlerts!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        alerts = MockOrderDetailsPaymentAlerts()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
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
        mockSuccessfulCardReaderConnection(clientSideRefundResult: .success(()))

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
        mockSuccessfulCardReaderConnection(clientSideRefundResult: .success(()))
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
        mockSuccessfulCardReaderConnection(clientSideRefundResult: .success(()))
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
        mockSuccessfulCardReaderConnection(clientSideRefundResult: .success(()))
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
        mockSuccessfulCardReaderConnection(clientSideRefundResult: .failure(RefundSubmissionUseCase.RefundSubmissionError.cardReaderDisconnected))

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

    func mockSuccessfulCardReaderConnection(clientSideRefundResult: Result<Void, Error>) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .checkCardReaderConnected(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .refundPayment(_, _, completion) = action {
                completion?(clientSideRefundResult)
            }
        }
    }

    func createUseCase(details: RefundSubmissionUseCase.Details) -> RefundSubmissionUseCase {
        RefundSubmissionUseCase(details: details,
                                rootViewController: .init(),
                                alerts: alerts,
                                currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                currencySettings: .init(),
                                cardPresentConfiguration: Mocks.configuration,
                                stores: stores,
                                analytics: analytics)
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
