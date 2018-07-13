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


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: - OrderAction.retrieveOrders

    /// Verifies that OrderAction.retrieveOrders returns the expected Orders.
    ///
    func testRetrieveOrdersReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders")
        let action = OrderAction.retrieveOrders(siteID: 123) { (orders, error) in
            XCTAssertNil(error)
            guard let orders = orders else {
                XCTFail()
                return
            }
            XCTAssertEqual(orders.count, 3, "Orders count should be 3")
            XCTAssertTrue(orders.contains(remoteOrder))
            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.retrieveOrders` effectively persists any retrieved orders.
    ///
    func testRetrieveOrdersEffectivelyPersistsRetrievedOrders() {
        let expectation = self.expectation(description: "Persist order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        let action = OrderAction.retrieveOrders(siteID: 123) { (orders, error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Order.self), 3)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `OrderAction.retrieveOrders` effectively persists all of the order fields correctly across all of the related Order objects (items, coupons, etc).
    ///
    func testRetrieveOrdersEffectivelyPersistsOrderFields() {
        let expectation = self.expectation(description: "Persist order list")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrder = sampleOrder()

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Order.self), 0)

        let action = OrderAction.retrieveOrders(siteID: 123) { (orders, error) in
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

    /// Verifies that OrderAction.retrieveOrders returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrdersReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve orders error response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "generic_error")
        let action = OrderAction.retrieveOrders(siteID: 123) { (orders, error) in
            XCTAssertNil(orders)
            XCTAssertNotNil(error)
            guard let _ = error else {
                XCTFail()
                return
            }
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

        let action = OrderAction.retrieveOrders(siteID: 123) { (orders, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(orders)
            guard let _ = error else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        orderStore.onAction(action)
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
        let action = OrderAction.retrieveOrder(siteID: 123, orderID: 963) { (order, error) in
            XCTAssertNil(error)
            guard let order = order else {
                XCTFail()
                return
            }
            XCTAssertEqual(order, remoteOrder)
            expectation.fulfill()
        }

        orderStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderAction.retrieveOrder returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveSingleOrderReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve single order error response")
        let orderStore = OrderStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/963", filename: "generic_error")
        let action = OrderAction.retrieveOrder(siteID: 123, orderID: 963) { (order, error) in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            guard let _ = error else {
                XCTFail()
                return
            }
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

        let action = OrderAction.retrieveOrder(siteID: 123, orderID: 963) { (order, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(order)
            guard let _ = error else {
                XCTFail()
                return
            }
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
        return Order(orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: .processing,
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
                     coupons: sampleCoupons())
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

    func sampleCoupons() -> [Networking.OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "30",
                                      discountTax: "1.2")
        return [coupon1]
    }

    func sampleItems() -> [Networking.OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product)",
                              productID: 52,
                              quantity: 1,
                              sku: "",
                              subtotal: "50.00",
                              subtotalTax: "2.00",
                              taxClass: "",
                              total: "30.00",
                              totalTax: "1.20",
                              variationID: 0)
        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle",
                              productID: 234,
                              quantity: 1,
                              sku: "5555-A",
                              subtotal: "10.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              total: "0.00",
                              totalTax: "0.00",
                              variationID: 0)
        return [item1, item2]
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
