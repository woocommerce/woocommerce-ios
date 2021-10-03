import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking
@testable import Hardware

/// RefundStore Unit Tests
///
final class ReceiptStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock receipt printing service.
    private var receiptPrinterService: MockReceiptPrinterService!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        receiptPrinterService = MockReceiptPrinterService()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        receiptPrinterService = nil

        super.tearDown()
    }

    func test_print_calls_print_in_service() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        XCTAssertTrue(receiptPrinterService.printWasCalled)
    }

    func test_print_calls_print_in_passing_expected_parameters() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        let parametersProvided = receiptPrinterService.contentProvided

        XCTAssertEqual(mockParameters.amount, parametersProvided?.parameters.amount)
        XCTAssertEqual(mockOrder.currency, parametersProvided?.parameters.currency)
        XCTAssertEqual("100.00", parametersProvided?.parameters.formattedAmount)
    }

    func test_print_callsPrint_passing_TotalAmountPaid() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        let amountPaidLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.amountPaidLineDescription
        }
        XCTAssertEqual("100.00", amountPaidLine?.amount)
    }

    func test_print_callsPrint_passing_TotalTaxes() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder(discountTax: "1.21", shippingTax: "0.50", totalTax: "10.71")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        let actualTaxLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.totalTaxLineDescription
        }
        XCTAssertEqual(mockOrder.totalTax, actualTaxLine?.amount)
    }

    func test_print_OrderWithoutTaxes_DoesNotIncludeTaxesInReceiptContent() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder(totalTax: "0.00")

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        let actualTaxLine = receiptPrinterService.contentProvided?.cartTotals.first {
            $0.description == ReceiptContent.Localization.totalTaxLineDescription
        }
        XCTAssertNil(actualTaxLine)
    }
}


private extension ReceiptStoreTests {
    func makeOrder(discountTax: String = "",
                   shippingTax: String = "",
                   totalTax: String = "") -> Networking.Order {
        Order(siteID: 1234,
              orderID: 0,
              parentID: 0,
              customerID: 0,
              number: "",
              status: .custom(""),
              currency: "usd",
              customerNote: nil,
              dateCreated: Date(),
              dateModified: Date(),
              datePaid: nil,
              discountTotal: "",
              discountTax: discountTax,
              shippingTotal: "",
              shippingTax: shippingTax,
              total: "100.00",
              totalTax: totalTax,
              paymentMethodID: "",
              paymentMethodTitle: "",
              items: [],
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [],
              fees: [])
    }
}
