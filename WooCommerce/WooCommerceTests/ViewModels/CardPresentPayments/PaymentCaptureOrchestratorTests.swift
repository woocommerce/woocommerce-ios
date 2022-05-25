import Combine
import XCTest
import Yosemite
@testable import WooCommerce

final class PaymentCaptureOrchestratorTests: XCTestCase {

    private var stores: MockStoresManager!
    private var sut: PaymentCaptureOrchestrator!
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        sut = PaymentCaptureOrchestrator(stores: stores,
                                         paymentReceiptEmailParameterDeterminer: MockReceiptEmailParameterDeterminer())
    }

    override func tearDown() {
        super.tearDown()
        stores = nil
        sut = nil
    }

    func test_collectPayment_for_a_payment_to_a_US_gateway_account_does_not_include_applicationFee_in_the_payment_intent() throws {
        // Given
        let account = PaymentGatewayAccount.fake().copy(siteID: sampleSiteID,
                                                        defaultCurrency: "USD",
                                                        supportedCurrencies: ["USD"],
                                                        country: "US",
                                                        isCardPresentEligible: true)
        let order = Order.fake().copy(siteID: sampleSiteID, currency: "USD")
        let orderTotal: NSDecimalNumber = 150

        // When
        let parameters: PaymentParameters = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .collectPayment(_, _, parameters, _, _, _) = action {
                    promise(parameters)
                }
            }

            self.sut.collectPayment(
                for: order,
                orderTotal: orderTotal,
                paymentGatewayAccount: account,
                paymentMethodTypes: ["card_present"],
                stripeSmallestCurrencyUnitMultiplier: 100,
                onWaitingForInput: {},
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        XCTAssertNil(parameters.applicationFee)
    }

    func test_collectPayment_for_a_payment_to_a_CA_gateway_account_includes_15cents_applicationFee_in_the_payment_intent() throws {
        // Given
        let account = PaymentGatewayAccount.fake().copy(siteID: sampleSiteID,
                                                        defaultCurrency: "CAD",
                                                        supportedCurrencies: ["CAD"],
                                                        country: "CA",
                                                        isCardPresentEligible: true)
        let order = Order.fake().copy(siteID: sampleSiteID, currency: "CAD")
        let orderTotal: NSDecimalNumber = 150

        // When
        let parameters: PaymentParameters = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .collectPayment(_, _, parameters, _, _, _) = action {
                    promise(parameters)
                }
            }

            self.sut.collectPayment(
                for: order,
                orderTotal: orderTotal,
                paymentGatewayAccount: account,
                paymentMethodTypes: ["card_present"],
                stripeSmallestCurrencyUnitMultiplier: 100,
                onWaitingForInput: {},
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        let expectedFee = NSDecimalNumber(string: "0.15").decimalValue
        assertEqual(expectedFee, parameters.applicationFee)
    }

    func test_retryPaymentCapture_successfully_returns_paymentIntent_from_CardPresentPaymentAction_capturePayment() throws {
        // Given
        let paymentIntent = PaymentIntent.fake()
        let paymentIntentOnSuccess = paymentIntent.copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))])
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .capturePayment(_, _, _, onCompletion) = action {
                onCompletion(Just<Result<PaymentIntent, Error>>(.success(paymentIntentOnSuccess)).eraseToAnyPublisher())
            }
        }

        // When
        let result: Result<CardPresentCapturedPaymentData, Error> = waitFor { promise in
            self.sut.retryPaymentCapture(order: .fake(),
                                         paymentIntent: paymentIntent) { result in
                promise(result)
            }
        }

        // Then
        let paymentData = try XCTUnwrap(result.get())
        XCTAssertEqual(paymentData.paymentMethod, .interacPresent(details: .fake()))
    }
}

struct MockReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer {
    func receiptEmail(from order: Order, onCompletion: @escaping ((Result<String?, Error>) -> Void)) {
        onCompletion(.success(nil))
    }
}
