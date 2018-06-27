import XCTest
@testable import Networking


/// OrdersRemoteTests:
///
class OrdersRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID = 1467


    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadAllOrders properly parses the `orders-load-all` sample response.
    ///
    func testLoadAllOrdersProperlyReturnsParsedOrders() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load All Orders")

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        remote.loadAllOrders(for: sampleSiteID) { orders, error in
            XCTAssertNil(error)
            XCTAssertNotNil(orders)
            XCTAssert(orders!.count == 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadAllOrders properly relays Networking Layer errors.
    ///
    func testLoadAllOrdersProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load All Orders")

        remote.loadAllOrders(for: sampleSiteID) { orders, error in
            XCTAssertNil(orders)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateOrder properly parses the `order` sample response.
    ///
    func testUpdateOrderProperlyReturnsParsedOrder() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, status: "pending") { (order, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(order)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that updateOrder properly relays any Networking Layer errors.
    ///
    func testUpdateOrderProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, status: "pending") { (order, error) in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
