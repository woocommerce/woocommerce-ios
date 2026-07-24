import XCTest
@testable import Networking
@testable import NetworkingCore
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

    func test_order_fields_parameter_includes_created_via_field() throws {
        // When
        let fieldValues = OrdersRemote.ParameterValues.fieldValues

        // Then
        XCTAssertTrue(fieldValues.contains("created_via"), "fieldValues should include 'created_via' field")
    }

    // MARK: - Load All Orders Tests

    /// Verifies that loadAllOrders properly parses the `orders-load-all` sample response.
    ///
    func test_loadAllOrders_properly_returns_parsed_orders() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        let orders = try await remote.loadAllOrders(for: sampleSiteID)

        // Then
        XCTAssert(orders.count == 4)
    }

    /// Verifies that loadAllOrders properly relays Networking Layer errors.
    ///
    func test_loadAllOrders_properly_relays_networking_errors() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When & Then
        do {
            _ = try await remote.loadAllOrders(for: sampleSiteID)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .notFound(response: nil))
        }
    }

    func test_loadAllOrders_includes_modifiedAfter_parameter_when_provided() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let modifiedAfter = Date()
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        _ = try await remote.loadAllOrders(for: sampleSiteID, modifiedAfter: modifiedAfter)

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let dateFormatter = DateFormatter.Defaults.iso8601
        let expectedParam = "modified_after=\(dateFormatter.string(from: modifiedAfter))"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    func test_loadAllOrders_includes_customer_parameter_when_provided() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let expectedCustomerID: Int64 = 123

        // When
        _ = try await remote.loadAllOrders(for: sampleSiteID, customerID: expectedCustomerID)

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedParam = "customer=\(expectedCustomerID)"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    func test_loadAllOrders_includes_product_parameter_when_provided() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")
        let expectedProductID: Int64 = 13

        // When
        _ = try await remote.loadAllOrders(for: sampleSiteID, productID: expectedProductID)

        // Then
        guard let queryParameters = network.queryParameters else {
            XCTFail("Cannot parse query from the API request")
            return
        }

        let expectedParam = "product=\(expectedProductID)"
        XCTAssertTrue(queryParameters.contains(expectedParam), "Expected to have param: \(expectedParam)")
    }

    // MARK: - Load Orders by IDs Tests

    func test_loadOrders_by_ids_when_request_succeeds_returns_parsed_orders() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let orderIDs: [Int64] = [1, 2, 3]
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        let orders = try await remote.loadOrders(for: sampleSiteID, orderIDs: orderIDs)

        // Then
        XCTAssertEqual(orders.count, 4) // The sample file has 4 orders
    }

    func test_loadOrders_by_ids_when_invoked_sends_correct_parameters() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let orderIDs: [Int64] = [1, 2, 3, 2] // with duplicate
        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        _ = try await remote.loadOrders(for: sampleSiteID, orderIDs: orderIDs)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let parameters = request.parameters

        let includeValue = parameters["include"] as? String
        let includedIDs = includeValue?.split(separator: ",").map { String($0) }
        XCTAssertNotNil(includeValue)
        XCTAssertEqual(Set(includedIDs ?? []), Set(["1", "2", "3"])) // check for unique ids

        XCTAssertNotNil(parameters["_fields"])
        XCTAssertEqual(parameters["per_page"] as? String, "4") // per_page matches order ID count
    }

    func test_loadOrders_by_ids_with_empty_ids_returns_empty_array_and_makes_no_request() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        let orders = try await remote.loadOrders(for: sampleSiteID, orderIDs: [])

        // Then
        XCTAssertTrue(orders.isEmpty)
        XCTAssertTrue(network.requestsForResponseData.isEmpty) // No network request should be made
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
            remote.loadOrder(for: self.sampleSiteID, orderID: self.sampleOrderID) { order, _ in
                if let order {
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
    func test_searchOrders_properly_returns_parsed_orders() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "orders", filename: "orders-load-all")

        // When
        let orders = try await remote.searchOrders(for: sampleSiteID, keyword: String())

        // Then
        XCTAssert(orders.count == 4)
    }

    /// Verifies that searchOrders properly relays Networking Layer errors.
    ///
    func test_searchOrders_properly_relays_networking_error() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        do {
            // When
            _ = try await remote.searchOrders(for: sampleSiteID, keyword: String())
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, .notFound(response: nil))
        }
    }


    // MARK: - Update Orders Tests

    /// Verifies that updateOrder properly parses the `order` sample response.
    ///
    func testUpdateOrderProperlyReturnsParsedOrder() {
        let remote = OrdersRemote(network: network)
        let expectation = self.expectation(description: "Update Order")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)", filename: "order")

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { order, error in
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

        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { order, error in
            XCTAssertNil(order)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func test_updateOrder_status_includes_decimal_places_parameter() throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        remote.updateOrder(from: sampleSiteID, orderID: sampleOrderID, statusKey: .pending) { _, _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["dp"] as? String)
        assertEqual(received, "8")
    }

    func test_update_order_properly_encodes_shipping_lines_for_removal_from_order() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let shipping = ShippingLine(shippingID: 333, methodTitle: "Shipping", methodID: nil, total: "1.23", totalTax: "", taxes: [])
        let order = Order.fake().copy(shippingLines: [shipping])

        // When
        remote.updateOrder(from: 123, order: order, giftCard: nil, fields: [.shippingLines]) { _ in }

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
        remote.updateOrder(from: 123, order: order, giftCard: nil, fields: [.fees]) { _ in }

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
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.status]) { _ in }

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
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.items]) { _ in }

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
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.items]) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let lineItemsValue = try XCTUnwrap(request.requestParameters.dictionary?["line_items"])
        guard case .array(let lineItems) = lineItemsValue else {
            return XCTFail("Expected line_items array")
        }
        let firstLineItem = try XCTUnwrap(lineItems.first)
        guard case .dictionary(let lineItem) = firstLineItem else {
            return XCTFail("Expected line item dictionary")
        }
        let received = try XCTUnwrap(lineItem["bundle_configuration"])
        let expected: RequestParameterValue = .array([
            .dictionary([
                "bundled_item_id": .int(20),
                "product_id": .int(51),
                "quantity": .int(3),
                "optional_selected": .bool(true)
            ]),
            .dictionary([
                "bundled_item_id": .int(21),
                "product_id": .int(52),
                "quantity": .int(5),
                "variation_id": .int(77),
                "attributes": .array([
                    .dictionary([
                        "id": .int(2),
                        "name": .string("Color"),
                        "option": .string("Coral")
                    ])
                ])
            ])
        ])
        XCTAssertEqual(expected, received)
    }

    func test_update_order_properly_encodes_coupon_lines() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let coupon = OrderCouponLine(couponID: 0, code: "couponcode", discount: "", discountTax: "")
        let order = Order.fake().copy(coupons: [coupon])

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.couponLines]) { _ in }

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
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: "ABAE-DCCA", fields: []) { _ in }

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
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.paymentMethodID, .paymentMethodTitle]) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters as? [String: AnyHashable])
        assertEqual(received["payment_method"], "cod")
        assertEqual(received["payment_method_title"], "Pay in Person")
    }

    func test_updateOrder_with_cashPaymentChangeDueAmount_encodes_cash_payment_change_due_amount() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()
        let cashPaymentChangeDueAmount = "$6.00"

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, cashPaymentChangeDueAmount: cashPaymentChangeDueAmount, fields: []) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["meta_data"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["id": 0,
                                                  "key": "_cash_change_amount",
                                                  "value": cashPaymentChangeDueAmount]]
        assertEqual(received, expected)
    }

    func test_updateOrder_without_cashPaymentChangeDueAmount_does_not_include_meta_data() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: []) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        XCTAssertNil(request.parameters["meta_data"])
    }

    func test_updateOrder_with_fields_includes_decimal_places_parameter() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.updateOrder(from: sampleSiteID, order: order, giftCard: nil, fields: [.customerNote]) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["dp"] as? String)
        assertEqual(received, "8")
    }

    func test_updateOrder_with_request_currency_encodes_currency_in_tunnel_path_and_preserves_body() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake().copy(orderID: sampleOrderID, customerNote: "Updated note")

        // When
        remote.updateOrder(from: sampleSiteID,
                           order: order,
                           giftCard: nil,
                           fields: [.customerNote],
                           requestCurrency: "EUR") { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let urlRequest = try request.asURLRequest()
        let path = try encodedFormField(named: "path", in: urlRequest)
        let body = try encodedFormField(named: "body", in: urlRequest)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
        XCTAssertEqual(path, "/wc/v3/orders/\(sampleOrderID)&currency=EUR&_method=post")
        XCTAssertEqual(payload["customer_note"] as? String, "Updated note")
        XCTAssertNil(payload["currency"])
    }

    func test_updateOrder_with_request_currency_preserves_query_when_converted_to_REST() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake().copy(orderID: sampleOrderID, customerNote: "Updated note")

        // When
        remote.updateOrder(from: sampleSiteID,
                           order: order,
                           giftCard: nil,
                           fields: [.customerNote],
                           requestCurrency: "EUR") { _ in }

        // Then
        let jetpackRequest = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let request = try XCTUnwrap(jetpackRequest.asRESTRequest(with: "https://example.com"))
        let urlRequest = try request.asURLRequest()
        let queryItems = URLComponents(url: try XCTUnwrap(urlRequest.url), resolvingAgainstBaseURL: false)?.queryItems
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(urlRequest.httpBody)) as? [String: Any])
        XCTAssertEqual(queryItems?.first { $0.name == "currency" }?.value, "EUR")
        XCTAssertEqual(payload["customer_note"] as? String, "Updated note")
        XCTAssertNil(payload["currency"])
    }

    func test_updateOrder_without_request_currency_omits_currency_query() throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        remote.updateOrder(from: sampleSiteID, order: .fake().copy(orderID: sampleOrderID), giftCard: nil, fields: []) { _ in }

        // Then
        let jetpackRequest = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        XCTAssertNil(jetpackRequest.queryParameters.dictionary)
        let request = try XCTUnwrap(jetpackRequest.asRESTRequest(with: "https://example.com"))
        let queryItems = URLComponents(url: try XCTUnwrap(request.asURLRequest().url), resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertNil(queryItems?.first { $0.name == "currency" })
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

        remote.addOrderNote(for: sampleSiteID, orderID: sampleOrderID, isCustomerNote: true, with: noteData) { orderNote, error in
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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.couponLines]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.feeLines]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.feeLines]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.status]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.status]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.items]) { _ in }

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

    func test_create_order_jetpack_body_preserves_nested_parameter_arrays() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let orderItem = OrderItem.fake().copy(productID: 5, quantity: 2)
        let order = Order.fake().copy(items: [orderItem])

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.items]) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let urlRequest = try request.asURLRequest()
        let body = try encodedFormField(named: "body", in: urlRequest)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
        assertOrderCreationPayloadPreservesNumericScalars(payload)
    }

    func test_create_order_rest_body_preserves_nested_parameter_arrays() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let orderItem = OrderItem.fake().copy(productID: 5, quantity: 2)
        let order = Order.fake().copy(items: [orderItem])

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.items]) { _ in }

        // Then
        let jetpackRequest = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let request = try XCTUnwrap(jetpackRequest.asRESTRequest(with: "https://example.com"))
        let urlRequest = try request.asURLRequest()
        let body = try XCTUnwrap(urlRequest.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        assertOrderCreationPayloadPreservesNumericScalars(payload)
    }

    func test_create_order_properly_encodes_addresses() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let address1 = sampleAddress1
        let address2 = sampleAddress2
        let order = Order.fake().copy(billingAddress: address1, shippingAddress: address2)

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.billingAddress, .shippingAddress]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: [.shippingLines]) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: "ABAE-DCCA", fields: []) { _ in }

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
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: []) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["meta_data"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["id": 0,
                                                  "key": "_wc_order_attribution_source_type",
                                                  "value": "mobile_app"]]
        assertEqual(received, expected)
    }

    func test_createPOSOrder_sets_created_via_for_point_of_sale() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        _ = try? await remote.createPOSOrder(siteID: 123, order: order, fields: [])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["created_via"] as? String)
        assertEqual(received, "pos-rest-api")
    }

    func test_createOrder_without_source_parameter_does_not_set_created_via() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: []) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        XCTAssertNil(request.parameters["created_via"])
    }

    func test_createOrder_includes_decimal_places_parameter() throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()

        // When
        remote.createOrder(siteID: 123, order: order, giftCard: nil, fields: []) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["dp"] as? String)
        assertEqual(received, "8")
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
        remote.deleteOrder(for: sampleSiteID, orderID: sampleOrderID, force: true) { _ in }

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

    // MARK: - POS Orders Tests

    func test_updatePOSOrder_encodes_cash_payment_change_due_amount() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let order = Order.fake()
        let cashPaymentChangeDueAmount = "$6.00"

        // When
        _ = try? await remote.updatePOSOrder(siteID: sampleSiteID, order: order, cashPaymentChangeDueAmount: cashPaymentChangeDueAmount, fields: [])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let received = try XCTUnwrap(request.parameters["meta_data"] as? [[String: AnyHashable]])
        let expected: [[String: AnyHashable]] = [["id": 0,
                                                  "key": "_cash_change_amount",
                                                  "value": cashPaymentChangeDueAmount]]
        assertEqual(received, expected)
    }

    func test_searchPOSOrders_sends_correct_parameters() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let searchTerm = "test search"
        let pageNumber = 2
        let pageSize = 10

        // When
        _ = try? await remote.searchPOSOrders(siteID: sampleSiteID, searchTerm: searchTerm, pageNumber: pageNumber, pageSize: pageSize)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let parameters = request.parameters

        XCTAssertEqual(parameters["search"] as? String, searchTerm)
        XCTAssertEqual(parameters["page"] as? String, String(pageNumber))
        XCTAssertEqual(parameters["per_page"] as? String, String(pageSize))
        XCTAssertEqual(parameters["status"] as? String, "any")
        XCTAssertEqual(parameters["created_via"] as? String, "pos-rest-api")
        XCTAssertEqual(parameters["dates_are_gmt"] as? Bool, true)
        let fields = try XCTUnwrap(parameters["_fields"] as? String)
        XCTAssertFalse(fields.contains("meta_data"))
    }

    func test_loadPOSOrders_sends_correct_parameters() async throws {
        // Given
        let remote = OrdersRemote(network: network)
        let pageNumber = 3
        let pageSize = 25

        // When
        _ = try? await remote.loadPOSOrders(siteID: sampleSiteID, pageNumber: pageNumber, pageSize: pageSize)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let parameters = request.parameters

        XCTAssertEqual(parameters["page"] as? String, String(pageNumber))
        XCTAssertEqual(parameters["per_page"] as? String, String(pageSize))
        XCTAssertEqual(parameters["status"] as? String, "any")
        XCTAssertEqual(parameters["created_via"] as? String, "pos-rest-api")
        XCTAssertEqual(parameters["dates_are_gmt"] as? Bool, true)
        let fields = try XCTUnwrap(parameters["_fields"] as? String)
        XCTAssertFalse(fields.contains("meta_data"))
    }

    func test_loadPOSOrders_by_orderIDs_excludes_meta_data_from_fields() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        // When
        _ = try? await remote.loadPOSOrders(siteID: sampleSiteID, orderIDs: [sampleOrderID])

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? JetpackRequest)
        let parameters = request.parameters

        XCTAssertEqual(parameters["include"] as? String, String(sampleOrderID))
        let fields = try XCTUnwrap(parameters["_fields"] as? String)
        XCTAssertFalse(fields.contains("meta_data"))
    }

    func test_searchPOSOrders_properly_relays_networking_error() async throws {
        // Given
        let remote = OrdersRemote(network: network)

        do {
            // When
            _ = try await remote.searchPOSOrders(siteID: sampleSiteID, searchTerm: "test", pageNumber: 1, pageSize: 25)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, .notFound(response: nil))
        }
    }
}

private extension OrdersRemoteTests {
    func encodedFormField(named name: String, in request: URLRequest) throws -> String {
        let body = try XCTUnwrap(request.httpBody)
        let query = try XCTUnwrap(String(data: body, encoding: .utf8))
        let components = URLComponents(string: "https://example.com?\(query)")
        return try XCTUnwrap(components?.queryItems?.first { $0.name == name }?.value)
    }

    func assertOrderCreationPayloadPreservesNumericScalars(_ payload: [String: Any]) {
        guard let lineItem = (payload["line_items"] as? [[String: Any]])?.first else {
            return XCTFail("Expected line_items in order creation payload")
        }
        XCTAssertEqual(number(lineItem["id"]), 0)
        XCTAssertEqual(number(lineItem["product_id"]), 5)
        XCTAssertEqual(number(lineItem["quantity"]), 2)
        XCTAssertFalse(isBoolean(lineItem["id"]))
        XCTAssertFalse(isBoolean(lineItem["product_id"]))
        XCTAssertFalse(isBoolean(lineItem["quantity"]))

        guard let metadata = (payload["meta_data"] as? [[String: Any]])?.first else {
            return XCTFail("Expected meta_data in order creation payload")
        }
        XCTAssertEqual(number(metadata["id"]), 0)
        XCTAssertFalse(isBoolean(metadata["id"]))
    }

    func number(_ value: Any?) -> Int64? {
        switch value {
        case let value as Int:
            return Int64(value)
        case let value as Int64:
            return value
        case let value as NSNumber where CFGetTypeID(value) != CFBooleanGetTypeID():
            return value.int64Value
        default:
            return nil
        }
    }

    func isBoolean(_ value: Any?) -> Bool {
        guard let value = value as? NSNumber else {
            return false
        }
        return CFGetTypeID(value) == CFBooleanGetTypeID()
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
