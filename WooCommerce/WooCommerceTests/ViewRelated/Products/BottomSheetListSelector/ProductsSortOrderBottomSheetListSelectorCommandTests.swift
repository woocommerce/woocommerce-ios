import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsSortOrderBottomSheetListSelectorCommandTests: XCTestCase {
    func testInitialSelectedValue() {
        let selected = ProductsSortOrder.nameAscending
        let dataSource = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)
        XCTAssertEqual(dataSource.selected, selected)
    }

    func testSelectedValueAfterChange() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        var dataSource = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)

        // Action
        let newSelected = ProductsSortOrder.dateDescending
        dataSource.handleSelectedChange(selected: newSelected)

        // Assert
        XCTAssertEqual(dataSource.selected, newSelected)
    }

    func testIsSelectedValueAfterChange() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        let notSelected: [ProductsSortOrder] = [.nameDescending, .dateAscending, .dateDescending]
        var dataSource = ProductsSortOrderBottomSheetListSelectorCommand(selected: selected)
        XCTAssertTrue(dataSource.isSelected(model: selected))
        notSelected.forEach { notSelectedSortOrder in
            XCTAssertFalse(dataSource.isSelected(model: notSelectedSortOrder))
        }

        // Action
        let newSelected = ProductsSortOrder.dateDescending
        let newNotSelected: [ProductsSortOrder] = [.nameDescending, .nameAscending, .dateAscending]
        dataSource.handleSelectedChange(selected: newSelected)

        // Assert
        XCTAssertTrue(dataSource.isSelected(model: newSelected))
        newNotSelected.forEach { notSelectedSortOrder in
            XCTAssertFalse(dataSource.isSelected(model: notSelectedSortOrder))
        }
    }
}
