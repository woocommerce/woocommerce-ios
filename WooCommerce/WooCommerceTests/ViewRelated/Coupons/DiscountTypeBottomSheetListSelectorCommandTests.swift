import XCTest
@testable import WooCommerce
@testable import Yosemite

final class DiscountTypeBottomSheetListSelectorCommandTests: XCTestCase {
    func test_callback_is_called_on_selection() {
        // Given
        var selectedActions = [Coupon.DiscountType]()
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: .percent) { (selected) in
            selectedActions.append(selected)
        }

        // When
        command.handleSelectedChange(selected: .fixedProduct)
        command.handleSelectedChange(selected: .fixedCart)
        command.handleSelectedChange(selected: .percent)

        // Then
        let expectedActions: [Coupon.DiscountType] = [
            .fixedProduct,
            .fixedCart,
            .percent
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }

    func test_isSelected_returns_true_if_given_the_initial_value() {
        // Given
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: .percent) { _ in }

        // When
        let isSelected = command.isSelected(model: .percent)

        // Then
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returns_false_if_given_a_different_value() {
        // Given
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: .percent) { _ in }

        // When
        let isSelected = command.isSelected(model: .fixedCart)

        // Then
        XCTAssertFalse(isSelected)
    }
}
