import XCTest

@testable import WooCommerce
import Yosemite

class Product_ProductFormTests: XCTestCase {

    private let sampleSiteID: Int64 = 109

    func testTrimmedFullDescriptionWithLeadingNewLinesAndHTMLTags() {
        let description = "\n\n\n  <p>This is the party room!</p>\n"
        let product = sampleProduct(description: description)
        let model = EditableProductModel(product: product)
        let expectedDescription = "This is the party room!"
        XCTAssertEqual(model.trimmedFullDescription, expectedDescription)
    }

    func testTrimmedShortDescriptionWithLeadingNewLinesAndHTMLTags() {
        let description = "\n\n\n  <p>This is the party room!</p>\n"
        let product = sampleProduct(shortDescription: description)
        let expectedDescription = "This is the party room!"
        XCTAssertEqual(product.trimmedShortDescription, expectedDescription)
    }

    func testNoCategoryDescriptionOutputsNilDescription() {
        let product = sampleProduct(categories: [])
        XCTAssertNil(product.categoriesDescription())
    }

    func testSingleCategoryDescriptionOutputsSingleCategory() {
        let category = sampleCategory(name: "Pants")
        let product = sampleProduct(categories: [category])
        let expectedDescription = "Pants"
        XCTAssertEqual(product.categoriesDescription(), expectedDescription)
    }

    func testMultipleCategoriesDescriptionOutputsFormattedList() {
        let categories = ["Pants", "Dress", "Shoes"].map { sampleCategory(name: $0) }
        let product = sampleProduct(categories: categories)
        let expectedDescription: String = {
            "Pants, Dress, and Shoes"
        }()
        let usLocale = Locale(identifier: "en_US")
        XCTAssertEqual(product.categoriesDescription(using: usLocale), expectedDescription)
    }

    // MARK: image related

    func testProductAllowsMultipleImages() {
        let product = Product().copy(images: [])
        let model = EditableProductModel(product: product)
        XCTAssertTrue(model.allowsMultipleImages())
    }

    func testProductImageDeletionIsEnabled() {
        let product = Product().copy(images: [])
        let model = EditableProductModel(product: product)
        XCTAssertTrue(model.isImageDeletionEnabled())
    }

    // MARK: `productTaxStatus`

    func testProductTaxStatusFromAnUnexpectedRawValueReturnsDefaultTaxable() {
        let product = Product().copy(taxStatusKey: "unknown tax status")
        XCTAssertEqual(product.productTaxStatus, .taxable)
    }

    func testProductTaxStatusFromAValidRawValueReturnsTheCorrespondingCase() {
        let product = Product().copy(taxStatusKey: ProductTaxStatus.shipping.rawValue)
        XCTAssertEqual(product.productTaxStatus, .shipping)
    }

    // MARK: `backordersSetting`

    func testBackordersSettingFromAnUnexpectedRawValueReturnsACustomCase() {
        let rawValue = "unknown setting"
        let product = Product().copy(backordersKey: rawValue)
        XCTAssertEqual(product.backordersSetting, .custom(rawValue))
    }

    func testBackordersSettingFromAValidRawValueReturnsTheCorrespondingCase() {
        let product = Product().copy(backordersKey: ProductBackordersSetting.notAllowed.rawValue)
        XCTAssertEqual(product.backordersSetting, .notAllowed)
    }
}

private extension Product_ProductFormTests {

    func sampleCategory(name: String = "") -> ProductCategory {
        return ProductCategory(categoryID: Int64.random(in: 0 ..< Int64.max),
                               siteID: sampleSiteID,
                               parentID: 0,
                               name: name,
                               slug: "")
    }

    func sampleProduct(description: String? = "", shortDescription: String? = "", categories: [ProductCategory] = []) -> Product {
        return Product(siteID: sampleSiteID,
                       productID: 177,
                       name: "Book the Green Room",
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       date: Date(),
                       dateCreated: Date(),
                       dateModified: Date(),
                       dateOnSaleStart: date(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: date(with: "2019-10-27T21:29:59"),
                       productTypeKey: "booking",
                       statusKey: "publish",
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: description,
                       shortDescription: shortDescription,
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
                       buttonText: "",
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "",
                       manageStock: false,
                       stockQuantity: nil,
                       stockStatusKey: "instock",
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       dimensions: ProductDimensions(length: "", width: "", height: ""),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: 0,
                       productShippingClass: nil,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: categories,
                       tags: [],
                       images: [],
                       attributes: [],
                       defaultAttributes: [],
                       variations: [192, 194, 193],
                       groupedProducts: [],
                       menuOrder: 0,
                       addOns: [])
    }

    private func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
