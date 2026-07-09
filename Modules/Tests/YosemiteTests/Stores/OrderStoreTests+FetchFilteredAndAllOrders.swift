
import XCTest

import YosemiteTestHelpers
@testable import Yosemite
@testable import Storage
@testable import Networking

/// Test cases for `OrderStore.fetchFilteredOrders`
///
final class OrderStoreTests_FetchFilteredAndAllOrders: XCTestCase {
    private var storageManager: MockStorageManager!

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func testItCanDeleteAllOrdersBeforeSaving() {
        // Arrange
        insert(order: Fixtures.order)
        // Confidence checks
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)

        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: [OrderStatusEnum.processing.rawValue],
                             writeStrategy: .deleteAllBeforeSaving)

        // Assert
        // The previously saved order should be deleted
        XCTAssertNil(findOrder(withID: Fixtures.order.orderID))
        // There should be records saved from the GET /orders query
        XCTAssertEqual(countOrders(), Fixtures.ordersLoadAllJSON.ordersCount)
    }

    /// `OrderDetailsViewController` relies on the delete + re-insert of a `deleteAllBeforeSaving` sync
    /// landing in a single save: its `EntityListener.onDelete` handler re-syncs only when the
    /// replacement order is already queryable when the deletion is observed, which holds because both
    /// changes merge into the view context as one change notification. Splitting them into separate
    /// saves would silently break that pairing, so this test pins the single-save behavior.
    ///
    func test_fetchFilteredOrders_when_deleting_all_before_saving_then_it_writes_in_a_single_save() {
        // Given
        let saveCountingStorageManager = SaveCountingStorageManager()
        let storageManager: StorageManagerType = saveCountingStorageManager
        let storageOrder = storageManager.viewStorage.insertNewObject(ofType: Storage.Order.self)
        storageOrder.update(with: Fixtures.order)

        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)
        let store = OrderStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)

        // When
        executeActionAndWait(using: store,
                             statuses: [OrderStatusEnum.processing.rawValue],
                             writeStrategy: .deleteAllBeforeSaving)

        // Then
        // The deletion of all stored orders and the insertion of the fetched orders happen in
        // one `performAndSave` operation, i.e. a single save.
        XCTAssertEqual(saveCountingStorageManager.performAndSaveCallCount, 1)
        XCTAssertNil(storageManager.viewStorage.firstObject(ofType: Storage.Order.self,
                                                            matching: NSPredicate(format: "orderID = %ld", Fixtures.order.orderID)))
        XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: Storage.Order.self), Fixtures.ordersLoadAllJSON.ordersCount)
    }

    func testItCanSkipDeletingAllOrdersBeforeSaving() {
        // Arrange
        insert(order: Fixtures.order)
        // Confidence checks
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)

        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: [OrderStatusEnum.processing.rawValue],
                             writeStrategy: .save)

        // Assert
        // The previously saved order should still be there
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        // There should be records saved from the GET /orders query
        XCTAssertEqual(countOrders(), Fixtures.ordersLoadAllJSON.ordersCount + 1)
    }

    func test_it_can_skip_saving_orders() {
        // Arrange
        insert(order: Fixtures.order)
        // Confidence checks
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)

        let network = MockNetwork()
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: [OrderStatusEnum.processing.rawValue],
                             writeStrategy: .doNotSave)

        // Assert
        // The previously saved order should still be there
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        // There should be no records saved from the GET /orders query
        XCTAssertEqual(countOrders(), 1)
    }

    func test_when_given_a_filter_it_fetches_all_orders_list() {
        // Arrange
        let network = MockNetwork(useResponseQueue: true)
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: [OrderStatusEnum.completed.rawValue],
                             writeStrategy: .deleteAllBeforeSaving)

        // Assert
        XCTAssertEqual(countOrders(),
                       Fixtures.ordersLoadAllJSON.ordersCount)
    }

    func test_when_not_given_a_filter_it_fetches_the_all_orders_list() {
        // Arrange
        let network = MockNetwork(useResponseQueue: true)
        network.simulateResponse(requestUrlSuffix: "orders", filename: Fixtures.ordersLoadAllJSON.fileName)

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: nil,
                             writeStrategy: .deleteAllBeforeSaving)

        // Assert
        XCTAssertEqual(countOrders(), Fixtures.ordersLoadAllJSON.ordersCount)
    }

    func testWhenAnErrorHappensItWillNotDeleteAllOrders() {
        // Arrange
        insert(order: Fixtures.order)

        let network = MockNetwork()
        network.simulateError(requestUrlSuffix: "orders", error: NetworkError.timeout())

        // Act
        executeActionAndWait(using: createOrderStore(using: network),
                             statuses: [OrderStatusEnum.processing.rawValue],
                             writeStrategy: .deleteAllBeforeSaving)

        // Assert
        // The previously saved order should still exist
        XCTAssertNotNil(findOrder(withID: Fixtures.order.orderID))
        XCTAssertEqual(countOrders(), 1)
    }
}

// MARK: - Private

private extension OrderStoreTests_FetchFilteredAndAllOrders {
    func createOrderStore(using network: Network) -> OrderStore {
        OrderStore(dispatcher: Dispatcher(), storageManager: storageManager, network: network)
    }

    func executeActionAndWait(using store: OrderStore,
                              statuses: [String]?,
                              writeStrategy: OrderAction.OrdersStorageWriteStrategy) {
        let expectation = self.expectation(description: "fetch")

        let action = OrderAction.fetchFilteredOrders(
            siteID: Fixtures.siteID,
            statuses: statuses,
            writeStrategy: writeStrategy,
            pageSize: 50) { _, _  in
                expectation.fulfill()
        }

        store.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func insert(order: Networking.Order) {
        let storageOrder = viewStorage.insertNewObject(ofType: Storage.Order.self)
        storageOrder.update(with: Fixtures.order)
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

    static let order = Networking.Order.fake().copy(
        siteID: siteID,
        orderID: 8_963,
        customerID: 11,
        number: "8963",
        status: .processing,
        currency: "USD",
        customerNote: "",
        datePaid: Date(),
        discountTotal: "30.00",
        discountTax: "1.20",
        shippingTotal: "0.00",
        shippingTax: "0.00",
        total: "31.20",
        totalTax: "1.20",
        paymentMethodID: "stripe",
        paymentMethodTitle: "Credit Card (Stripe)",
        items: []
    )
}

/// Counts `performAndSave` operations (each is a single save) while forwarding to an in-memory stack.
///
private final class SaveCountingStorageManager: StorageManagerType {
    private let inner = MockStorageManager()

    private(set) var performAndSaveCallCount = 0

    var viewStorage: StorageType {
        inner.viewStorage
    }

    func performAndSave(_ operation: @escaping (StorageType) -> Void,
                        completion: (() -> Void)?,
                        on queue: DispatchQueue) {
        performAndSaveCallCount += 1
        inner.performAndSave(operation, completion: completion, on: queue)
    }

    func performAndSave<T>(_ operation: @escaping (StorageType) throws -> T,
                           completion: @escaping (Result<T, Error>) -> Void,
                           on queue: DispatchQueue) {
        performAndSaveCallCount += 1
        inner.performAndSave(operation, completion: completion, on: queue)
    }

    func reset(onCompletion: (() -> Void)?) {
        inner.reset(onCompletion: onCompletion)
    }
}
