import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductsByProductTypeListSelectorCommandTests: XCTestCase {
    func testSelectedIsSetCorrectlyAfterSelections() {
        let productType = ProductType.variable
        var selectedProductType: ProductType? = productType
        let command = FilterProductsByProductTypeListSelectorCommand(selected: productType) { selected in
            selectedProductType = selected
        }
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, productType)

        let newProductType: ProductType? = nil
        command.handleSelectedChange(selected: newProductType, viewController: viewController)
        XCTAssertEqual(command.selected, newProductType)
        XCTAssertEqual(selectedProductType, newProductType)

        // Selecting the same data twice should not affect the selected data.
        command.handleSelectedChange(selected: newProductType, viewController: viewController)
        XCTAssertEqual(command.selected, newProductType)
        XCTAssertEqual(selectedProductType, newProductType)
    }

    // MARK: Cell Configuration

    func testCellConfigurationForNilValue() {
        let productType: ProductType? = nil
        let command = FilterProductsByProductTypeListSelectorCommand(selected: productType) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: productType)

        XCTAssertEqual(cell.textLabel?.text, NSLocalizedString("Any", comment: "Title when there is no filter set."))
    }

    func testCellConfigurationForNonNilValue() {
        let productType = ProductType.grouped
        let command = FilterProductsByProductTypeListSelectorCommand(selected: productType) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: productType)

        XCTAssertEqual(cell.textLabel?.text, productType.description)
    }
}
