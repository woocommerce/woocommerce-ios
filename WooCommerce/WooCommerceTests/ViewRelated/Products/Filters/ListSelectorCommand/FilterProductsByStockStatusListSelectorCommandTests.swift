import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductsByStockStatusListSelectorCommandTests: XCTestCase {
    func testSelectedIsSetCorrectlyAfterSelections() {
        let stockStatus = ProductStockStatus.outOfStock
        var selectedStockStatus: ProductStockStatus? = stockStatus
        let command = FilterProductsByStockStatusListSelectorCommand(selected: stockStatus) { selected in
            selectedStockStatus = selected
        }
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, stockStatus)

        let newStockStatus: ProductStockStatus? = nil
        command.handleSelectedChange(selected: newStockStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newStockStatus)
        XCTAssertEqual(selectedStockStatus, newStockStatus)

        // Selecting the same data twice should not affect the selected data.
        command.handleSelectedChange(selected: newStockStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newStockStatus)
        XCTAssertEqual(selectedStockStatus, newStockStatus)
    }

    // MARK: Cell Configuration

    func testCellConfigurationForNilValue() {
        let stockStatus: ProductStockStatus? = nil
        let command = FilterProductsByStockStatusListSelectorCommand(selected: stockStatus) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: stockStatus)

        XCTAssertEqual(cell.textLabel?.text, NSLocalizedString("Any", comment: "Title when there is no filter set."))
    }

    func testCellConfigurationForNonNilValue() {
        let stockStatus = ProductStockStatus.outOfStock
        let command = FilterProductsByStockStatusListSelectorCommand(selected: stockStatus) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: stockStatus)

        XCTAssertEqual(cell.textLabel?.text, stockStatus.description)
    }
}
