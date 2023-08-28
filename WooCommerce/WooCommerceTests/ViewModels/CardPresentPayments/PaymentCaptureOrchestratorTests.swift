import XCTest
import Yosemite
@testable import WooCommerce

final class PaymentCaptureOrchestratorTests: XCTestCase {

    private var stores: MockStoresManager!
    private var sessionManager: SessionManager!
    private var sut: PaymentCaptureOrchestrator!
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        sessionManager = SessionManager.makeForTesting(defaultSite: .fake().copy(
            siteID: sampleSiteID,
            name: "AwesomeStore"))
        stores = MockStoresManager(sessionManager: sessionManager)
        sut = PaymentCaptureOrchestrator(stores: stores,
                                         paymentReceiptEmailParameterDeterminer: MockReceiptEmailParameterDeterminer(),
                                         celebration: MockPaymentCaptureCelebration())
    }

    override func tearDown() {
        super.tearDown()
        stores = nil
        sut = nil
    }

    func test_collect_payment_starts_payment_for_correct_site() {
        // Given
        let order = Order.fake().copy(siteID: 12391)
        let orderTotal: NSDecimalNumber = 150

        // When
        let paymentSiteID = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .collectPayment(siteID, _, _, _, _, _) = action {
                    promise(siteID)
                }
            }

            self.sut.collectPayment(
                for: order,
                orderTotal: orderTotal,
                paymentGatewayAccount: PaymentGatewayAccount.fake(),
                paymentMethodTypes: ["card_present"],
                stripeSmallestCurrencyUnitMultiplier: 100,
                onPreparingReader: {},
                onWaitingForInput: { _ in },
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        assertEqual(12391, paymentSiteID)
    }

    func test_collect_payment_starts_payment_for_correct_order() {
        // Given
        let order = Order.fake().copy(orderID: 9283)
        let orderTotal: NSDecimalNumber = 150

        // When
        let paymentOrderID = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .collectPayment(_, orderID, _, _, _, _) = action {
                    promise(orderID)
                }
            }

            self.sut.collectPayment(
                for: order,
                orderTotal: orderTotal,
                paymentGatewayAccount: PaymentGatewayAccount.fake(),
                paymentMethodTypes: ["card_present"],
                stripeSmallestCurrencyUnitMultiplier: 100,
                onPreparingReader: {},
                onWaitingForInput: { _ in },
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        assertEqual(9283, paymentOrderID)
    }

    func test_collect_payment_starts_payment_with_valid_parameters() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID,
                                      orderID: 293,
                                      number: "482",
                                      currency: "USD",
                                      billingAddress: .fake().copy(
                                        firstName: "Bob",
                                        lastName: "Smith",
                                        email: "bob.smith@example.com"))
        let orderTotal: NSDecimalNumber = 150
        sessionManager.defaultSite = Site.fake().copy(siteID: sampleSiteID, name: "AwesomeStore")

        // When
        let paymentParameters = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
                if case let .collectPayment(_, _, parameters, _, _, _) = action {
                    promise(parameters)
                }
            }

            self.sut.collectPayment(
                for: order,
                orderTotal: orderTotal,
                paymentGatewayAccount: PaymentGatewayAccount.fake(),
                paymentMethodTypes: ["card_present"],
                stripeSmallestCurrencyUnitMultiplier: 100,
                onPreparingReader: {},
                onWaitingForInput: { _ in },
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        let expectedParameters = PaymentParameters(
            amount: Decimal(150),
            currency: "USD",
            stripeSmallestCurrencyUnitMultiplier: 100,
            applicationFee: nil,
            receiptDescription: "In-Person Payment for Order #482 for AwesomeStore blog_id \(sampleSiteID)",
            statementDescription: "",
            receiptEmail: "bob.smith@example.com",
            paymentMethodTypes: ["card_present"],
            metadata: PaymentIntent.initMetadata(
                store: "AwesomeStore",
                customerName: "Bob Smith",
                customerEmail: "bob.smith@example.com",
                siteURL: "", // Could not test this: when set on the default site, it gets reset to an empty string.
                orderID: 293,
                paymentType: .single))
        assertEqual(expectedParameters, paymentParameters)
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
                onPreparingReader: {},
                onWaitingForInput: { _ in },
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
                onPreparingReader: {},
                onWaitingForInput: { _ in },
                onProcessingMessage: {},
                onDisplayMessage: { _ in },
                onProcessingCompletion: { _ in },
                onCompletion: { _ in })
        }

        // Then
        let expectedFee = NSDecimalNumber(string: "0.15").decimalValue
        assertEqual(expectedFee, parameters.applicationFee)
    }
}

struct MockReceiptEmailParameterDeterminer: ReceiptEmailParameterDeterminer {
    func receiptEmail(from order: Order) -> String? {
        return order.billingAddress?.email
    }
}
