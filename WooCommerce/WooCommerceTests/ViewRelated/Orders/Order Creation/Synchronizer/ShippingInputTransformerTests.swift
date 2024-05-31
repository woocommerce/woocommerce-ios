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
        assertEqual(input, shippingLine)
        assertEqual("10.0", updatedOrder.shippingTotal)
    }

    func test_new_input_adds_expected_shipping_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: "flat_rate", total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        assertEqual(input, shippingLine)
        assertEqual("10.0", updatedOrder.shippingTotal)
    }

    func test_new_input_with_no_shipping_method_adds_expected_shipping_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: "", total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        assertEqual(input.copy(methodID: " "), shippingLine)
        assertEqual("10.0", updatedOrder.shippingTotal)
    }

    func test_new_input_updates_matching_shipping_line_from_order() throws {
        // Given
        let shipping = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: sampleMethodID, total: "10.00")
        let shipping2 = ShippingLine.fake().copy(shippingID: sampleShippingID + 1, methodID: sampleMethodID, total: "12.00")
        let order = Order.fake().copy(shippingLines: [shipping, shipping2])

        // When
        let input = shipping2.copy(total: "10.00")
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let updatedShippingLine = try XCTUnwrap(updatedOrder.shippingLines[safe: 1])
        assertEqual(input.shippingID, updatedShippingLine.shippingID)
        assertEqual(input.methodID, updatedShippingLine.methodID)
        assertEqual(input.total, updatedShippingLine.total)
        assertEqual("20.0", updatedOrder.shippingTotal)

        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        assertEqual(shippingLine, shipping)
    }
}
