import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStockStatusListSelectorDataSourceTests: XCTestCase {

    func testSelectedStatus() {
        let expectedStockStatus = ProductStockStatus.outOfStock
        let product = MockProduct().product(stockStatus: expectedStockStatus)
        var dataSource = ProductStockStatusListSelectorDataSource(selected: product.productStockStatus)
        XCTAssertEqual(dataSource.selected, expectedStockStatus)

        let newStockStatus = ProductStockStatus.inStock
        dataSource.handleSelectedChange(selected: newStockStatus)
        XCTAssertEqual(dataSource.selected, newStockStatus)
    }

    func testStockStatusListData() {
        let product = MockProduct().product()
        let dataSource = ProductStockStatusListSelectorDataSource(selected: product.productStockStatus)
        XCTAssertEqual(dataSource.data.count, 3)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let dataSource = ProductStockStatusListSelectorDataSource(selected: product.productStockStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        let status = ProductStockStatus.onBackOrder
        dataSource.configureCell(cell: cell, model: status)

        XCTAssertEqual(cell.textLabel?.text, status.description)
    }
}
