import XCTest
import TestKit
import Yosemite
import Hardware

@testable import WooCommerce

final class ReceiptActionCoordinatorTests: XCTestCase {
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()

        storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
    }

    override func tearDown() {
        storesManager = nil
    }

    func test_printReceipt_logs_receiptPrintTapped_analyticEvent() async throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let order = MockOrders().makeOrder()
        let params = CardPresentReceiptParameters.makeParams()

        storesManager.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .print(_, _, completion):
                completion(.success)
            default:
                break
            }
        }

        // When
        await ReceiptActionCoordinator.printReceipt(for: order,
                                              params: params,
                                              countryCode: "CA",
                                              cardReaderModel: "WISEPAD_3",
                                              stores: storesManager,
                                              analytics: WooAnalytics(analyticsProvider: analytics))

        // Then
        let indexOfEvent = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == WooAnalyticsStat.receiptPrintTapped.rawValue}))
        let eventProperties = try XCTUnwrap(analytics.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "WISEPAD_3")
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
    }

    func test_printReceipt_sends_print_receiptAction() async throws {
        // Given
        let order = MockOrders().makeOrder()
        let params = CardPresentReceiptParameters.makeParams()

        storesManager.reset()

        assertEmpty(storesManager.receivedActions)

        storesManager.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .print(_, _, completion):
                completion(.success)
            default:
                break
            }
        }

        // When
        await ReceiptActionCoordinator.printReceipt(for: order,
                                              params: params,
                                              countryCode: "CA",
                                              cardReaderModel: nil,
                                              stores: storesManager, analytics: ServiceLocator.analytics)

        //Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ReceiptAction)
        switch action {
        case .print(let actionOrder, let actionParams, completion: _):
            XCTAssertEqual(actionOrder, order)
            XCTAssertEqual(actionParams, params)
        default:
            XCTFail("Print Receipt failed to dispatch .print action")
        }
    }

    func test_printReceipt_success_logs_receiptPrintSuccess_analyticEvent() async throws {
        try await assertAnalyticLogged(.receiptPrintSuccess, for: .success)
    }

    func test_printReceipt_cancel_logs_receiptPrintCanceled_analyticEvent() async throws {
        try await assertAnalyticLogged(.receiptPrintCanceled, for: .cancel)
    }

    func test_printReceipt_fail_logs_receiptPrintFailed_analyticEvent() async throws {
        let error = NSError(domain: "errordomain", code: 123, userInfo: nil)
        try await assertAnalyticLogged(.receiptPrintFailed, for: .failure(error))
    }
}

extension ReceiptActionCoordinatorTests {
    func assertAnalyticLogged(_ analytic: WooAnalyticsStat, for printingResult: PrintingResult) async throws {
        // Given
        let order = MockOrders().makeOrder()
        let params = CardPresentReceiptParameters.makeParams()
        let countryCode = "CA"
        let cardReaderModel = "test_reader"


        let analytics = MockAnalyticsProvider()

        storesManager.whenReceivingAction(ofType: ReceiptAction.self) { action in
            switch action {
            case let .print(_, _, completion):
                completion(printingResult)
            default:
                break
            }
        }

        // When
        await ReceiptActionCoordinator.printReceipt(for: order,
                                              params: params,
                                              countryCode: "CA",
                                              cardReaderModel: cardReaderModel,
                                              stores: storesManager,
                                              analytics: WooAnalytics(analyticsProvider: analytics))

        // Then
        let indexOfEvent = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == analytic.rawValue}))
        let eventProperties = try XCTUnwrap(analytics.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, cardReaderModel)
        XCTAssertEqual(eventProperties["country"] as? String, countryCode)
    }
}

extension CardPresentReceiptParameters {
    static func makeParams(amount: UInt = 123,
                           formattedAmount: String = "0.00",
                           currency: String = "USD",
                           date: Date = Date(timeIntervalSince1970: TimeInterval(1630000000)), //Thu Aug 26 2021 17:46:40 GMT+0000
                           storeName: String? = "My store",
                           cardDetails: CardPresentTransactionDetails = CardPresentTransactionDetails.makeDetails(),
                           orderID: Int64? = 12345) -> CardPresentReceiptParameters {
        CardPresentReceiptParameters(amount: amount,
                                     formattedAmount: formattedAmount,
                                     currency: currency,
                                     date: date,
                                     storeName: storeName,
                                     cardDetails: cardDetails,
                                     orderID: orderID)
    }
}

extension CardPresentTransactionDetails {
    static func makeDetails(last4: String = "0000",
                            expMonth: Int = 1,
                            expYear: Int = 31,
                            cardholderName: String? = nil,
                            brand: CardBrand = .unknown,
                            fingerprint: String = "y29834",
                            generatedCard: String? = "1230",
                            receipt: ReceiptDetails? = nil,
                            emvAuthData: String? = nil) -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: last4,
                                      expMonth: expMonth,
                                      expYear: expYear,
                                      cardholderName: cardholderName,
                                      brand: brand,
                                      fingerprint: fingerprint,
                                      generatedCard: generatedCard,
                                      receipt: receipt,
                                      emvAuthData: emvAuthData)
    }
}
