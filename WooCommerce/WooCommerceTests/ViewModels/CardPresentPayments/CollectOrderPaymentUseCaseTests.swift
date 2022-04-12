import Combine
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class CollectOrderPaymentUseCaseTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_cancelling_readerIsReady_tracks_collectPaymentCanceled_event() throws {
        // Given
        let alerts = MockOrderDetailsPaymentAlerts()
        let useCase = CollectOrderPaymentUseCase(siteID: 122,
                                                 order: .fake().copy(total: "1.5"),
                                                 formattedAmount: "1.5",
                                                 paymentGatewayAccount: .fake().copy(gatewayID: Mocks.paymentGatewayAccount),
                                                 rootViewController: .init(),
                                                 alerts: alerts,
                                                 configuration: Mocks.configuration,
                                                 stores: stores,
                                                 analytics: analytics)

        // When
        mockCardPresentPaymentActions()
        useCase.collectPayment(backButtonTitle: "", onCollect: { _ in }, onCompleted: {})
        alerts.cancelReaderIsReadyAlert?()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("card_present_collect_payment_canceled"))

        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["card_reader_model"] as? String, Mocks.cardReaderModel)
        XCTAssertEqual(firstPropertiesBatch["country"] as? String, "US")
        XCTAssertEqual(firstPropertiesBatch["plugin_slug"] as? String, Mocks.paymentGatewayAccount)
    }

    func test_cancelling_readerIsReady_dispatches_cancel_action() throws {
        // Given
        let alerts = MockOrderDetailsPaymentAlerts()
        let useCase = CollectOrderPaymentUseCase(siteID: 122,
                                                 order: .fake(),
                                                 formattedAmount: "1.5",
                                                 paymentGatewayAccount: .fake().copy(gatewayID: Mocks.paymentGatewayAccount),
                                                 rootViewController: .init(),
                                                 alerts: alerts,
                                                 configuration: Mocks.configuration,
                                                 stores: stores,
                                                 analytics: analytics)
        assertEmpty(stores.receivedActions)

        // When
        mockCardPresentPaymentActions()
        useCase.collectPayment(backButtonTitle: "", onCollect: { _ in }, onCompleted: {})
        alerts.cancelReaderIsReadyAlert?()

        // Then
        let action = try XCTUnwrap(stores.receivedActions.last as? CardPresentPaymentAction)
        switch action {
        case .cancelPayment(onCompletion: _):
            XCTAssertTrue(true)
        default:
            XCTFail("Primary button failed to dispatch .cancelPayment action")
        }
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
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
