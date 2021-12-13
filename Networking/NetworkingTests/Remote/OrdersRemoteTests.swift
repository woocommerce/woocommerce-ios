import XCTest
@testable import Networking


/// OrdersRemoteTests:
///
final class OrdersRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID: Int64 = 1467

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

    /// Verifies that the parameter `_fields` in single order and order list requests do not contain whitespace.
    ///
    func test_order_fields_parameter_values_do_not_contain_whitespace() throws {
        // When
        let orderListFieldsValue = OrdersRemote.ParameterValues.listFieldValues
        let orderFieldsValue = OrdersRemote.ParameterValues.singleOrderFieldValues

        // Then
        XCTAssertFalse(orderListFieldsValue.contains(" "))
        XCTAssertFalse(orderFieldsValue.contains(" "))
    }

    // MARK: - Load All Orders Tests

    /// Verifies that loadAllOrders properly parses the `orders-load-all` sample response.
    ///
    func testLoadAllOrdersProperlyReturnsParsedOrders() throws {
        // Given
        let remote = OrdersRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        var result: Result<[Order], Error>?
        waitForExpectation { expectation in
            remote.loadAllOrders(for: sampleSiteID) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        let orders = try XCTUnwrap(result?.get())
        XCTAssert(orders.count == 4)
    }

    /// Verifies that loadAllOrders properly relays Networking Layer errors.
    ///
    func testLoadAllOrdersProperlyRelaysNetwokingErrors() throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        var result: Result<[Order], Error>?
        waitForExpectation { expectation in
            remote.loadAllOrders(for: sampleSiteID) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)
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

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { (order, error) in
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

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { (order, error) in
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

    func test_create_order_properly_encodes_fee_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let fee = OrderFeeLine(feeID: 333, name: "Line", taxClass: "", taxStatus: .none, total: "12.34", totalTax: "", taxes: [], attributes: [])
        let order = Order.fake().copy(fees: [fee])

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.feeLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": fee.feeID,
            "name": fee.name,
            "tax_status": fee.taxStatus.rawValue,
            "tax_class": fee.taxClass,
            "total": fee.total
        ]
        assertEqual(received, expected)
    }

    func test_create_order_properly_encodes_status() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let status = OrderStatusEnum.onHold
        let order = Order.fake().copy(status: status)

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.status]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["status"] as? String)
        assertEqual(received, status.rawValue)
    }
}
