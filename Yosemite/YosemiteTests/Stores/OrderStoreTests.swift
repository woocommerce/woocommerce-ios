import Combine
import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderStore Unit Tests
///
final class OrderStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing OrderID
    ///
    private let sampleOrderID: Int64 = 963

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    /// Testing Page Size
    ///
    private let defaultPageSize = 75

    /// Testing Search Keyword
    ///
    private let defaultSearchKeyword = "gooooooooogol"

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - OrderAction.synchronizeOrders

    /// Verifies that OrderAction.synchronizeOrders returns the expected Orders.
    ///
    func testRetrieveOrdersReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 4)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderRefundCondensed.self), 4)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.synchronizeOrders` effectively persists any retrieved orders.
    ///
    func testRetrieveOrdersEffectivelyPersistsRetrievedOrders() {
        let expectation = self.expectation(description: "Persist order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderRefundCondensed.self), 0)

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 4)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderRefundCondensed.self), 4)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.synchronizeOrders` effectively persists all of the order fields
    /// correctly across all of the related Order objects (items, coupons, etc).
    ///
    func testRetrieveOrdersEffectivelyPersistsOrderFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderRefundCondensed.self), 0)

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertNil(error)

            let predicate = NSPredicate(format: "orderID = %ld", remoteOrder.orderID)
            let storedOrder = self.viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)
            let readOnlyStoredOrder = storedOrder?.toReadOnly()
            XCTAssertNotNil(storedOrder)
            XCTAssertNotNil(readOnlyStoredOrder)
            XCTAssertEqual(readOnlyStoredOrder, remoteOrder)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.synchronizeOrders` can properly process the document `broken-orders-mark-2`.
    ///
    /// Ref. Issue: https://github.com/woocommerce/woocommerce-ios/issues/221
    ///
    func testRetrieveOrdersWithBreakingDocumentIsProperlyParsedAndInsertedIntoStorage() {
        let expectation = self.expectation(description: "Persist order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "broken-orders-mark-2")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 6)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderAction.retrieveOrders returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrdersReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve orders error response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "generic_error")
        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderAction.retrieveOrders returns an error whenever there is no backend response.
    ///
    func testRetrieveOrdersReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve orders empty response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statuses: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { _, error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - OrderAction.checkIfStoreHasOrders

    func test_checkIfStoreHasOrders_returns_true_if_there_exists_any_order_in_storage() throws {
        // Given
        storageManager.insertSampleOrder(readOnlyOrder: Order.fake().copy(siteID: sampleSiteID))
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            store.onAction(OrderAction.checkIfStoreHasOrders(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasOrders = try result.get()
        XCTAssertTrue(hasOrders)
    }

    func test_checkIfStoreHasOrders_returns_true_if_remote_returns_non_empty_results() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            store.onAction(OrderAction.checkIfStoreHasOrders(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasOrders = try result.get()
        XCTAssertTrue(hasOrders)
    }

    func test_checkIfStoreHasOrders_returns_false_if_remote_returns_empty_results() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "orders", filename: "empty-data-array")
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            store.onAction(OrderAction.checkIfStoreHasOrders(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let hasOrders = try result.get()
        XCTAssertFalse(hasOrders)
    }

    func test_checkIfStoreHasOrders_relays_error_if_remote_request_fails() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "orders", filename: "generic_error")
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            store.onAction(OrderAction.checkIfStoreHasOrders(siteID: self.sampleSiteID, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - OrderAction.searchOrders

    /// Verifies that `OrderAction.searchOrder` effectively persists the retrieved orders.
    ///
    func testSearchOrdersEffectivelyPersistsRetrievedSearchOrders() {
        let expectation = self.expectation(description: "Search Persists Orders")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectedOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        let action = OrderAction.searchOrders(siteID: sampleSiteID,
                                              keyword: defaultSearchKeyword,
                                              pageNumber: defaultPageNumber,
                                              pageSize: defaultPageSize) { error in
                                                let readOnlyOrder = self.viewStorage.loadOrder(siteID: self.sampleSiteID,
                                                                                               orderID: expectedOrder.orderID)?.toReadOnly()
            XCTAssertEqual(readOnlyOrder, expectedOrder)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.searchOrders` effectively upserts the `OrderSearchResults` entity.
    ///
    func testSearchOrdersEffectivelyPersistsSearchResultsEntity() {
        let expectation = self.expectation(description: "Search Persists Results")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderRefundCondensed.self), 0)

        let action = OrderAction.searchOrders(siteID: sampleSiteID,
                                              keyword: defaultSearchKeyword,
                                              pageNumber: defaultPageNumber,
                                              pageSize: defaultPageSize) { error in
            let searchResults = self.viewStorage.loadOrderSearchResults(keyword: self.defaultSearchKeyword)

            XCTAssertEqual(searchResults?.keyword, self.defaultSearchKeyword)
            XCTAssertEqual(searchResults?.orders?.count, self.viewStorage.countObjects(ofType: Storage.Order.self))
            XCTAssertNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.searchOrders` does not result in duplicated entries in the OrderSearchResults entity.
    ///
    func testSearchOrdersDoesNotProduceDuplicatedReferences() {
        let expectation = self.expectation(description: "Search Doesnt Duplicate References")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let context = self.viewStorage

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        let nestedAction = OrderAction.searchOrders(siteID: sampleSiteID,
                                                    keyword: defaultSearchKeyword,
                                                    pageNumber: defaultPageNumber,
                                                    pageSize: defaultPageSize) { error in
            let orders = context.allObjects(ofType: Storage.Order.self, matching: nil, sortedBy: nil)
            for order in orders {
                XCTAssertEqual(order.searchResults?.count, 1)
                XCTAssertEqual(order.searchResults?.first?.keyword, self.defaultSearchKeyword)
            }

            XCTAssertEqual(context.firstObject(ofType: OrderSearchResults.self)?.orders?.count, 4)
            XCTAssertEqual(context.countObjects(ofType: OrderSearchResults.self), 1)
            XCTAssertNil(error)

            expectation.fulfill()
        }

        let firstAction = OrderAction.searchOrders(siteID: sampleSiteID,
                                                   keyword: defaultSearchKeyword,
                                                   pageNumber: defaultPageNumber,
                                                   pageSize: defaultPageSize) { error in
            orderStore.onAction(nestedAction)
        }

        orderStore.onAction(firstAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - OrderAction.retrieveOrder

    /// Verifies that OrderAction.retrieveOrder returns the expected Order.
    ///
    func testRetrieveSingleOrderReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve single order")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")
        let action = OrderAction.retrieveOrder(siteID: sampleSiteID, orderID: sampleOrderID) { (order, error) in
            XCTAssertNil(error)
            XCTAssertEqual(order, remoteOrder)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.retrieveOrder` effectively persists all of the remote order fields
    /// correctly across all of the related `Order` objects (items, coupons, etc).
    ///
    func testRetrieveSingleOrderEffectivelyPersistsOrderFieldsAndRelatedObjects() {
        let expectation = self.expectation(description: "Persist order")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        let action = OrderAction.retrieveOrder(siteID: sampleSiteID, orderID: sampleOrderID) { (order, error) in
            XCTAssertNotNil(order)
            XCTAssertNil(error)

            let predicate = NSPredicate(format: "orderID = %ld", remoteOrder.orderID)
            let storedOrder = self.viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)
            let readOnlyStoredOrder = storedOrder?.toReadOnly()
            XCTAssertNotNil(storedOrder)
            XCTAssertNotNil(readOnlyStoredOrder)
            XCTAssertEqual(readOnlyStoredOrder, remoteOrder)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_retrieve_single_order_fetches_up_to_date_order_from_storage() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "date-modified-gmt")

        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2023-03-29T03:23:02")
        let order = sampleOrder().copy(dateModified: dateModified)
        storageManager.insertSampleOrder(readOnlyOrder: order)

        // When
        let predicate = NSPredicate(format: "orderID = %ld", order.orderID)
        let storedOrder = self.viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)?.toReadOnly()

        let fetchedOrder: Yosemite.Order? = waitFor { promise in
            let action = OrderAction.retrieveOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { (order, error) in
                promise(order)
            }

            orderStore.onAction(action)
        }

        // Then
        assertEqual(storedOrder, fetchedOrder)
    }

    func test_retrieve_single_order_fetches_order_from_remote_when_stored_order_is_outdated() {
        // Given
        network = MockNetwork(useResponseQueue: true)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "date-modified-gmt")
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        storageManager.insertSampleOrder(readOnlyOrder: sampleOrderMutated())

        // When
        let fetchedOrder: Yosemite.Order? = waitFor { promise in
            let action = OrderAction.retrieveOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { (order, error) in
                promise(order)
            }

            orderStore.onAction(action)
        }

        // Then
        let expectedOrder = sampleOrder()
        assertEqual(expectedOrder, fetchedOrder)
    }

    // MARK: - OrderAction.retrieveOrderRemotely

    /// Verifies that OrderAction.retrieveOrderRemotely returns the expected Order.
    ///
    func test_retrieveOrderRemotely_returns_expected_fields() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result = waitFor { promise in
            orderStore.onAction(OrderAction.retrieveOrderRemotely(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertEqual(try? result.get(), remoteOrder)
    }

    /// Verifies that `OrderAction.retrieveOrderRemotely` effectively persists all of the remote order fields
    /// correctly across all of the related `Order` objects (items, coupons, etc).
    ///
    func test_retrieveOrderRemotely_effectively_persists_order_fields_and_related_objects() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        // When
        let result = waitFor { promise in
            orderStore.onAction(OrderAction.retrieveOrderRemotely(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let predicate = NSPredicate(format: "orderID = %ld", remoteOrder.orderID)
        let storedOrder = viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)
        XCTAssertEqual(storedOrder?.toReadOnly(), remoteOrder)
    }

    func test_retrieveOrderRemotely_does_not_return_existing_order_in_storage_and_replaces_order_in_storage() throws {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // Inserting an order without related objects for simpler testing.
        // The status is different from the remote order in the simulated response.
        let existingOrder = sampleOrder().copy(status: .autoDraft)
        storageManager.insertSampleOrder(readOnlyOrder: existingOrder)
        viewStorage.saveIfNeeded()

        let predicate = NSPredicate(format: "orderID = %ld", existingOrder.orderID)
        let existingOrderFromStorage = viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)?.toReadOnly()
        assertEqual(existingOrder.status, existingOrderFromStorage?.status)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)

        // When
        let result = waitFor { promise in
            orderStore.onAction(OrderAction.retrieveOrderRemotely(siteID: self.sampleSiteID, orderID: self.sampleOrderID) { result in
                promise(result)
            })
        }

        // Then
        let retrievedOrder = try XCTUnwrap(result.get())
        XCTAssertFalse(retrievedOrder == existingOrder)
        XCTAssertFalse(retrievedOrder.status == existingOrder.status)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        let orderFromStorage = viewStorage.firstObject(ofType: Storage.Order.self, matching: predicate)?.toReadOnly()
        assertEqual(retrievedOrder, orderFromStorage)
    }

    // MARK: - OrderStore.upsertStoredOrder

    /// Verifies that `upsertStoredOrder` does not produce duplicate entries.
    ///
    func testUpdateStoredOrderEffectivelyUpdatesPreexistantOrder() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.MetaData.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 0)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.MetaData.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 0)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated(), in: viewStorage)
        let storageOrder1 = viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderMutated().orderID)
        XCTAssertEqual(storageOrder1?.toReadOnly(), sampleOrderMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.MetaData.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 1)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated2(), in: viewStorage)
        let storageOrder2 = viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderMutated2().orderID)
        XCTAssertEqual(storageOrder2?.toReadOnly(), sampleOrderMutated2())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 4)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.MetaData.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 0)
    }

    /// Verifies that `upsertStoredOrder` effectively inserts a new Order, with the specified payload.
    ///
    func testUpdateStoredOrderEffectivelyPersistsNewOrder() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        XCTAssertNil(viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID))
        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, in: viewStorage)

        let storageOrder = viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID)
        XCTAssertEqual(storageOrder?.toReadOnly(), remoteOrder)
    }

    /// Verifies that `upsertStoredOrder` doesnt mark a Pre Existant order as "Search Results" (since it's been already
    /// retrieved for "Regular Scroll" display).
    ///
    func testUpsertStoredOrderDoesntMarkPreExistantOrdersAsSearchResults() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: false, in: viewStorage)
        viewStorage.saveIfNeeded()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: true, in: viewStorage)

        let storageOrder = viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID)
        XCTAssert(storageOrder?.exclusiveForSearch == false)
    }

    /// Verifies that `upsertStoredOrder` keeps the "Search Results" flag whenever the same order is upserted more than once.
    ///
    func testUpsertStoredOrderPreservesPreExistantSearchResults() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: true, in: viewStorage)
        viewStorage.saveIfNeeded()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: true, in: viewStorage)
        viewStorage.saveIfNeeded()

        let storageOrder = viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID)
        XCTAssert(storageOrder?.exclusiveForSearch == true)
    }

    /// Verifies that `upsertStoredOrder` unmarks "Search Results Cached Orders" whenever we're storing "regular scroll" Orders.
    ///
    func testUpsertStoredOrderUnmarksSearchResultsWhenUpsertingRegularPagingResults() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: true, in: viewStorage)
        viewStorage.saveIfNeeded()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: false, in: viewStorage)
        viewStorage.saveIfNeeded()

        let storageOrder = viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID)
        XCTAssert(storageOrder?.exclusiveForSearch == false)
    }


    // MARK: - OrderAction.upsertStoredResults

    /// Verifies that `upsertStoredResults` inserts new OrderSearchResults entities, and links them to a given Order.
    ///
    func testUpsertStoredSearchResultsEffectivelyInsertsNewSearchResultsEntitiesAndLinkThemToOrders() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, insertingSearchResults: true, in: viewStorage)
        orderStore.upsertStoredResults(keyword: defaultSearchKeyword, readOnlyOrder: remoteOrder, in: viewStorage)

        let storageSearchResults = viewStorage.loadOrderSearchResults(keyword: defaultSearchKeyword)
        let storageOrder = viewStorage.loadOrder(siteID: sampleSiteID, orderID: remoteOrder.orderID)

        XCTAssertEqual(storageSearchResults?.keyword, defaultSearchKeyword)
        XCTAssertEqual(storageSearchResults?.orders?.count, 1)
        XCTAssertEqual(storageSearchResults?.orders?.first?.orderID, remoteOrder.orderID)
        XCTAssertEqual(storageOrder?.searchResults?.first?.keyword, defaultSearchKeyword)
    }


    // MARK: - OrderAction.retrieveOrder

    /// Verifies that OrderAction.retrieveOrder returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSingleOrderReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve single order error response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "generic_error")
        let action = OrderAction.retrieveOrder(siteID: sampleSiteID, orderID: sampleOrderID) { (order, error) in
            XCTAssertNil(order)
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderAction.retrieveOrder returns an error whenever there is no backend response.
    ///
    func testRetrieveSingleOrderReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve single order empty response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = OrderAction.retrieveOrder(siteID: sampleSiteID, orderID: sampleOrderID) { (order, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(order)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that whenever a `retrieveOrder` action results in a response with statusCode = 404, the local entity
    /// is obliterated from existence.
    ///
    func testRetrieveSingleOrderResultingInStatusCode404CausesTheStoredOrderToGetDeleted() {
        let expectation = self.expectation(description: "Retrieve single order empty response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)

        network.simulateError(requestUrlSuffix: "orders/963", error: NetworkError.notFound())
        let action = OrderAction.retrieveOrder(siteID: sampleSiteID, orderID: sampleOrderID) { (order, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(order)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - OrderAction.updateOrder

    /// Verifies that an Order's .status field gets effectively updated during `updateOrder`'s response processing.
    ///
    func testUpdateOrderEffectivelyChangesAffectedOrderStatusField() {
        let expectation = self.expectation(description: "Update Order Status")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        /// Insert Order [Status == .completed]
        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated(), in: viewStorage)

        // Update: Expected Status is actually coming from `order.json` (Status == .processing actually!)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        let action = OrderAction.updateOrderStatus(siteID: sampleSiteID, orderID: sampleOrderID, status: OrderStatusEnum.processing) { error in
            XCTAssertNil(error)

            let storageOrder = self.storageManager.viewStorage.loadOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID)
            XCTAssert(storageOrder?.statusKey == OrderStatusEnum.processing.rawValue)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that the Optimistic OrderStatus Update OP effectively reverts the (optimistic) change upon failure.
    ///
    func testUpdateOrderRevertsOptimisticUpdateUponFailure() {
        let expectation = self.expectation(description: "Optimistic Update Recovery")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        /// Insert Order [Status == .completed]
        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated(), in: viewStorage)

        network.removeAllSimulatedResponses()

        let action = OrderAction.updateOrderStatus(siteID: sampleSiteID, orderID: sampleOrderID, status: OrderStatusEnum.processing) { error in
            XCTAssertNotNil(error)

            let storageOrder = self.storageManager.viewStorage.loadOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID)
            XCTAssert(storageOrder?.statusKey == OrderStatusEnum.completed.rawValue)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_optimistic_update_order_customer_note_correctly() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder()
        let updatedOrder = originalOrder.copy(customerNote: "Updated!")

        orderStore.upsertStoredOrder(readOnlyOrder: originalOrder, in: viewStorage)

        /// As we're updating the order optimistically, the response from the API will be ignored.
        /// It's only to simulate the successful path.
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID, order: updatedOrder, fields: [.customerNote]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storageOrder?.customerNote, updatedOrder.customerNote)
    }

    func test_optimistic_update_order_customer_note_reverts_upon_failure() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder() // (Customer note == "")
        let updatedOrder = originalOrder.copy(customerNote: "Updated!")

        orderStore.upsertStoredOrder(readOnlyOrder: originalOrder, in: viewStorage)

        network.removeAllSimulatedResponses()

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID, order: updatedOrder, fields: [.customerNote]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertFalse(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storageOrder?.customerNote, originalOrder.customerNote)
    }

    func test_optimistic_update_deletes_order_from_storage_upon_failure_if_it_does_not_exist_locally() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder() // (Customer note == "")
        let updatedOrder = originalOrder.copy(customerNote: "Updated!")

        network.removeAllSimulatedResponses()

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID, order: updatedOrder, fields: [.customerNote]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertFalse(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertNil(storageOrder)
    }

    func test_optimistic_update_order_shipping_phone_correctly() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder() // [Shipping Phone == "333-333-3333"]
        let newAddress = Address.fake().copy(phone: "333-333-3334")
        let updatedOrder = originalOrder.copy(shippingAddress: newAddress) // [Shipping Phone == "333-333-3334"]

        orderStore.upsertStoredOrder(readOnlyOrder: originalOrder, in: viewStorage)

        /// As we're updating the order optimistically, the response from the API will be ignored.
        /// It's only to simulate the successful path.
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID, order: updatedOrder, fields: [.shippingAddress]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storageOrder?.shippingPhone, updatedOrder.shippingAddress?.phone)
    }

    func test_optimistic_update_order_shipping_phone_reverts_upon_failure() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder() // [Shipping Phone == "333-333-3333"]
        let newAddress = Address.fake().copy(phone: "333-333-3334")
        let updatedOrder = originalOrder.copy(shippingAddress: newAddress) // [Shipping Phone == "333-333-3334"]

        orderStore.upsertStoredOrder(readOnlyOrder: originalOrder, in: viewStorage)

        network.removeAllSimulatedResponses()

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID, order: updatedOrder, fields: [.shippingAddress]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertFalse(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storageOrder?.shippingPhone, originalOrder.shippingAddress?.phone)
    }

    func test_optimistic_update_order_shipping_and_billing_phone_correctly() {
        // Given
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let originalOrder = sampleOrder() // [Shipping & Biling Phone == "333-333-3333"]
        let newAddress = Address.fake().copy(phone: "333-333-3334")
        let updatedOrder = originalOrder.copy(billingAddress: newAddress, shippingAddress: newAddress) // [Shipping & Biling == "333-333-3334"]

        orderStore.upsertStoredOrder(readOnlyOrder: originalOrder, in: viewStorage)

        /// As we're updating the order optimistically, the response from the API will be ignored.
        /// It's only to simulate the successful path.
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result: Result<Networking.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrderOptimistically(siteID: self.sampleSiteID,
                                                               order: updatedOrder,
                                                               fields: [.shippingAddress, .billingAddress]) { result in
                promise(result)
            }
            orderStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storageOrder = storageManager.viewStorage.loadOrder(siteID: sampleSiteID, orderID: sampleOrderID)
        XCTAssertEqual(storageOrder?.shippingPhone, updatedOrder.shippingAddress?.phone)
        XCTAssertEqual(storageOrder?.billingPhone, updatedOrder.billingAddress?.phone)
    }


    // MARK: - OrderAction.resetStoredOrders

    /// Verifies that `resetStoredOrders` nukes the Orders Cache.
    ///
    func testResetStoredOrdersEffectivelyNukesTheOrdersCache() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = sampleOrder().copy(appliedGiftCards: [.fake()])

        orderStore.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 1)

        let expectation = self.expectation(description: "Stored Orders Reset")
        let action = OrderAction.resetStoredOrders {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItem.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderTaxLine.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderGiftCard.self), 0)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that Innocuous Upsert OP(s) performed in Derived Contexts **DO NOT** trigger Refresh Events in the
    /// main thread.
    ///
    /// This translates effectively into: Ensure that performing update OP's that don't really change anything, do not
    /// end up causing UI refresh OP's in the main thread.
    ///
    func testInnocuousUpdateOperationsPerformedInBackgroundDoNotTriggerUpsertEventsInTheMainThread() {
        // Stack
        let viewContext = storageManager.persistentContainer.viewContext
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let entityListener = EntityListener(viewContext: viewContext, readOnlyEntity: sampleOrder())

        // Track Events: Upsert == 1 / Delete == 0
        var numberOfUpsertEvents = 0
        entityListener.onUpsert = { upserted in
            numberOfUpsertEvents += 1
        }

        // We expect *never* to get a deletion event
        entityListener.onDelete = {
            XCTFail()
        }

        // Initial save: This should trigger *ONE* Upsert event
        let backgroundSaveExpectation = expectation(description: "Retrieve order notes empty response")
        let derivedContext = storageManager.writerDerivedStorage

        derivedContext.perform {
            orderStore.upsertStoredOrder(readOnlyOrder: self.sampleOrder(), in: derivedContext)
        }

        storageManager.saveDerivedType(derivedStorage: derivedContext) {

            // Secondary Save: Expect ZERO new Upsert Events
            derivedContext.perform {
                orderStore.upsertStoredOrder(readOnlyOrder: self.sampleOrder(), in: derivedContext)
            }

            self.storageManager.saveDerivedType(derivedStorage: derivedContext) {
                XCTAssertEqual(numberOfUpsertEvents, 1)
                backgroundSaveExpectation.fulfill()
            }
        }

        wait(for: [backgroundSaveExpectation], timeout: Constants.expectationTimeout)
    }


    func test_create_simple_payments_order_properly_sends_values_as_fees_with_no_taxes() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order")

        // When
        let action = OrderAction.createSimplePaymentsOrder(siteID: self.sampleSiteID, status: .autoDraft, amount: "125.50", taxable: false) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": 0,
            "name": "Simple Payments",
            "tax_status": "none",
            "tax_class": "",
            "total": "125.50"
        ]
        assertEqual(received, expected)
    }

    func test_create_simple_payments_order_properly_sends_values_as_fees_with_taxes() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order")

        // When
        let action = OrderAction.createSimplePaymentsOrder(siteID: self.sampleSiteID, status: .autoDraft, amount: "125.50", taxable: true) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": 0,
            "name": "Simple Payments",
            "tax_status": "taxable",
            "tax_class": "",
            "total": "125.50"
        ]
        assertEqual(received, expected)
    }

    func test_create_pending_simple_payments_order_stores_orders_correctly() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order")

        // When
        let storedOrder: Yosemite.Order? = waitFor { promise in
            let action = OrderAction.createSimplePaymentsOrder(siteID: self.sampleSiteID, status: .pending, amount: "125.50", taxable: false) { _ in
                let order = self.storageManager.viewStorage.loadOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID)?.toReadOnly()
                promise(order)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNotNil(storedOrder)
    }

    func test_create_draft_simple_payments_order_does_not_get_stored() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order-auto-draft-status")

        // When
        let storedOrder: Yosemite.Order? = waitFor { promise in
            let action = OrderAction.createSimplePaymentsOrder(siteID: self.sampleSiteID, status: .autoDraft, amount: "125.50", taxable: false) { _ in
                let order = self.storageManager.viewStorage.loadOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID)?.toReadOnly()
                promise(order)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNil(storedOrder)
    }

    func test_create_order_stores_orders_correctly() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order")

        // When
        let storedOrder: Yosemite.Order? = waitFor { promise in
            let action = OrderAction.createOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: nil) { _ in
                let order = self.storageManager.viewStorage.loadOrder(siteID: self.sampleSiteID, orderID: self.sampleOrderID)?.toReadOnly()
                promise(order)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNotNil(storedOrder)
    }

    func test_create_order_with_gift_card_returns_notApplied_error_when_error_response_does_not_include_gift_card() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.createOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError, .notApplied)
    }

    func test_create_order_with_gift_card_returns_cannotApply_error_when_error_is_returned() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order-gift-card-cannot-apply-error")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.createOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError,
                       .cannotApply(reason: "Requested amount for gift card code Z exceeded the order total."))
    }

    func test_create_order_with_gift_card_returns_invalid_error_when_error_is_returned() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order-gift-card-invalid-error")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.createOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134") { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError,
                       .invalid(reason: "Gift card code Z not found."))
    }

    func test_update_simple_payments_order_sends_correct_values() throws {
        // Given
        let feeID: Int64 = 1234
        let amount = "100.00"
        let amountName = "A simple amount"
        let taxable = true
        let note = "This is a note"
        let email = "email@email.com"

        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let action = OrderAction.updateSimplePaymentsOrder(siteID: sampleSiteID,
                                                           orderID: sampleOrderID,
                                                           feeID: feeID,
                                                           status: .pending,
                                                           amount: amount,
                                                           amountName: amountName,
                                                           taxable: taxable,
                                                           orderNote: note,
                                                           email: email) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let receivedFees = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expectedFees: [String: AnyHashable] = [
            "id": 1234,
            "name": "A simple amount",
            "tax_status": "taxable",
            "tax_class": "",
            "total": "100.00"
        ]
        assertEqual(expectedFees, receivedFees)

        let receivedBilling = try XCTUnwrap(request.parameters["billing"] as? [String: AnyHashable])
        let expectedBilling: [String: AnyHashable] = [
            "first_name": "",
            "last_name": "",
            "address_1": "",
            "city": "",
            "state": "",
            "postcode": "",
            "country": "",
            "email": email
        ]
        assertEqual(receivedBilling, expectedBilling)

        let receivedNote = try XCTUnwrap(request.parameters["customer_note"] as? String)
        assertEqual(receivedNote, note)
    }

    func test_update_simple_payments_order_sends_default_name_when_none_provided() throws {
        // Given
        let feeID: Int64 = 1234
        let amount = "100.00"
        let taxable = true
        let note = "This is a note"
        let email = "email@email.com"

        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let action = OrderAction.updateSimplePaymentsOrder(siteID: sampleSiteID,
                                                           orderID: sampleOrderID,
                                                           feeID: feeID,
                                                           status: .pending,
                                                           amount: amount,
                                                           amountName: nil,
                                                           taxable: taxable,
                                                           orderNote: note,
                                                           email: email) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let receivedFees = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expectedFees: [String: AnyHashable] = [
            "id": 1234,
            "name": "Simple Payments",
            "tax_status": "taxable",
            "tax_class": "",
            "total": "100.00"
        ]
        assertEqual(expectedFees, receivedFees)
    }

    func test_create_order_sends_expected_fields() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let action = OrderAction.createOrder(siteID: sampleSiteID, order: sampleOrder(), giftCard: nil) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let receivedKeys = Array(request.parameters.keys).sorted()
        let expectedKeys = [
            "billing",
            "coupon_lines",
            "customer_id",
            "customer_note",
            "fee_lines",
            "line_items",
            "meta_data",
            "shipping",
            "shipping_lines",
            "status"
        ]
        assertEqual(expectedKeys, receivedKeys)
    }

    func test_create_order_with_giftCard_sends_expected_fields() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let action = OrderAction.createOrder(siteID: sampleSiteID, order: sampleOrder(), giftCard: "GEM") { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let receivedKeys = Array(request.parameters.keys).sorted()
        let expectedKeys = [
            "billing",
            "coupon_lines",
            "customer_id",
            "customer_note",
            "fee_lines",
            "gift_cards",
            "line_items",
            "meta_data",
            "shipping",
            "shipping_lines",
            "status"
        ]
        assertEqual(expectedKeys, receivedKeys)
    }

    func test_create_order_does_not_upsert_autodrafts() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "order-auto-draft-status")

        // When
        let result: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = OrderAction.createOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
    }

    func test_update_order_does_not_upsert_autodrafts() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order-auto-draft-status")

        // When
        let result: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = OrderAction.updateOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: nil, fields: []) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
    }

    func test_update_order_with_giftCard_sends_expected_fields() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let action = OrderAction.updateOrder(siteID: sampleSiteID, order: sampleOrder(), giftCard: "AEJE", fields: []) { _ in }
        store.onAction(action)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let receivedKeys = Array(request.parameters.keys).sorted()
        let expectedKeys = [
            "gift_cards"
        ]
        assertEqual(expectedKeys, receivedKeys)
    }

    func test_update_order_with_gift_card_returns_notApplied_error_when_error_response_does_not_include_gift_card() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.updateOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134", fields: []) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError, .notApplied)
    }

    func test_update_order_with_gift_card_returns_cannotApply_error_when_error_is_returned() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order-gift-card-cannot-apply-error")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.updateOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134", fields: []) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError,
                       .cannotApply(reason: "Requested amount for gift card code Z exceeded the order total."))
    }

    func test_update_order_with_gift_card_returns_invalid_error_when_error_is_returned() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order-gift-card-invalid-error")

        // When
        let result = waitFor { promise in
            store.onAction(OrderAction.updateOrder(siteID: self.sampleSiteID, order: self.sampleOrder(), giftCard: "134", fields: []) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? OrderStore.GiftCardError,
                       .invalid(reason: "Gift card code Z not found."))
    }

    // MARK: Tests for `markOrderAsPaidLocally`

    func test_markOrderAsPaidLocally_sets_order_datePaid_and_status_to_processing_on_success() throws {
        // Given
        let initialStatus = OrderStatusEnum.pending
        let expectedStatus = OrderStatusEnum.processing
        // GMT: Wednesday, May 11, 2022 3:45:03 AM
        let datePaid = Date(timeIntervalSince1970: 1652240703)
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = Order.fake().copy(siteID: 1234, orderID: 5678, status: initialStatus)

        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = OrderAction.markOrderAsPaidLocally(siteID: order.siteID, orderID: order.orderID, datePaid: datePaid) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        guard let storageOrder = viewStorage.loadOrder(siteID: order.siteID, orderID: order.orderID) else {
            return XCTFail("Expected order. Got nothing")
        }
        assertEqual(storageOrder.datePaid, datePaid)
        assertEqual(storageOrder.statusKey, expectedStatus.rawValue)
    }

    func test_markOrderAsPaidLocally_returns_failure_when_there_is_no_order() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = Order.fake()
        // GMT: Wednesday, May 11, 2022 3:45:03 AM
        let datePaid = Date(timeIntervalSince1970: 1652240703)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = OrderAction.markOrderAsPaidLocally(siteID: order.siteID, orderID: order.orderID, datePaid: datePaid) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? OrderStore.MarkOrderAsPaidLocallyError, .orderNotFoundInStorage)
    }

    func test_delete_order_removes_order_from_storage() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = sampleOrder()
        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "order")

        // When
        let result: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = OrderAction.deleteOrder(siteID: self.sampleSiteID, order: order, deletePermanently: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
    }

    func test_delete_order_keeps_order_in_storage_if_deletion_fails() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = sampleOrder()
        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "generic_error")

        // When
        let result: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = OrderAction.deleteOrder(siteID: self.sampleSiteID, order: order, deletePermanently: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 1)
    }

    func test_delete_order_does_not_keep_autodraft_order_in_storage_if_deletion_fails() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let order = sampleOrder().copy(status: .autoDraft)
        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)
        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "generic_error")

        // When
        let result: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = OrderAction.deleteOrder(siteID: self.sampleSiteID, order: order, deletePermanently: false) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
    }

    // MARK: - `observeInsertedOrders`

    func test_observeInsertedOrders_emits_inserted_order() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteID: Int64 = 6688

        // Ensures the assertions take place after the Core Data notifications are sent.
        var viewContextChanged = false
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewStorage)
            .sink { _ in
                viewContextChanged = true
            }.store(in: &subscriptions)

        // When
        let publisher: AnyPublisher<[Yosemite.Order], Never> = waitFor { promise in
            let action = OrderAction.observeInsertedOrders(siteID: siteID) { publisher in
                promise(publisher)
            }
            store.onAction(action)
        }
        var ordersSequence = [[Yosemite.Order]]()
        publisher.sink { orders in
            ordersSequence.append(orders)
        }.store(in: &subscriptions)

        // Inserts an order on the same site.
        let order = sampleOrder().copy(siteID: siteID, status: .autoDraft)
        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)

        waitUntil {
            viewContextChanged == true
        }

        // Then
        XCTAssertEqual(ordersSequence.count, 1)
        XCTAssertEqual(ordersSequence.first, [order])
    }

    func test_observeInsertedOrders_does_not_emit_values_after_inserting_orders_in_a_different_site() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteID: Int64 = 6688
        let anotherSiteID: Int64 = 7799

        // Ensures the assertions take place after the Core Data notifications are sent.
        var viewContextChanged = false
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewStorage)
            .sink { _ in
                viewContextChanged = true
            }.store(in: &subscriptions)

        // When
        let publisher: AnyPublisher<[Yosemite.Order], Never> = waitFor { promise in
            let action = OrderAction.observeInsertedOrders(siteID: siteID) { publisher in
                promise(publisher)
            }
            store.onAction(action)
        }
        var ordersSequence = [[Yosemite.Order]]()
        publisher.sink { orders in
            ordersSequence.append(orders)
        }.store(in: &subscriptions)

        // Inserts an order on another site.
        let order = sampleOrder().copy(siteID: anotherSiteID, status: .autoDraft)
        store.upsertStoredOrder(readOnlyOrder: order, in: viewStorage)

        waitUntil {
            viewContextChanged == true
        }

        // Then
        XCTAssertEqual(ordersSequence.count, 0)
    }

    func test_observeInsertedOrders_does_not_emit_values_after_inserting_a_non_order_object() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteID: Int64 = 6688

        // Ensures the assertions take place after the Core Data notifications are sent.
        var viewContextChanged = false
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewStorage)
            .sink { _ in
                viewContextChanged = true
            }.store(in: &subscriptions)

        // When
        let publisher: AnyPublisher<[Yosemite.Order], Never> = waitFor { promise in
            let action = OrderAction.observeInsertedOrders(siteID: siteID) { publisher in
                promise(publisher)
            }
            store.onAction(action)
        }
        var ordersSequence = [[Yosemite.Order]]()
        publisher.sink { orders in
            ordersSequence.append(orders)
        }.store(in: &subscriptions)

        // Inserts a product on the same site.
        let product = Product.fake().copy(siteID: siteID)
        let storageProduct = viewStorage.insertNewObject(ofType: Storage.Product.self)
        storageProduct.update(with: product)

        waitUntil {
            viewContextChanged == true
        }

        // Then
        XCTAssertEqual(ordersSequence.count, 0)
    }

    // MARK: - Product bundles extension

    func test_updateOrder_with_remote_item_with_bundle_configuration_updates_line_items() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteID: Int64 = 6688
        let order = Order.fake().copy(items: [
            // Parent order item that is a bundle product with item ID 6.
            .fake().copy(itemID: 6, quantity: 2, bundleConfiguration: [.fake()]),
            // Child order item of the bundle product order item (parent item ID 6).
            .fake().copy(itemID: 7, quantity: 3, parent: 6)
        ])

        // When
        store.onAction(OrderAction.updateOrder(siteID: siteID,
                                               order: order,
                                               giftCard: nil,
                                               fields: [.items],
                                               onCompletion: { _ in }))

        // Then
        let lineItems = try XCTUnwrap(network.queryParametersDictionary?["line_items"] as? [[String: Any]])
        XCTAssertEqual(lineItems.count, 3)

        let removedBundleOrderItem = try XCTUnwrap(lineItems.first { ($0["id"] as? Int64) == 6 })
        XCTAssertEqual(removedBundleOrderItem["quantity"] as? Int64, 0)
        XCTAssertNil(removedBundleOrderItem["bundle_configuration"])

        let updatedBundleOrderItem = try XCTUnwrap(lineItems.first { ($0["id"] as? Int64) == 0 })
        XCTAssertEqual(updatedBundleOrderItem["quantity"] as? Int64, 2)
        XCTAssertNotNil(updatedBundleOrderItem["bundle_configuration"])

        let removedChildBundleOrderItem = try XCTUnwrap(lineItems.first { ($0["id"] as? Int64) == 7 })
        XCTAssertEqual(removedChildBundleOrderItem["quantity"] as? Int64, 0)
        XCTAssertNil(removedChildBundleOrderItem["bundle_configuration"])
    }

    func test_updateOrder_with_new_item_with_bundle_configuration_does_not_update_line_items() throws {
        // Given
        let store = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let siteID: Int64 = 6688
        let order = Order.fake().copy(items: [
            .fake().copy(itemID: 0, quantity: 2, bundleConfiguration: [.fake()]),
            // Another order item.
            .fake().copy(itemID: 7, quantity: 3)
        ])

        // When
        store.onAction(OrderAction.updateOrder(siteID: siteID,
                                               order: order,
                                               giftCard: nil,
                                               fields: [.items],
                                               onCompletion: { _ in }))

        // Then
        let lineItems = try XCTUnwrap(network.queryParametersDictionary?["line_items"] as? [[String: Any]])
        XCTAssertEqual(lineItems.count, 2)

        let bundleOrderItem = try XCTUnwrap(lineItems.first { ($0["id"] as? Int64) == 0 })
        XCTAssertEqual(bundleOrderItem["quantity"] as? Int64, 2)
        XCTAssertNotNil(bundleOrderItem["bundle_configuration"])

        let anotherOrderItem = try XCTUnwrap(lineItems.first { ($0["id"] as? Int64) == 7 })
        XCTAssertEqual(anotherOrderItem["quantity"] as? Int64, 3)
    }
}


// MARK: - Private Methods
//
private extension OrderStoreTests {
    func sampleOrder() -> Networking.Order {
        return Order.fake().copy(siteID: sampleSiteID,
                                 orderID: 963,
                                 customerID: 11,
                                 orderKey: "abc123",
                                 isEditable: true,
                                 needsPayment: true,
                                 needsProcessing: true,
                                 number: "963",
                                 status: .processing,
                                 currency: "USD",
                                 customerNote: "",
                                 dateCreated: DateFormatter.dateFromString(with: "2018-04-03T23:05:12"),
                                 dateModified: DateFormatter.dateFromString(with: "2018-04-03T23:05:14"),
                                 datePaid: DateFormatter.dateFromString(with: "2018-04-03T23:05:14"),
                                 discountTotal: "30.00",
                                 discountTax: "1.20",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "31.20",
                                 totalTax: "1.20",
                                 paymentMethodID: "stripe",
                                 paymentMethodTitle: "Credit Card (Stripe)",
                                 paymentURL: URL(string: "http://www.automattic.com"),
                                 items: sampleItems(),
                                 billingAddress: sampleAddress(),
                                 shippingAddress: sampleAddress(),
                                 shippingLines: sampleShippingLines(),
                                 coupons: sampleCoupons(),
                                 taxes: sampleOrderTaxLines(),
                                 customFields: sampleCustomFields())
    }

    func sampleOrderMutated() -> Networking.Order {
        return sampleOrder().copy(status: .completed,
                                  discountTotal: "40.00",
                                  total: "41.20",
                                  items: sampleItemsMutated(),
                                  coupons: sampleCouponsMutated(),
                                  taxes: sampleOrderTaxLinesMutated(),
                                  customFields: sampleCustomFieldsMutated(),
                                  appliedGiftCards: sampleAppliedGiftCards())
    }

    func sampleOrderMutated2() -> Networking.Order {
        return sampleOrder().copy(status: .completed,
                                  discountTotal: "40.00",
                                  total: "41.20",
                                  items: sampleItemsMutated2(),
                                  coupons: [],
                                  taxes: [],
                                  customFields: [],
                                  appliedGiftCards: [])
    }

    func sampleAddress() -> Networking.Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func sampleShippingLines() -> [Networking.ShippingLine] {
        return [ShippingLine(shippingID: 123,
        methodTitle: "International Priority Mail Express Flat Rate",
        methodID: "usps",
        total: "133.00",
        totalTax: "0.00",
        taxes: [.init(taxID: 1, subtotal: "", total: "0.62125")])]
    }

    func sampleCoupons() -> [Networking.OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "30",
                                      discountTax: "1.2")

        return [coupon1]
    }

    func sampleCouponsMutated() -> [Networking.OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "20",
                                      discountTax: "12.2")
        let coupon2 = OrderCouponLine(couponID: 12,
                                      code: "hithere!",
                                      discount: "50",
                                      discountTax: "0.66")

        return [coupon1, coupon2]
    }

    func sampleOrderTaxLine() -> Networking.OrderTaxLine {
        OrderTaxLine.fake().copy(taxID: 1330,
                                 rateCode: "US-NY-STATE-2",
                                 rateID: 6,
                                 label: "State",
                                 totalTax: "7.71",
                                 ratePercent: 4.5)
    }

    func sampleOrderTaxLines() -> [Networking.OrderTaxLine] {
        [sampleOrderTaxLine()]
    }

    func sampleOrderTaxLinesMutated() -> [Networking.OrderTaxLine] {
        [
            sampleOrderTaxLine().copy(totalTax: "55", ratePercent: 5.5),
            OrderTaxLine.fake()
        ]
    }

    func sampleItems() -> [Networking.OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product)",
                              productID: 52,
                              variationID: 0,
                              quantity: 2,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "50.00",
                              subtotalTax: "2.00",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "2", total: "1.2")],
                              total: "30.00",
                              totalTax: "1.20",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle",
                              productID: 234,
                              variationID: 0,
                              quantity: 1.5,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "10.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "0.4", total: "0")],
                              total: "0.00",
                              totalTax: "0.00",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        return [item1, item2]
    }

    func sampleItemsMutated() -> [Networking.OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product) 2",
                              productID: 52,
                              variationID: 0,
                              quantity: 10,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "60.00",
                              subtotalTax: "4.00",
                              taxClass: "",
                              taxes: taxes(),
                              total: "64.00",
                              totalTax: "4.00",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle 2",
                              productID: 234,
                              variationID: 0,
                              quantity: 3,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "30.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: taxes(),
                              total: "30.40",
                              totalTax: "0.40",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        let item3 = OrderItem(itemID: 23,
                              name: "Some new product",
                              productID: 12,
                              variationID: 0,
                              quantity: 1,
                              price: NSDecimalNumber(integerLiteral: 10),
                              sku: "QWE123",
                              subtotal: "130.00",
                              subtotalTax: "10.40",
                              taxClass: "",
                              taxes: taxes(),
                              total: "140.40",
                              totalTax: "10.40",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        return [item1, item2, item3]
    }

    func sampleItemsMutated2() -> [Networking.OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product) 2",
                              productID: 52,
                              variationID: 0,
                              quantity: 10,
                              price: NSDecimalNumber(integerLiteral: 10),
                              sku: "",
                              subtotal: "60.00",
                              subtotalTax: "4.00",
                              taxClass: "",
                              taxes: taxesMutated(),
                              total: "64.00",
                              totalTax: "4.00",
                              attributes: [],
                              addOns: [],
                              parent: nil,
                              bundleConfiguration: [])

        return [item1]
    }

    func taxes() -> [Networking.OrderItemTax] {
        return [Networking.OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45")]
    }

    func taxesMutated() -> [Networking.OrderItemTax] {
        [Networking.OrderItemTax(taxID: 73, subtotal: "0.9", total: "0.9"),
         Networking.OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45")]
    }

    func sampleCustomFields() -> [Networking.MetaData] {
        return [Networking.MetaData(metadataID: 18148, key: "Viewed Currency", value: "USD")]
    }

    func sampleCustomFieldsMutated() -> [Networking.MetaData] {
        return [Networking.MetaData(metadataID: 18148, key: "Viewed Currency", value: "GBP"),
                Networking.MetaData(metadataID: 18149, key: "Converted Order Total", value: "223.71 GBP")]
    }

    func sampleAppliedGiftCards() -> [Networking.OrderGiftCard] {
        return [Networking.OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)]
    }
}
