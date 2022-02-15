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
    func testLoadAllOrdersProperlyRelaysNetworkingErrors() throws {
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
    func testLoadSingleOrderProperlyRelaysNetworkingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        remote.loadOrder(for: sampleSiteID, orderID: sampleOrderID) { order, error in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrder fetches metadata
    ///
    func testLoadSingleOrderFetchesMetaData() throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        remote.loadOrder(for: sampleSiteID, orderID: sampleOrderID) { _, _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["_fields"] as? String)
        XCTAssertTrue(received.contains("meta_data"))
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
    func testSearchOrdersProperlyRelaysNetworkingErrors() {
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
    func testUpdateOrderProperlyRelaysNetworkingErrors() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { (order, error) in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_update_order_properly_encodes_shipping_lines_for_removal_from_order() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let shipping = ShippingLine(shippingID: 333, methodTitle: "Shipping", methodID: nil, total: "1.23", totalTax: "", taxes: [])
        let order = Order.fake().copy(shippingLines: [shipping])

        // When
        remote.updateOrder(from: 123, order: order, fields: [.shippingLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["shipping_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": shipping.shippingID,
            "method_title": shipping.methodTitle,
            "method_id": NSNull(),
            "total": shipping.total
        ]
        assertEqual(received, expected)
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
    func testLoadOrderNotesProperlyRelaysNetworkingErrors() {
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

    // MARK: - Create Order Tests

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

    func test_create_order_properly_encodes_custom_status() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let expectedStatusString = "backorder"
        let status = OrderStatusEnum.custom(expectedStatusString)
        let order = Order.fake().copy(status: status)

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.status]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["status"] as? String)
        assertEqual(received, expectedStatusString)
    }

    func test_create_order_properly_encodes_order_items() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let expectedQuantity: Int64 = 2
        let orderItem = OrderItem.fake().copy(productID: 5, quantity: Decimal(expectedQuantity))
        let order = Order.fake().copy(items: [orderItem])

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.items]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["line_items"] as? [[String: AnyHashable]]).first
        let expected: [String: Int64] = [
            "product_id": orderItem.productID,
            "quantity": expectedQuantity
        ]
        assertEqual(received, expected)
    }

    func test_create_order_properly_encodes_addresses() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let address1 = sampleAddress1
        let address2 = sampleAddress2
        let order = Order.fake().copy(billingAddress: address1, shippingAddress: address2)

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.billingAddress, .shippingAddress]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received1 = try XCTUnwrap(request.parameters["billing"] as? [String: AnyHashable])
        let expected1: [String: AnyHashable] = [
            "first_name": address1.firstName,
            "last_name": address1.lastName,
            "address_1": address1.address1,
            "city": address1.city,
            "state": address1.state,
            "postcode": address1.postcode,
            "country": address1.country,
            "email": address1.email ?? "",
            "phone": address1.phone ?? ""
        ]
        assertEqual(received1, expected1)

        let received2 = try XCTUnwrap(request.parameters["shipping"] as? [String: AnyHashable])
        let expected2: [String: AnyHashable] = [
            "first_name": address2.firstName,
            "last_name": address2.lastName,
            "company": address2.company ?? "",
            "address_1": address2.address1,
            "city": address2.city,
            "state": address2.state,
            "postcode": address2.postcode,
            "country": address2.country
        ]
        assertEqual(received2, expected2)
    }

    func test_create_order_properly_encodes_shipping_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let shipping = ShippingLine(shippingID: 333, methodTitle: "Shipping", methodID: "other", total: "1.23", totalTax: "", taxes: [])
        let order = Order.fake().copy(shippingLines: [shipping])

        // When
        remote.createOrder(siteID: 123, order: order, fields: [.shippingLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["shipping_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": shipping.shippingID,
            "method_title": shipping.methodTitle,
            "method_id": shipping.methodID,
            "total": shipping.total
        ]
        assertEqual(received, expected)
    }
}

private extension OrdersRemoteTests {
    var sampleAddress1: Address {
        Address(firstName: "Johnny",
                lastName: "Appleseed",
                company: nil,
                address1: "234 70th Street",
                address2: nil,
                city: "Niagara Falls",
                state: "NY",
                postcode: "14304",
                country: "US",
                phone: "333-333-3333",
                email: "scrambled@scrambled.com")
    }

    var sampleAddress2: Address {
        Address(firstName: "Skylar",
                lastName: "Ferry",
                company: "Automattic Inc.",
                address1: "60 29th Street #343",
                address2: nil,
                city: "New York",
                state: "NY",
                postcode: "94121-2303",
                country: "US",
                phone: nil,
                email: nil)
    }
}
