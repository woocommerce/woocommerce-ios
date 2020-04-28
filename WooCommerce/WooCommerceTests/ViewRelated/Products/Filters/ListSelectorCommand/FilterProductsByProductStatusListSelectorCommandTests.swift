import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductsByProductStatusListSelectorCommandTests: XCTestCase {
    func testSelectedIsSetCorrectlyAfterSelections() {
        let productStatus = ProductStatus.privateStatus
        var selectedProductStatus: ProductStatus? = productStatus
        let command = FilterProductsByProductStatusListSelectorCommand(selected: productStatus) { selected in
            selectedProductStatus = selected
        }
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, productStatus)

        let newProductStatus: ProductStatus? = nil
        command.handleSelectedChange(selected: newProductStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newProductStatus)
        XCTAssertEqual(selectedProductStatus, newProductStatus)

        // Selecting the same data twice should not affect the selected data.
        command.handleSelectedChange(selected: newProductStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newProductStatus)
        XCTAssertEqual(selectedProductStatus, newProductStatus)
    }

    // MARK: Cell Configuration

    func testCellConfigurationForNilValue() {
        let productStatus: ProductStatus? = nil
        let command = FilterProductsByProductStatusListSelectorCommand(selected: productStatus) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: productStatus)

        XCTAssertEqual(cell.textLabel?.text, NSLocalizedString("Any", comment: "Title when there is no filter set."))
    }

    func testCellConfigurationForNonNilValue() {
        let productStatus = ProductStatus.pending
        let command = FilterProductsByProductStatusListSelectorCommand(selected: productStatus) { _ in }
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: productStatus)

        XCTAssertEqual(cell.textLabel?.text, productStatus.description)
    }
}
