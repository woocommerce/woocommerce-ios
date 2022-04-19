import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class RefundSubmissionUseCaseTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var alerts: MockOrderDetailsPaymentAlerts!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        alerts = MockOrderDetailsPaymentAlerts()
    }

    override func tearDown() {
        alerts = nil
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_submitRefund_with_non_interac_payment_method_does_not_dispatch_CardPresentPaymentActions() throws {
        // Given
        let useCase = RefundSubmissionUseCase(siteID: 322,
                                              details: .init(order: .fake().copy(total: "2.28"),
                                                             charge: .fake().copy(paymentMethodDetails: .cardPresent(
                                                                details: .init(brand: .visa,
                                                                               last4: "9969",
                                                                               funding: .credit,
                                                                               receipt: .init(accountType: .credit,
                                                                                              applicationPreferredName: "Stripe Credit",
                                                                                              dedicatedFileName: "A000000003101001")))),
                                                             amount: "2.28"),
                                              rootViewController: .init(),
                                              alerts: alerts,
                                              currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                              currencySettings: .init(),
                                              stores: stores,
                                              analytics: analytics)
        mockCreateRefundAction(result: .success(()))

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
        let useCase = RefundSubmissionUseCase(siteID: 322,
                                              details: .init(order: .fake().copy(total: "2.28"),
                                                             charge: .fake().copy(paymentMethodDetails: .interacPresent(
                                                                details: .init(brand: .visa,
                                                                               last4: "9969",
                                                                               funding: .credit,
                                                                               receipt: .init(accountType: .credit,
                                                                                              applicationPreferredName: "Stripe Credit",
                                                                                              dedicatedFileName: "A000000003101001")))),
                                                             amount: "2.28"),
                                              rootViewController: .init(),
                                              alerts: alerts,
                                              currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                              currencySettings: .init(),
                                              stores: stores,
                                              analytics: analytics)

        // When
        useCase.submitRefund(.fake(), showInProgressUI: {}, onCompletion: { _ in })

        // Then
        XCTAssertTrue(stores.receivedActions.contains(where: { $0 is CardPresentPaymentAction }))
    }
}

private extension RefundSubmissionUseCaseTests {
    func mockCreateRefundAction(result: Result<Void, Error>) {
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
}

private extension RefundSubmissionUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
