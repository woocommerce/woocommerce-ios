import XCTest
@testable import Networking


/// OrdersRemoteTests:
///
final class OrdersRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID = 1467

    /// Dummy author string
    ///
    let sampleAuthor = "someuser"

    /// Dummy author string for an "admin"
    ///
    let sampleAdminUserAuthor = "someadmin"

    /// Dummy author string for the system
    ///
    let sampleSystemAuthor = "system"

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    // MARK: - Load All Orders Tests

    /// Verifies that loadAllOrders properly parses the `orders-load-all` sample response.
    ///
    func testLoadAllOrdersProperlyReturnsParsedOrders() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load All Orders")

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        remote.loadAllOrders(for: sampleSiteID) { orders, error in
            XCTAssertNil(error)
            XCTAssertNotNil(orders)
            XCTAssert(orders!.count == 4)
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


    // MARK: - Load Order Tests

    /// Verifies that loadOrder properly parses the `order` sample response.
    ///
    func testLoadSingleOrderProperlyReturnsParsedOrder() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load Order")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        remote.loadOrder(for: sampleSiteID, orderID: sampleOrderID) { order, error in
            XCTAssertNil(error)
            XCTAssertNotNil(order)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrder properly relays any Networking Layer errors.
    ///
    func testLoadSingleOrderProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        remote.loadOrder(for: sampleSiteID, orderID: sampleOrderID) { order, error in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Search Orders

    /// Verifies that searchOrders properly parses the `orders-load-all` sample response.
    ///
    func testSearchOrdersProperlyReturnsParsedOrders() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load All Orders")

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        remote.searchOrders(for: sampleSiteID, keyword: String()) { (orders, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orders)
            XCTAssert(orders!.count == 4)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that searchOrders properly relays Networking Layer errors.
    ///
    func testSearchOrdersProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load All Orders")

        remote.searchOrders(for: sampleSiteID, keyword: String()) { (orders, error) in
            XCTAssertNil(orders)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Update Orders Tests

    /// Verifies that updateOrder properly parses the `order` sample response.
    ///
    func testUpdateOrderProperlyReturnsParsedOrder() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: "pending") { (order, error) in
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

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: "pending") { (order, error) in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Load Order Notes Tests

    /// Verifies that loadOrderNotes properly parses the `order-notes` sample response.
    ///
    func testLoadOrderNotesProperlyReturnsParsedNotes() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load Order Notes")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes/", filename: "order-notes")

        remote.loadOrderNotes(for: sampleSiteID, orderID: sampleOrderID) { orderNotes, error in
            XCTAssertNil(error)
            XCTAssertNotNil(orderNotes)
            XCTAssertEqual(orderNotes?.count, 19)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrderNotes properly relays any Networking Layer errors.
    ///
    func testLoadOrderNotesProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Load Order Notes")

        remote.loadOrderNotes(for: sampleSiteID, orderID: sampleOrderID) { orderNotes, error in
            XCTAssertNil(orderNotes)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that addOrderNote properly parses the `new-order-note` sample response.
    ///
    func testLoadAddOrderNoteProperlyReturnsParsedOrderNote() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Add Order Note")
        let noteData = "This order would be so much better with ketchup."

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/notes", filename: "new-order-note")

        remote.addOrderNote(for: sampleSiteID, orderID: sampleOrderID, isCustomerNote: true, with: noteData) { (orderNote, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderNote)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - Count Orders Tests

    /// Verifies that countOrders properly parses response.
    ///
    func testCountOrdersProperlyReturnsParsedOrderCount() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Count Orders")

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "orders-count")

        remote.countOrders(for: sampleSiteID,
                           statusKey: "processing") { orderCount, error in
                            XCTAssertNil(error)
                            XCTAssertNotNil(orderCount)

                            // Take the opportunity to test the custom subscript works
                            let numberOfProcessingOrders = orderCount!["processing"]?.total

                            XCTAssertEqual(numberOfProcessingOrders, 6)

                            expectation.fulfill()

        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that countOrders properly relays Networking Layer errors.
    ///
    func testCountOrdersProperlyRelaysNetwokingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Count Orders")

        remote.countOrders(for: sampleSiteID,
                           statusKey: "processing") { orderCount, error in
                            XCTAssertNil(orderCount)
                            XCTAssertNotNil(error)
                            expectation.fulfill()

        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
