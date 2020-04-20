import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductsSortOrderBottomSheetListSelectorDataSourceTests: XCTestCase {
    func testInitialSelectedValue() {
        let selected = ProductsSortOrder.nameAscending
        let dataSource = ProductsSortOrderBottomSheetListSelectorDataSource(selected: selected)
        XCTAssertEqual(dataSource.selected, selected)
    }

    func testSelectedValueAfterChange() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        var dataSource = ProductsSortOrderBottomSheetListSelectorDataSource(selected: selected)

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
        var dataSource = ProductsSortOrderBottomSheetListSelectorDataSource(selected: selected)
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

    func testCellConfiguration() {
        // Arrange
        let selected = ProductsSortOrder.nameAscending
        let dataSource = ProductsSortOrderBottomSheetListSelectorDataSource(selected: selected)

        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        // Action
        dataSource.configureCell(cell: cell, model: selected)

        // Assert
        XCTAssertEqual(cell.textLabel?.text, selected.actionSheetTitle)
    }
}
