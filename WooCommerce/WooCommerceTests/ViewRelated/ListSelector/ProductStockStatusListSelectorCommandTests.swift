import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStockStatusListSelectorCommandTests: XCTestCase {

    func testSelectedStatus() {
        let expectedStockStatus = ProductStockStatus.outOfStock
        let product = MockProduct().product(stockStatus: expectedStockStatus)
        let command = ProductStockStatusListSelectorCommand(selected: product.productStockStatus)
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, expectedStockStatus)

        let newStockStatus = ProductStockStatus.inStock
        command.handleSelectedChange(selected: newStockStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newStockStatus)
    }

    func testStockStatusListData() {
        let product = MockProduct().product()
        let command = ProductStockStatusListSelectorCommand(selected: product.productStockStatus)
        XCTAssertEqual(command.data.count, 3)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let command = ProductStockStatusListSelectorCommand(selected: product.productStockStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        let status = ProductStockStatus.onBackOrder
        command.configureCell(cell: cell, model: status)

        XCTAssertEqual(cell.textLabel?.text, status.description)
    }
}
