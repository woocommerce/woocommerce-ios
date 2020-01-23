import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderStore Unit Tests
///
class OrderStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

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



    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: - OrderAction.synchronizeOrders

    /// Verifies that OrderAction.synchronizeOrders returns the expected Orders.
    ///
    func testRetrieveOrdersReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
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

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
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

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
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

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
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
        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
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

        let action = OrderAction.synchronizeOrders(siteID: sampleSiteID, statusKey: nil, pageNumber: defaultPageNumber, pageSize: defaultPageSize) { error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
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
            let readOnlyOrder = self.viewStorage.loadOrder(orderID: expectedOrder.orderID)?.toReadOnly()
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


    // MARK: - OrderStore.upsertStoredOrder

    /// Verifies that `upsertStoredOrder` does not produce duplicate entries.
    ///
    func testUpdateStoredOrderEffectivelyUpdatesPreexistantOrder() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 0)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 1)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated(), in: viewStorage)
        let storageOrder1 = viewStorage.loadOrder(orderID: sampleOrderMutated().orderID)
        XCTAssertEqual(storageOrder1?.toReadOnly(), sampleOrderMutated())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 3)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 2)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrderMutated2(), in: viewStorage)
        let storageOrder2 = viewStorage.loadOrder(orderID: sampleOrderMutated2().orderID)
        XCTAssertEqual(storageOrder2?.toReadOnly(), sampleOrderMutated2())
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItemTax.self), 5)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)
    }

    /// Verifies that `upsertStoredOrder` effectively inserts a new Order, with the specified payload.
    ///
    func testUpdateStoredOrderEffectivelyPersistsNewOrder() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        XCTAssertNil(viewStorage.loadOrder(orderID: remoteOrder.orderID))
        orderStore.upsertStoredOrder(readOnlyOrder: remoteOrder, in: viewStorage)

        let storageOrder = viewStorage.loadOrder(orderID: remoteOrder.orderID)
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

        let storageOrder = viewStorage.loadOrder(orderID: remoteOrder.orderID)
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

        let storageOrder = viewStorage.loadOrder(orderID: remoteOrder.orderID)
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

        let storageOrder = viewStorage.loadOrder(orderID: remoteOrder.orderID)
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
        let storageOrder = viewStorage.loadOrder(orderID: remoteOrder.orderID)

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

        network.simulateError(requestUrlSuffix: "orders/963", error: NetworkError.notFound)
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

        let action = OrderAction.updateOrder(siteID: sampleSiteID, orderID: sampleOrderID, statusKey: OrderStatusEnum.processing.rawValue) { error in
            XCTAssertNil(error)

            let storageOrder = self.storageManager.viewStorage.loadOrder(orderID: self.sampleOrderID)
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

        let action = OrderAction.updateOrder(siteID: sampleSiteID, orderID: sampleOrderID, statusKey: OrderStatusEnum.processing.rawValue) { error in
            XCTAssertNotNil(error)

            let storageOrder = self.storageManager.viewStorage.loadOrder(orderID: self.sampleOrderID)
            XCTAssert(storageOrder?.statusKey == OrderStatusEnum.completed.rawValue)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - OrderAction.resetStoredOrders

    /// Verifies that `resetStoredOrders` nukes the Orders Cache.
    ///
    func testResetStoredOrdersEffectivelyNukesTheOrdersCache() {
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        orderStore.upsertStoredOrder(readOnlyOrder: sampleOrder(), in: viewStorage)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 1)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderItem.self), 2)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 1)

        let expectation = self.expectation(description: "Stored Orders Reset")
        let action = OrderAction.resetStoredOrders {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderItem.self), 0)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderCoupon.self), 0)

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
        let derivedContext = storageManager.newDerivedStorage()

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


    // MARK: - OrderAction.countProcessingOrders

    /// Verifies that OrderAction.countProcessingOrders returns the expected OrderCount.
    ///
    func testCountProcessingOrdersReturnsExpectedFields() {
        let expectation = self.expectation(description: "Count processing orders")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "orders-count")

        let action = OrderAction.countProcessingOrders(siteID: sampleSiteID) { orderCount, error in
            XCTAssertNil(error)
            // Assert the entity is saved to coredata
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderCount.self), 1)
            // And assert it is returned
            XCTAssertNotNil(orderCount)
            XCTAssertEqual(orderCount!["processing"]?.total, 6)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderAction.countProcessingOrders returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderCountReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order count error response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")

        let action = OrderAction.countProcessingOrders(siteID: sampleSiteID) { orderCount, error in
            XCTAssertNotNil(error)

            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension OrderStoreTests {
    func sampleOrder() -> Networking.Order {
        return Order(siteID: sampleSiteID,
                     orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     statusKey: "processing",
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItems(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: sampleCoupons(),
                     refunds: [])
    }

    func sampleOrderMutated() -> Networking.Order {
        return Order(siteID: sampleSiteID,
                     orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     statusKey: "completed",
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "40.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "41.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItemsMutated(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: sampleCouponsMutated(),
                     refunds: [])
    }

    func sampleOrderMutated2() -> Networking.Order {
        return Order(siteID: sampleSiteID,
                     orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     statusKey: "completed",
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "40.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "41.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItemsMutated2(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: [],
                     refunds: [])
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
        totalTax: "0.00")]
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
                              taxes: [],
                              total: "30.00",
                              totalTax: "1.20")

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
                              taxes: [],
                              total: "0.00",
                              totalTax: "0.00")

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
                              totalTax: "4.00")

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
                              totalTax: "0.40")

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
                              totalTax: "10.40")

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
                              totalTax: "4.00")

        return [item1]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

    func taxes() -> [Networking.OrderItemTax] {
        return [Networking.OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45")]
    }

    func taxesMutated() -> [Networking.OrderItemTax] {
        return [Networking.OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45"),
                Networking.OrderItemTax(taxID: 73, subtotal: "0.9", total: "0.9")]
    }
}
