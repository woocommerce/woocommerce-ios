import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductTaxStatusListSelectorDataSourceTests: XCTestCase {

    func testSelectedTaxStatus() {

        let taxStatus = ProductTaxStatus.taxable
        var dataSource = ProductTaxStatusListSelectorDataSource(selected: taxStatus)
        XCTAssertEqual(dataSource.selected, taxStatus)

        let newTaxStatus = ProductTaxStatus.shipping
        dataSource.handleSelectedChange(selected: newTaxStatus)
        XCTAssertEqual(dataSource.selected, newTaxStatus)

        // Select the same data twice should not clear the selected data.
        dataSource.handleSelectedChange(selected: newTaxStatus)
        XCTAssertNotNil(dataSource.selected)
    }

    func testCellConfiguration() {
        let taxStatus = ProductTaxStatus.taxable
        let dataSource = ProductTaxStatusListSelectorDataSource(selected: taxStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        dataSource.configureCell(cell: cell, model: taxStatus)

        XCTAssertEqual(cell.textLabel?.text, taxStatus.description)
    }

}
