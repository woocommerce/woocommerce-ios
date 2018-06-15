import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// AccountStore Unit Tests
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


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    /// Verifies that OrderAction.retrieveOrders returns the expected Orders.
    ///
    func testRetrieveOrdersReturnsExpectedFields() {
        let expectation = self.expectation(description: "Synchronize")
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
}


// MARK: - Private Methods
//
private extension OrderStoreTests {
    func sampleOrder() -> Networking.Order {
        return Networking.Order(orderID: 963,
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
                     items: [],
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress())
    }

    func sampleAddress() -> Networking.Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street.",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US")
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
