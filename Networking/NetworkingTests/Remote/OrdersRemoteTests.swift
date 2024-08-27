import XCTest
@testable import Networking
import TestKit


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
    let sampleOrderID: Int64 = 963

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
        let fieldValues = OrdersRemote.ParameterValues.fieldValues

        // Then
        XCTAssertFalse(fieldValues.contains(" "))
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

    func test_loadAllOrders_includes_modifiedAfter_parameter_when_provided() {
        // Given
        let remote = OrdersRemote(network: network)
        let modifiedAfter = Date()
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        _ = waitFor { promise in
            remote.loadAllOrders(for: self.sampleSiteID, modifiedAfter: modifiedAfter) { result in
                promise(result)
            }
        }

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let dateFormatter = DateFormatter.Defaults.iso8601
        let expectedParam = "modified_after=\(dateFormatter.string(from: modifiedAfter))"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    func test_loadAllOrders_includes_customer_parameter_when_provided() {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let expectedCustomerID: Int64 = 123

        // When
        _ = waitFor { promise in
            remote.loadAllOrders(for: self.sampleSiteID, customerID: expectedCustomerID) { result in
                promise(result)
            }
        }

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedParam = "customer=\(expectedCustomerID)"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    func test_loadAllOrders_includes_product_parameter_when_provided() {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let expectedProductID: Int64 = 13

        // When
        _ = waitFor { promise in
            remote.loadAllOrders(for: self.sampleSiteID, productID: expectedProductID) { result in
                promise(result)
            }
        }

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedParam = "product=\(expectedProductID)"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
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

    func test_load_single_order_properly_returns_WC6_6_new_fields() {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        // When
        let order: Order = waitFor { promise in
            remote.loadOrder(for: self.sampleSiteID, orderID: self.sampleOrderID) { order, error in
                if let order = order {
                    promise(order)
                }
            }
        }

        // Then
        XCTAssertTrue(order.isEditable)
        XCTAssertTrue(order.needsPayment)
        XCTAssertTrue(order.needsProcessing)
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
        remote.updateOrder(from: 123, order: order, giftCard: nil, fields: [.shippingLines]) { result in }

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

    func test_update_order_properly_encodes_fee_lines_for_removal_from_order() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let fee = OrderFeeLine(feeID: 333, name: nil, taxClass: "", taxStatus: .none, total: "12.34", totalTax: "", taxes: [], attributes: [])
        let order = Order.fake().copy(fees: [fee])

        // When
        remote.updateOrder(from: 123, order: order, giftCard: nil, fields: [.fees]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": fee.feeID,
            "name": NSNull(),
            "tax_status": fee.taxStatus.rawValue,
            "tax_class": fee.taxClass,
            "total": fee.total
        ]
        assertEqual(expected, received)
    }

    func test_update_order_properly_encodes_custom_status() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let expectedStatusString = "backorder"
        let status = OrderStatusEnum.custom(expectedStatusString)
        let order = Order.fake().copy(orderID: sampleOrderID, status: status)

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.status]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["status"] as? String)
        assertEqual(received, expectedStatusString)
    }

    func test_update_order_properly_encodes_order_items() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let expectedQuantity: Int64 = 2
        let orderItem = OrderItem.fake().copy(itemID: 123, productID: 5, quantity: Decimal(expectedQuantity), subtotal: "3", total: "15")
        let order = Order.fake().copy(items: [orderItem])

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.items]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["line_items"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": orderItem.itemID,
            "product_id": orderItem.productID,
            "quantity": expectedQuantity,
            "subtotal": orderItem.subtotal,
            "total": orderItem.total
        ]
        assertEqual(received, expected)
    }

    func test_update_order_properly_encodes_order_item_bundle_configuration() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let orderItem = OrderItem.fake().copy(itemID: 123, productID: 5, quantity: 2, bundleConfiguration: [
            // Non-variable bundle item
            .init(bundledItemID: 20, productID: 51, quantity: 3, isOptionalAndSelected: true, variationID: nil, variationAttributes: nil),
            // Variable bundle item
            .init(bundledItemID: 21,
                  productID: 52,
                  quantity: 5,
                  isOptionalAndSelected: nil,
                  variationID: 77,
                  variationAttributes: [.init(id: 2, name: "Color", option: "Coral")])
        ])
        let order = Order.fake().copy(items: [orderItem])

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.items]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let lineItem = try XCTUnwrap((request.parameters["line_items"] as? [[String: AnyHashable]])?.first)
        let received = try XCTUnwrap(lineItem["bundle_configuration"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [
            [
                "bundled_item_id": 20,
                "product_id": 51,
                "quantity": 3,
                "optional_selected": true
            ],
            [
                "bundled_item_id": 21,
                "product_id": 52,
                "quantity": 5,
                "variation_id": 77,
                "attributes": [
                    [
                        "id": 2,
                        "name": "Color",
                        "option": "Coral"
                    ] as [String: AnyHashable]
                ] as [AnyHashable]
            ]
        ]
        assertEqual(expected, received)
    }

    func test_update_order_properly_encodes_coupon_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let coupon = OrderCouponLine(couponID: 0, code: "couponcode", discount: "", discountTax: "")
        let order = Order.fake().copy(coupons: [coupon])

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.couponLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["coupon_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "code": coupon.code
        ]
        assertEqual(received, expected)
    }

    func test_update_order_properly_encodes_gift_card() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: "ABAE-DCCA", fields: []) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["gift_cards"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["code": "ABAE-DCCA"]]
        assertEqual(received, expected)
    }

    func test_update_order_when_payment_method_id_and_title_passed_then_request_parameters_set() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake().copy(paymentMethodID: "cod", paymentMethodTitle: "Pay in Person")

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.paymentMethodID, .paymentMethodTitle]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters as? [String: AnyHashable])
        assertEqual(received["payment_method"], "cod")
        assertEqual(received["payment_method_title"], "Pay in Person")
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

    func test_create_order_properly_encodes_coupon_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let coupon = OrderCouponLine(couponID: 0, code: "couponcode", discount: "", discountTax: "")
        let order = Order.fake().copy(coupons: [coupon])

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.couponLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["coupon_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "code": coupon.code
        ]
        assertEqual(received, expected)
    }

    func test_create_order_properly_encodes_fee_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let fee = OrderFeeLine(feeID: 333, name: "Line", taxClass: "", taxStatus: .none, total: "12.34", totalTax: "", taxes: [], attributes: [])
        let order = Order.fake().copy(fees: [fee])

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.feeLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": fee.feeID,
            "name": fee.name ?? "",
            "tax_status": fee.taxStatus.rawValue,
            "tax_class": fee.taxClass,
            "total": fee.total
        ]
        assertEqual(received, expected)
    }

    func test_create_order_when_total_has_special_characters_then_properly_encodes_fee_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let fee = OrderFeeLine(feeID: 333, name: "Line", taxClass: "", taxStatus: .none, total: "1.00د.إ", totalTax: "", taxes: [], attributes: [])
        let order = Order.fake().copy(fees: [fee])

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.feeLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["fee_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": fee.feeID,
            "name": fee.name ?? "",
            "tax_status": fee.taxStatus.rawValue,
            "tax_class": fee.taxClass,
            "total": fee.total
        ]
        assertEqual("1.00د.إ", expected["total"])
        assertEqual(received, expected)
    }

    func test_create_order_properly_encodes_status() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let status = OrderStatusEnum.onHold
        let order = Order.fake().copy(status: status)

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.status]) { result in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.status]) { result in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.items]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["line_items"] as? [[String: AnyHashable]]).first
        let expected: [String: Int64] = [
            "id": 0,
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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.billingAddress, .shippingAddress]) { result in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.shippingLines]) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["shipping_lines"] as? [[String: AnyHashable]]).first
        let expected: [String: AnyHashable] = [
            "id": shipping.shippingID,
            "method_title": shipping.methodTitle,
            "method_id": shipping.methodID ?? "",
            "total": shipping.total
        ]
        assertEqual(received, expected)
    }

    func test_create_order_properly_encodes_gift_card() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: "ABAE-DCCA", fields: []) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["gift_cards"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["code": "ABAE-DCCA"]]
        assertEqual(received, expected)
    }

    func test_create_order_sets_mobile_app_as_source_type_meta_data() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: []) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["meta_data"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["id": 0,
                                                  "key": "_wc_order_attribution_source_type",
                                                  "value": "mobile_app"]]
        assertEqual(received, expected)
    }

    // MARK: - Delete order tests

    func test_delete_order_properly_returns_parsed_order() throws {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        // When
        let result: Result<Order, Error> = waitFor { promise in
            remote.deleteOrder(for: self.sampleSiteID, orderID: self.sampleOrderID, force: false) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let order = try XCTUnwrap(result.get())
        XCTAssertEqual(order.orderID, sampleOrderID)
    }

    func test_delete_order_properly_relays_networking_errors() {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        let result: Result<Order, Error> = waitFor { promise in
            remote.deleteOrder(for: self.sampleSiteID, orderID: self.sampleOrderID, force: false) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNotNil(result.failure)
    }

    func test_delete_order_includes_expected_force_parameter() throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        remote.deleteOrder(for: sampleSiteID, orderID: sampleOrderID, force: true) { result in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["force"] as? String)
        XCTAssertEqual(received, "true")
    }

    // MARK: - Fetch Date Modified Tests

    func test_fetchDateModified_properly_returns_date_modified() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "date-modified-gmt")

        // When
        let date = try await remote.fetchDateModified(for: self.sampleSiteID, orderID: self.sampleOrderID)

        // Then
        let expectedDate = DateFormatter.Defaults.dateTimeFormatter.date(from: "2023-03-29T03:23:02")
        assertEqual(expectedDate, date)
    }

    func test_fetchDateModified_properly_relays_networking_errors() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)", error: expectedError)

        // When & Then
        await assertThrowsError({
            _ = try await remote.fetchDateModified(for: self.sampleSiteID, orderID: self.sampleOrderID)
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
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
