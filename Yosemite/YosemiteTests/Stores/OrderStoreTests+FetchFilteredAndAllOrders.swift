
import XCTest

@testable import Yosemite
@testable import Storage
@testable import Networking

/// Test cases for `OrderStore.fetchFilteredAndAllOrders`
///
final class OrderStoreTests_FetchFilteredAndAllOrders: XCTestCase {
    private var storageManager: MockupStorageManager!
    private var network: MockupNetwork!

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        super.tearDown()
    }

    func testItCanDeleteAllOrdersBeforeSaving() {
        // Arrange
        insert(order: Fixtures.order)
        // Confidence checks
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)

        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(), deleteAllBeforeSaving: true)

        // Assert
        // The previously saved order should be deleted
        XCTAssertNil(findOrder(withID: Fixtures.order.orderID))
        // There should be records saved from the GET /orders query
        XCTAssertEqual(countOrders(), Fixtures.ordersLoadAllJSON.ordersCount)
    }

    func testItCanSkipDeletingAllOrdersBeforeSaving() {
        // Arrange
        insert(order: Fixtures.order)
        // Confidence checks
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)

        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(), deleteAllBeforeSaving: false)

        // Assert
        // The previously saved order should still be there
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        // There should be records saved from the GET /orders query
        XCTAssertEqual(countOrders(), Fixtures.ordersLoadAllJSON.ordersCount + 1)
    }
}

// MARK: - Private

private extension OrderStoreTests_FetchFilteredAndAllOrders {
    func createOrderStore() -> OrderStore {
        OrderStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)
    }

    func executeActionAndWait(using store: OrderStore, deleteAllBeforeSaving: Bool) {
        let expectation = self.expectation(description: "fetch")

        let action = OrderAction.fetchFilteredAndAllOrders(
            siteID: Fixtures.siteID,
            statusKey: OrderStatusEnum.processing.rawValue,
            deleteAllBeforeSaving: deleteAllBeforeSaving,
            pageSize: 50) { _ in
                expectation.fulfill()
        }

        store.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    @discardableResult
    func insert(order: Networking.Order) -> Storage.Order {
        let storageOrder = viewStorage.insertNewObject(ofType: Storage.Order.self)
        storageOrder.update(with: Fixtures.order)
        return storageOrder
    }

    func findOrder(withID orderID: Int64) -> Storage.Order? {
        let predicate = NSPredicate(format: "orderID = %ld", orderID)
        return viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)
    }

    func countOrders() -> Int {
        viewStorage.countObjects(ofType: Storage.Order.self)
    }
}

// MARK: - Fixtures

private enum Fixtures {
    /// Information about the orders-load-all.json
    ///
    static let ordersLoadAllJSON = (
        fileName: "orders-load-all",
        ordersCount: 4
    )

    static let siteID: Int64 = 1_987
    static let order = Networking.Order(
        siteID: siteID,
        orderID: 8_963,
        parentID: 0,
        customerID: 11,
        number: "8963",
        statusKey: "processing",
        currency: "USD",
        customerNote: "",
        dateCreated: Date(),
        dateModified: Date(),
        datePaid: Date(),
        discountTotal: "30.00",
        discountTax: "1.20",
        shippingTotal: "0.00",
        shippingTax: "0.00",
        total: "31.20",
        totalTax: "1.20",
        paymentMethodTitle: "Credit Card (Stripe)",
        items: [],
        billingAddress: nil,
        shippingAddress: nil,
        shippingLines: [],
        coupons: [],
        refunds: []
    )
}
