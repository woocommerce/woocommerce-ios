import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `RefundItemQuantityListSelectorCommand`
///
final class RefundItemQuantityListSelectorCommandTests: XCTestCase {
    func test_command_produces_correct_data_when_max_quantity_is_0() {
        // When
        let command = RefundItemQuantityListSelectorCommand(maxRefundQuantity: 0, currentQuantity: 0)

        // Then
        XCTAssertEqual(command.data, [0])
    }

    func test_commanmd_produces_correct_data_when_max_quantity_is_bigger_than_0() {
        // When
        let command = RefundItemQuantityListSelectorCommand(maxRefundQuantity: 5, currentQuantity: 0)

        // Then
        XCTAssertEqual(command.data, [0, 1, 2, 3, 4, 5])
    }

    func test_command_computes_selected_correctly() {
        // When
        let command = RefundItemQuantityListSelectorCommand(maxRefundQuantity: 5, currentQuantity: 3)

        // Then
        XCTAssertEqual(command.selected, 3)
    }
}
