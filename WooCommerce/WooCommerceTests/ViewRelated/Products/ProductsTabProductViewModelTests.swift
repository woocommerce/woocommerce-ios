import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductsTabProductViewModelTests: XCTestCase {

    // MARK: Stock status

    func testDetailsForProductInStockWithoutQuantity() {
        let product = productMock(name: "Yay", stockQuantity: nil, stockStatus: .inStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let expectedStockDetail = NSLocalizedString("In stock", comment: "Label about product's inventory stock status shown on Products tab")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductInStockWithQuantity() {
        let stockQuantity = 6
        let product = productMock(name: "Yay", stockQuantity: stockQuantity, stockStatus: .inStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let format = NSLocalizedString("%ld in stock", comment: "Label about product's inventory stock status shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(format, stockQuantity)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductOutOfStock() {
        let product = productMock(name: "Yay", stockQuantity: 1099, stockStatus: .outOfStock)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let expectedStockDetail = NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    // MARK: Variations

    func testDetailsForProductWithOneVariation() {
        let variations = [134]
        let product = productMock(name: "Yay", variations: variations)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let singularFormat = NSLocalizedString("%ld variant", comment: "Label about one product variation shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(singularFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

    func testDetailsForProductWithMultipleVariations() {
        let variations = [201, 134]
        let product = productMock(name: "Yay", variations: variations)
        let viewModel = ProductsTabProductViewModel(product: product)
        let detailsText = viewModel.detailsAttributedString.string
        let pluralFormat = NSLocalizedString("%ld variants", comment: "Label about number of variations shown on Products tab")
        let expectedStockDetail = String.localizedStringWithFormat(pluralFormat, variations.count)
        XCTAssertTrue(detailsText.contains(expectedStockDetail))
    }

}

extension ProductsTabProductViewModelTests {
    func productMock(
        name: String = "Hogsmeade",
        stockQuantity: Int? = nil,
        stockStatus: ProductStockStatus = .inStock,
        variations: [Int] = [],
        images: [ProductImage] = []
    ) -> Product {
        let testSiteID = 2019
        let testProductID = 2020
        return Product(
            siteID: testSiteID,
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
            briefDescription:
                """
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
            upsellIDs: [99, 1_234_566],
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
