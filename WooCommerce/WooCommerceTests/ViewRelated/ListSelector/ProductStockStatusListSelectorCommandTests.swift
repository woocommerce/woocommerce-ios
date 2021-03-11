import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStockStatusListSelectorCommandTests: XCTestCase {

    func test_selected_status() {
        let expectedStockStatus = ProductStockStatus.outOfStock
        let product = Product.fake().copy(stockStatusKey: expectedStockStatus.rawValue)
        let command = ProductStockStatusListSelectorCommand(selected: product.productStockStatus)
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, expectedStockStatus)

        let newStockStatus = ProductStockStatus.inStock
        command.handleSelectedChange(selected: newStockStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newStockStatus)
    }

    func test_stock_status_list_data() {
        let product = Product.fake()
        let command = ProductStockStatusListSelectorCommand(selected: product.productStockStatus)
        XCTAssertEqual(command.data.count, 3)
    }

    func test_cell_configuration() {
        let product = Product.fake()
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
