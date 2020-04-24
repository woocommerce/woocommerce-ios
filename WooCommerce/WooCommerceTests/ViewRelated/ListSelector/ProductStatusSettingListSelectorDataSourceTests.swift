import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStatusSettingListSelectorDataSourceTests: XCTestCase {

    func testSelectedSetting() {
        let expectedSetting = ProductStatus.publish
        let product = MockProduct().product(status: expectedSetting)
        var dataSource = ProductStatusSettingListSelectorDataSource(selected: product.productStatus)
        XCTAssertEqual(dataSource.selected, expectedSetting)

        let newSetting = ProductStatus.pending
        dataSource.handleSelectedChange(selected: newSetting)
        XCTAssertEqual(dataSource.selected, newSetting)
    }

    func testSettingListData() {
        let dataSource = ProductStatusSettingListSelectorDataSource(selected: nil)
        XCTAssertEqual(dataSource.data.count, 4)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let dataSource = ProductStatusSettingListSelectorDataSource(selected: product.productStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        dataSource.configureCell(cell: cell, model: product.productStatus)

        XCTAssertEqual(cell.textLabel?.text, product.productStatus.description)
    }

}
