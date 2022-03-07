import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class ShippingInputTransformerTests: XCTestCase {

    private let sampleShippingID: Int64 = 123
    private let sampleMethodID = "other"

    func test_new_input_adds_shipping_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: sampleMethodID, total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine, input)
        XCTAssertEqual(updatedOrder.shippingTotal, input.total)
    }

    func test_new_input_updates_shipping_line_from_order() throws {
        // Given
        let shipping = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: sampleMethodID, total: "10.00")
        let order = Order.fake().copy(shippingLines: [shipping])

        // When
        let input = ShippingLine.fake().copy(methodID: sampleMethodID, total: "12.00")
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine.shippingID, shipping.shippingID)
        XCTAssertEqual(shippingLine.methodID, input.methodID)
        XCTAssertEqual(shippingLine.total, input.total)
        XCTAssertEqual(updatedOrder.shippingTotal, input.total)
    }

    func test_new_input_deletes_shipping_line_from_order() throws {
        // Given
        let shipping = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: sampleMethodID, total: "10.00")
        let order = Order.fake().copy(shippingLines: [shipping])

        // When
        let updatedOrder = ShippingInputTransformer.update(input: nil, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertNil(shippingLine.methodID)
        XCTAssertEqual(shippingLine.shippingID, shipping.shippingID)
        XCTAssertEqual(shippingLine.total, "0")
        XCTAssertEqual(updatedOrder.shippingTotal, "0")
    }
}
