import XCTest
@testable import Networking
@testable import NetworkingCore

final class POSOrderListMapperTests: XCTestCase {
    private let dummySiteID: Int64 = 242424

    func test_map_skips_order_with_missing_required_top_level_field_and_keeps_valid_orders() throws {
        let response = try makeOrdersResponse { malformedOrder in
            malformedOrder.removeValue(forKey: "total")
        }

        let orders = try POSOrderListMapper(siteID: dummySiteID).map(response: response)

        XCTAssertEqual(orders.map(\.orderID), [964])
    }

    func test_map_skips_order_with_nested_decoding_failure_and_keeps_valid_orders() throws {
        let response = try makeOrdersResponse { malformedOrder in
            guard var lineItems = malformedOrder["line_items"] as? [[String: Any]],
                  var firstLineItem = lineItems.first else {
                return
            }
            firstLineItem["taxes"] = [
                [
                    "id": 1,
                    "subtotal": "1.00"
                ]
            ]
            lineItems[0] = firstLineItem
            malformedOrder["line_items"] = lineItems
        }

        let orders = try POSOrderListMapper(siteID: dummySiteID).map(response: response)

        XCTAssertEqual(orders.map(\.orderID), [964])
    }

    func test_map_skips_malformed_orders_when_response_has_data_envelope() throws {
        let response = try makeOrdersResponse(hasDataEnvelope: true) { malformedOrder in
            malformedOrder.removeValue(forKey: "total")
        }

        let orders = try POSOrderListMapper(siteID: dummySiteID).map(response: response)

        XCTAssertEqual(orders.map(\.orderID), [964])
    }

    func test_regular_order_list_mapper_still_throws_for_missing_required_fields() throws {
        let response = try makeOrdersResponse { malformedOrder in
            malformedOrder.removeValue(forKey: "total")
        }

        XCTAssertThrowsError(try OrderListMapper(siteID: dummySiteID).map(response: response))
    }
}

private extension POSOrderListMapperTests {
    func makeOrdersResponse(
        hasDataEnvelope: Bool = false,
        mutateMalformedOrder: (inout [String: Any]) -> Void
    ) throws -> Data {
        let response = try XCTUnwrap(Loader.contentsOf("orders-load-all-without-data"))
        let sourceOrders = try XCTUnwrap(JSONSerialization.jsonObject(with: response) as? [[String: Any]])
        let sourceOrder = try XCTUnwrap(sourceOrders.first)

        var malformedOrder = sourceOrder
        mutateMalformedOrder(&malformedOrder)

        var validOrder = sourceOrder
        validOrder["id"] = 964
        validOrder["number"] = "964"

        let orders = [malformedOrder, validOrder]
        let payload: Any = hasDataEnvelope ? ["data": orders] : orders
        return try JSONSerialization.data(withJSONObject: payload)
    }
}
