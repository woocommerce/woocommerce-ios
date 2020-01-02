import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductTaxClassListSelectorDataSourceTests: XCTestCase {
    private let sampleSiteID: Int64 = 521

    func testSelectedTaxClass() {
        let product = MockProduct().product(taxClass: "reduced-rate")
        let taxClass = TaxClass(siteID: sampleSiteID, name: "Reduced rate", slug: "reduced-rate")
        var dataSource = ProductTaxClassListSelectorDataSource(product: product, selected: taxClass)
        XCTAssertEqual(dataSource.selected, taxClass)

        let newTaxClass = TaxClass(siteID: sampleSiteID, name: "Zero rate", slug: "zero-rate")
        dataSource.handleSelectedChange(selected: newTaxClass)
        XCTAssertEqual(dataSource.selected, newTaxClass)

        // Select the same data twice should not clear the selected data.
        dataSource.handleSelectedChange(selected: newTaxClass)
        XCTAssertNotNil(dataSource.selected)
    }

    func testCellConfiguration() {
        let product = MockProduct().product(taxClass: "reduced-rate")
        let taxClass = TaxClass(siteID: sampleSiteID, name: "Reduced rate", slug: "reduced-rate")
        let dataSource = ProductTaxClassListSelectorDataSource(product: product, selected: taxClass)
        let nib = Bundle.main.loadNibNamed(WooBasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? WooBasicTableViewCell else {
            XCTFail()
            return
        }

        dataSource.configureCell(cell: cell, model: taxClass)

        XCTAssertEqual(cell.bodyLabel.text, taxClass.name)
    }

}
