import XCTest

@testable import WooCommerce
@testable import Yosemite

final class PaginatedProductShippingClassListSelectorDataSourceTests: XCTestCase {
    private let sampleSiteID: Int64 = 521

    func testSelectedShippingClass() {
        let shippingClassID = Int64(134)
        let shippingClass = sampleProductShippingClass(remoteID: shippingClassID)
        let product = MockProduct().product(productShippingClass: shippingClass)
        var dataSource = PaginatedProductShippingClassListSelectorDataSource(product: product)
        XCTAssertEqual(dataSource.selected, shippingClass)

        let newShippingClass = sampleProductShippingClass(remoteID: 2019)
        dataSource.handleSelectedChange(selected: newShippingClass)
        XCTAssertEqual(dataSource.selected, newShippingClass)

        // Select the same data twice should clear the selected data.
        dataSource.handleSelectedChange(selected: newShippingClass)
        XCTAssertNil(dataSource.selected)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let dataSource = PaginatedProductShippingClassListSelectorDataSource(product: product)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        let shippingClass = sampleProductShippingClass(remoteID: 134)
        dataSource.configureCell(cell: cell, model: shippingClass)

        XCTAssertEqual(cell.textLabel?.text, shippingClass.name)
    }

}

private extension PaginatedProductShippingClassListSelectorDataSourceTests {
    func sampleProductShippingClass(remoteID: Int64) -> ProductShippingClass {
        return ProductShippingClass(count: 3,
                                    descriptionHTML: "Limited offer!",
                                    name: "Free Shipping",
                                    shippingClassID: remoteID,
                                    siteID: sampleSiteID,
                                    slug: "free-shipping")
    }
}
