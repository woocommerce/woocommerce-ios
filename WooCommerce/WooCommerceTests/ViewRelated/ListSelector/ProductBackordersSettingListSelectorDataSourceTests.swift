import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductBackordersSettingListSelectorDataSourceTests: XCTestCase {

    func testSelectedSetting() {
        let expectedSetting = ProductBackordersSetting.notAllowed
        let product = MockProduct().product(backordersSetting: expectedSetting)
        var dataSource = ProductBackordersSettingListSelectorDataSource(selected: product.backordersSetting)
        XCTAssertEqual(dataSource.selected, expectedSetting)

        let newSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        dataSource.handleSelectedChange(selected: newSetting)
        XCTAssertEqual(dataSource.selected, newSetting)
    }

    func testSettingListData() {
        let dataSource = ProductBackordersSettingListSelectorDataSource(selected: nil)
        XCTAssertEqual(dataSource.data.count, 3)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let dataSource = ProductBackordersSettingListSelectorDataSource(selected: product.backordersSetting)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        dataSource.configureCell(cell: cell, model: product.backordersSetting)

        XCTAssertEqual(cell.textLabel?.text, product.backordersSetting.description)
    }

}
