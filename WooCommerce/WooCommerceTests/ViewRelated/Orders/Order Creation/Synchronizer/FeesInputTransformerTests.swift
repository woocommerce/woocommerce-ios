import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class FeesInputTransformerTests: XCTestCase {

    private let sampleFeeID: Int64 = 123
    private let sampleFeeName = "other"

    func test_new_input_adds_fee_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = OrderFeeLine.fake().copy(name: sampleFeeName, total: "10.0")

        // When
        let updatedOrder = FeesInputTransformer.update(input: input, on: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees.first)
        XCTAssertEqual(feeLine, input)
    }

    func test_new_input_updates_first_fee_line_from_order() throws {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: sampleFeeName, total: "10.0")
        let fee2 = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: sampleFeeName, total: "12.0")
        let order = Order.fake().copy(fees: [fee, fee2])

        // When
        let input = OrderFeeLine.fake().copy(name: sampleFeeName, total: "8.0")
        let updatedOrder = FeesInputTransformer.update(input: input, on: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees.first)
        XCTAssertEqual(feeLine.feeID, fee.feeID)
        XCTAssertEqual(feeLine.name, input.name)
        XCTAssertEqual(feeLine.total, input.total)
        let allFeesTotal = updatedOrder.fees.reduce(0) { accumulator, feeLine in
            accumulator + (Double(feeLine.total) ?? .zero)
        }
        XCTAssertEqual(allFeesTotal, 20)

        let feeLine2 = try XCTUnwrap(updatedOrder.fees[safe: 1])
        XCTAssertEqual(fee2, feeLine2)
    }

    func test_new_input_deletes_first_fee_line_from_order() throws {
        // Given
        let fee = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: sampleFeeName, total: "10.0")
        let fee2 = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: sampleFeeName, total: "12.0")
        let order = Order.fake().copy(fees: [fee, fee2])

        // When
        let updatedOrder = FeesInputTransformer.update(input: nil, on: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees.first)
        XCTAssertNil(feeLine.name)
        XCTAssertEqual(feeLine.feeID, fee.feeID)
        XCTAssertEqual(feeLine.total, "0")
        let allFeesTotal = updatedOrder.fees.reduce(0) { accumulator, feeLine in
            accumulator + (Double(feeLine.total) ?? .zero)
        }
        XCTAssertEqual(allFeesTotal, 12)

        let feeLine2 = try XCTUnwrap(updatedOrder.fees[safe: 1])
        XCTAssertEqual(fee2, feeLine2)
    }
}
