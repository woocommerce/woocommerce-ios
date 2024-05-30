import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class ShippingInputTransformerTests: XCTestCase {

    private let sampleShippingID: Int64 = 123
    private let sampleMethodID = "other"

    // MARK: Multiple Shipping Lines Enabled

    func test_new_input_adds_shipping_line_to_order() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)

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
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)

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
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)

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
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)

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

    // MARK: Multiple Shipping Lines Disabled

    func test_new_input_adds_shipping_line_to_order_with_feature_flag_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: sampleMethodID, total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine, input)
        XCTAssertEqual(updatedOrder.shippingTotal, input.total)
    }

    func test_new_input_adds_expected_shipping_line_to_order_with_feature_flag_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: "flat_rate", total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine, input)
        XCTAssertEqual(updatedOrder.shippingTotal, input.total)
    }

    func test_new_input_with_no_shipping_method_adds_expected_shipping_line_to_order_with_feature_flag_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        let order = Order.fake()
        let input = ShippingLine.fake().copy(methodID: "", total: "10.00")

        // When
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine, input.copy(methodID: " "))
        XCTAssertEqual(updatedOrder.shippingTotal, input.total)
    }

    func test_new_input_deletes_matching_shipping_line_from_order_with_feature_flag_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        let shipping = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: sampleMethodID, total: "10.00")
        let shipping2 = ShippingLine.fake().copy(shippingID: sampleShippingID + 1, methodID: sampleMethodID, total: "12.00")
        let order = Order.fake().copy(shippingLines: [shipping, shipping2])

        // When
        let updatedOrder = ShippingInputTransformer.remove(input: shipping2, from: order)

        // Then
        let shippingLineToRemove = try XCTUnwrap(updatedOrder.shippingLines[safe: 1])
        XCTAssertNil(shippingLineToRemove.methodID)
        XCTAssertEqual(shippingLineToRemove.shippingID, shipping2.shippingID)
        XCTAssertEqual(shippingLineToRemove.total, "0")
        XCTAssertEqual(updatedOrder.shippingTotal, "10.0")

        let remainingShippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shipping, remainingShippingLine)
    }

    func test_new_input_updates_first_shipping_line_from_order_with_feature_flag_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isMultipleShippingLinesEnabled: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        let shipping = ShippingLine.fake().copy(shippingID: sampleShippingID, methodID: sampleMethodID, total: "10.00")
        let shipping2 = ShippingLine.fake().copy(shippingID: sampleShippingID + 1, methodID: sampleMethodID, total: "12.00")
        let order = Order.fake().copy(shippingLines: [shipping, shipping2])

        // When
        let input = ShippingLine.fake().copy(methodID: sampleMethodID, total: "12.00")
        let updatedOrder = ShippingInputTransformer.update(input: input, on: order)

        // Then
        let shippingLine = try XCTUnwrap(updatedOrder.shippingLines.first)
        XCTAssertEqual(shippingLine.shippingID, shipping.shippingID)
        XCTAssertEqual(shippingLine.methodID, input.methodID)
        XCTAssertEqual(shippingLine.total, input.total)
        XCTAssertEqual(updatedOrder.shippingTotal, "24.0")

        let shippingLine2 = try XCTUnwrap(updatedOrder.shippingLines[safe: 1])
        XCTAssertEqual(shipping2, shippingLine2)
    }
}
