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

        XCTAssertEqual(UInt(mockOrder.total), parametersProvided?.parameters.amount)
        XCTAssertEqual(mockOrder.currency, parametersProvided?.parameters.currency)
    }

    func test_print_callsPrint_passing_cartTotals() throws {
        let mockParameters = try XCTUnwrap(MockPaymentIntent.mock().receiptParameters())
        let mockOrder = makeOrder()

        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        receiptPrinterService: receiptPrinterService,
                                        fileStorage: MockInMemoryStorage())

        let action = ReceiptAction.print(order: mockOrder, parameters: mockParameters, completion: { _ in })

        receiptStore.onAction(action)

        let contentProvided = receiptPrinterService.contentProvided

        XCTAssertEqual(mockOrder.totalTax, contentProvided?.cartTotals.totalTax)
    }
}


private extension ReceiptStoreTests {
    func makeOrder() -> Networking.Order {
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
              discountTax: "1.21",
              shippingTotal: "",
              shippingTax: "0.50",
              total: "100",
              totalTax: "10.71",
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
