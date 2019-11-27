import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStockStatusListSelectorDataSourceTests: XCTestCase {

    func testSelectedStatus() {
        let expectedStockStatus = ProductStockStatus.outOfStock
        let product = productMock(stockStatus: expectedStockStatus)
        var dataSource = ProductStockStatusListSelectorDataSource(product: product)
        XCTAssertEqual(dataSource.selected, expectedStockStatus)

        let newStockStatus = ProductStockStatus.inStock
        dataSource.handleSelectedChange(selected: newStockStatus)
        XCTAssertEqual(dataSource.selected, newStockStatus)
    }

    func testStockStatusListData() {
        let product = productMock()
        let dataSource = ProductStockStatusListSelectorDataSource(product: product)
        XCTAssertEqual(dataSource.data.count, 3)
    }

    func testCellConfiguration() {
        let product = productMock()
        let dataSource = ProductStockStatusListSelectorDataSource(product: product)
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

extension ProductStockStatusListSelectorDataSourceTests {
    func productMock(name: String = "Hogsmeade",
                     stockQuantity: Int? = nil,
                     stockStatus: ProductStockStatus = .inStock,
                     variations: [Int] = [],
                     images: [ProductImage] = []) -> Product {
        let testSiteID = 2019
        let testProductID = 2020
        return Product(siteID: testSiteID,
                       productID: testProductID,
                       name: name,
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: Date(),
                       dateModified: Date(),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                           [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                           We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                           know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                           for $100.</p>\n
                           """,
                       sku: "",
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: true,
                       downloadable: false,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: stockQuantity,
                       stockStatusKey: stockStatus.rawValue,
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: ProductDimensions(length: "0", width: "0", height: "0"),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: [],
                       tags: [],
                       images: images,
                       attributes: [],
                       defaultAttributes: [],
                       variations: variations,
                       groupedProducts: [],
                       menuOrder: 0)
    }
}
