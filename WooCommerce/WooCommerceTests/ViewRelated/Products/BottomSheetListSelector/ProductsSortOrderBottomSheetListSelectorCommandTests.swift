import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsSortOrderBottomSheetListSelectorCommandTests: XCTestCase {
    func testInitialSelectedValue() {
        let selected = ProductsSortOrder.nameAscending
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)
        XCTAssertEqual(command.selected, selected)
    }

    func testSelectedValueAfterChange() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)

        // Action
        let newSelected = ProductsSortOrder.dateDescending
        command.handleSelectedChange(selected: newSelected)

        // Assert
        XCTAssertEqual(command.selected, newSelected)
    }

    func testIsSelectedValueAfterChange() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        let notSelected: [ProductsSortOrder] = [.nameDescending, .dateAscending, .dateDescending]
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)
        XCTAssertTrue(command.isSelected(model: selected))
        notSelected.forEach { notSelectedSortOrder in
            XCTAssertFalse(command.isSelected(model: notSelectedSortOrder))
        }

        // Action
        let newSelected = ProductsSortOrder.dateDescending
        let newNotSelected: [ProductsSortOrder] = [.nameDescending, .nameAscending, .dateAscending]
        command.handleSelectedChange(selected: newSelected)

        // Assert
        XCTAssertTrue(command.isSelected(model: newSelected))
        newNotSelected.forEach { notSelectedSortOrder in
            XCTAssertFalse(command.isSelected(model: notSelectedSortOrder))
        }
    }
}
