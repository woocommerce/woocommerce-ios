import XCTest

@testable import WooCommerce
@testable import Yosemite

final class PaginatedProductShippingClassListSelectorDataSourceTests: XCTestCase {
    private let sampleSiteID: Int64 = 521

    func test_selected_shippingClass() {
        let shippingClassID = Int64(134)
        let shippingClass = sampleProductShippingClass(remoteID: shippingClassID)
        let product = Product.fake().copy(productShippingClass: shippingClass)
        let model = EditableProductModel(product: product)
        var dataSource = PaginatedProductShippingClassListSelectorDataSource(product: model, selected: product.productShippingClass)
        XCTAssertEqual(dataSource.selected, shippingClass)

        let newShippingClass = sampleProductShippingClass(remoteID: 2019)
        dataSource.handleSelectedChange(selected: newShippingClass)
        XCTAssertEqual(dataSource.selected, newShippingClass)

        // Select the same data twice should clear the selected data.
        dataSource.handleSelectedChange(selected: newShippingClass)
        XCTAssertNil(dataSource.selected)
    }

    func test_cell_configuration() {
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let dataSource = PaginatedProductShippingClassListSelectorDataSource(product: model, selected: product.productShippingClass)
        let nib = Bundle.main.loadNibNamed(WooBasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? WooBasicTableViewCell else {
            XCTFail()
            return
        }

        let shippingClass = sampleProductShippingClass(remoteID: 134)
        dataSource.configureCell(cell: cell, model: shippingClass)

        XCTAssertEqual(cell.bodyLabel.text, shippingClass.name)
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
