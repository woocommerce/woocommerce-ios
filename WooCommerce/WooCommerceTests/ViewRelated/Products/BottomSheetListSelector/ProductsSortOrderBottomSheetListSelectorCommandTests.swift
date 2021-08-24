import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsSortOrderBottomSheetListSelectorCommandTests: XCTestCase {
    func test_initial_selected_value_is_stored_in_command() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        var selectedActions = [ProductsSortOrder]()
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected) { (selected) in
            selectedActions.append(selected)
        }
        // Action
        command.handleSelectedChange(selected: .nameAscending)
        // Assert
        XCTAssertEqual(command.selected, selected)
    }

    func test_selected_value_after_change() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected) { (selected) in
            // noop
        }
        // Assert
        XCTAssertEqual(command.selected, selected)
    }

    func test_isSelected_returns_true_if_given_the_initial_value() {
        // Arrange
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: .nameAscending) { (selected) in
            // noop
        }
        // Action
        let isSelected = command.isSelected(model: .nameAscending)
        // Assert
        XCTAssertTrue(isSelected)
    }
    func test_isSelected_returns_false_if_given_a_different_value() {
        // Arrange
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: .nameAscending) { (selected) in
            // noop
        }
        // Action
        let isSelected = command.isSelected(model: .nameDescending)
        // Assert
        XCTAssertFalse(isSelected)
    }

}
