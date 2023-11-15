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
        let updatedOrder = FeesInputTransformer.append(input: input, on: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees.first)
        XCTAssertEqual(feeLine, input)
    }

    func test_remove_then_removes_specified_fee() throws {
        // Given
        let removingFeeID: Int64 = 12345
        let fee = OrderFeeLine.fake().copy(feeID: sampleFeeID, name: sampleFeeName, total: "10.0")
        let fee2 = OrderFeeLine.fake().copy(feeID: removingFeeID, name: sampleFeeName, total: "12.0")
        let order = Order.fake().copy(fees: [fee, fee2])

        // When
        let updatedOrder = FeesInputTransformer.remove(input: fee2, from: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees.first(where: { $0.feeID == fee2.feeID }))
        XCTAssertTrue(feeLine.isDeleted)
    }

    func test_update_then_updates_existing_fee() throws {
        // Given
        let newSampleFeeName = "new"
        let newFeeTotal = "2.0"
        let fee = OrderFeeLine.fake().copy(feeID: 1, name: sampleFeeName, total: "10.0")
        let fee2 = OrderFeeLine.fake().copy(feeID: 2, name: sampleFeeName, total: "12.0")
        let fee3 = OrderFeeLine.fake().copy(feeID: 3, name: sampleFeeName, total: "12.0")
        let fees = [fee, fee2, fee3]
        let order = Order.fake().copy(fees: fees)

        // When
        let input = OrderFeeLine.fake().copy(feeID: fee2.feeID, name: newSampleFeeName, total: newFeeTotal)
        let updatedOrder = FeesInputTransformer.update(input: input, on: order)

        // Then
        let feeLine = try XCTUnwrap(updatedOrder.fees[safe: 1])
        XCTAssertEqual(feeLine.feeID, fee2.feeID)
        XCTAssertEqual(feeLine.name, newSampleFeeName)
        XCTAssertEqual(feeLine.total, newFeeTotal)
    }

    func test_update_when_the_fee_is_not_included_then_it_does_nothing() throws {
        // Given
        let newSampleFeeID: Int64 = 12345
        let newSampleFeeName = "new"
        let newFeeTotal = "2.0"
        let fee = OrderFeeLine.fake().copy(feeID: 1, name: sampleFeeName, total: "10.0")
        let fee2 = OrderFeeLine.fake().copy(feeID: 2, name: sampleFeeName, total: "12.0")
        let fee3 = OrderFeeLine.fake().copy(feeID: 3, name: sampleFeeName, total: "12.0")
        let fees = [fee, fee2, fee3]
        let order = Order.fake().copy(fees: fees)

        // When
        let input = OrderFeeLine.fake().copy(feeID: newSampleFeeID, name: newSampleFeeName, total: newFeeTotal)
        let updatedOrder = FeesInputTransformer.update(input: input, on: order)

        // Then
        XCTAssertEqual(updatedOrder.fees, fees)
    }
}
