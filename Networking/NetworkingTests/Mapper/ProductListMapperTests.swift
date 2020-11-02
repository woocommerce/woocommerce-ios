import XCTest
@testable import Networking


/// ProductListMapper Unit Tests
///
class ProductListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the Product Fields are parsed correctly.
    ///
    func test_Product_fields_are_properly_parsed() {
        let products = mapLoadAllProductsResponse()
        XCTAssertEqual(products.count, 10)

        let firstProduct = products[0]
        XCTAssertEqual(firstProduct.siteID, dummySiteID)
        XCTAssertEqual(firstProduct.productID, 282)
        XCTAssertEqual(firstProduct.name, "Book the Green Room")
        XCTAssertEqual(firstProduct.slug, "book-the-green-room")
        XCTAssertEqual(firstProduct.permalink, "https://example.com/product/book-the-green-room/")

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:33:31")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:48:01")
        XCTAssertEqual(firstProduct.dateCreated, dateCreated)
        XCTAssertEqual(firstProduct.dateModified, dateModified)

        XCTAssertEqual(firstProduct.productTypeKey, "booking")
        XCTAssertEqual(firstProduct.statusKey, "publish")
        XCTAssertFalse(firstProduct.featured)
        XCTAssertEqual(firstProduct.catalogVisibilityKey, "visible")

        XCTAssertEqual(firstProduct.fullDescription, "<p>This is the party room!</p>\n")
        XCTAssertEqual(firstProduct.shortDescription, """
            [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
            We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let \
            us know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests for $100.</p>\n
            """)
        XCTAssertEqual(firstProduct.sku, "")

        XCTAssertEqual(firstProduct.price, "0")
        XCTAssertEqual(firstProduct.regularPrice, "")
        XCTAssertEqual(firstProduct.salePrice, "")
        XCTAssertFalse(firstProduct.onSale)

        XCTAssertTrue(firstProduct.purchasable)
        XCTAssertEqual(firstProduct.totalSales, 0)
        XCTAssertTrue(firstProduct.virtual)

        XCTAssertFalse(firstProduct.downloadable)
        XCTAssertEqual(firstProduct.downloadLimit, -1)
        XCTAssertEqual(firstProduct.downloadExpiry, -1)

        XCTAssertEqual(firstProduct.externalURL, "http://somewhere.com")
        XCTAssertEqual(firstProduct.taxStatusKey, "taxable")
        XCTAssertEqual(firstProduct.taxClass, "")

        XCTAssertFalse(firstProduct.manageStock)
        XCTAssertNil(firstProduct.stockQuantity)
        XCTAssertEqual(firstProduct.stockStatusKey, "instock")

        XCTAssertEqual(firstProduct.backordersKey, "no")
        XCTAssertFalse(firstProduct.backordersAllowed)
        XCTAssertFalse(firstProduct.backordered)

        XCTAssertTrue(firstProduct.soldIndividually)
        XCTAssertEqual(firstProduct.weight, "213")

        XCTAssertFalse(firstProduct.shippingRequired)
        XCTAssertFalse(firstProduct.shippingTaxable)
        XCTAssertEqual(firstProduct.shippingClass, "")
        XCTAssertEqual(firstProduct.shippingClassID, 0)

        XCTAssertTrue(firstProduct.reviewsAllowed)
        XCTAssertEqual(firstProduct.averageRating, "4.30")
        XCTAssertEqual(firstProduct.ratingCount, 23)

        XCTAssertEqual(firstProduct.relatedIDs, [31, 22, 369, 414, 56])
        XCTAssertEqual(firstProduct.upsellIDs, [99, 1234566])
        XCTAssertEqual(firstProduct.crossSellIDs, [1234, 234234, 3])
        XCTAssertEqual(firstProduct.parentID, 0)

        XCTAssertEqual(firstProduct.purchaseNote, "Thank you!")
        XCTAssertEqual(firstProduct.variations, [192, 194, 193])
        XCTAssertEqual(firstProduct.groupedProducts, [])

        XCTAssertEqual(firstProduct.menuOrder, 0)
        XCTAssertEqual(firstProduct.productType, ProductType(rawValue: "booking"))
    }

    /// Test that ProductTypeKey converts to
    /// a ProductType enum properly.
    func test_that_productTypeKey_converts_to_enum_properly() {
        let products = mapLoadAllProductsResponse()

        let firstProduct = products[0]
        let customType = ProductType(rawValue: "booking")
        XCTAssertEqual(firstProduct.productTypeKey, "booking")
        XCTAssertEqual(firstProduct.productType, customType)

        let secondProduct = products[1]
        let simpleType = ProductType.simple
        XCTAssertEqual(secondProduct.productTypeKey, "simple")
        XCTAssertEqual(secondProduct.productType, simpleType)

        let thirdProduct = products[2]
        let groupedType = ProductType.grouped
        XCTAssertEqual(thirdProduct.productTypeKey, "grouped")
        XCTAssertEqual(thirdProduct.productType, groupedType)

        let fourthProduct = products[3]
        let affiliateType = ProductType.affiliate
        XCTAssertEqual(fourthProduct.productTypeKey, "external")
        XCTAssertEqual(fourthProduct.productType, affiliateType)

        let fifthProduct = products[4]
        let variableType = ProductType.variable
        XCTAssertEqual(fifthProduct.productTypeKey, "variable")
        XCTAssertEqual(fifthProduct.productType, variableType)
    }

    /// Test that categories are properly mapped.
    ///
    func test_that_product_categories_are_properly_mapped() {
        let products = mapLoadAllProductsResponse()
        let firstProduct = products[0]
        let categories = firstProduct.categories
        XCTAssertEqual(categories.count, 1)

        let category = firstProduct.categories[0]
        XCTAssertEqual(category.categoryID, 36)
        XCTAssertEqual(category.name, "Events")
        XCTAssertEqual(category.slug, "events")
        XCTAssertTrue(category.categoryID == 36)
    }

    /// Test that tags are properly mapped.
    ///
    func test_that_product_tags_are_properly_mapped() {
        let products = mapLoadAllProductsResponse()
        let firstProduct = products[0]
        let tags = firstProduct.tags
        XCTAssert(tags.count == 9)

        let tag = tags[2]
        XCTAssertEqual(tag.tagID, 39)
        XCTAssertEqual(tag.name, "30")
        XCTAssertEqual(tag.slug, "30")
    }

    /// Test that product images are properly mapped.
    ///
    func test_that_product_images_are_properly_mapped() {
        let products = mapLoadAllProductsResponse()
        let product = products[1]
        let images = product.images
        XCTAssertEqual(images.count, 1)

        let productImage = images[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-05-07T21:02:45")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-05-07T21:03:04")
        XCTAssertEqual(productImage.imageID, 209)
        XCTAssertEqual(productImage.dateCreated, dateCreated)
        XCTAssertEqual(productImage.dateModified, dateModified)
        XCTAssertEqual(productImage.src,
                       "https://i0.wp.com/thuy-nonjtpk.mystagingwebsite.com/wp-content/uploads/2018/05/71PEq6VvFjL._SL1500_.jpg?fit=1500%2C1500&ssl=1")
        XCTAssertEqual(productImage.name, "Dymo LabelWriter 4XL")
        XCTAssert(productImage.alt?.isEmpty == true)
    }

    /// Test that product attributes are properly mapped
    ///
    func test_that_product_attributes_are_properly_mapped() {
        let products = mapLoadAllProductsResponse()
        let product = products[4]
        let attributes = product.attributes
        XCTAssertEqual(attributes.count, 2)

        let attribute = attributes[0]
        XCTAssertEqual(attribute.attributeID, 0)
        XCTAssertEqual(attribute.name, "Size")
        XCTAssertEqual(attribute.position, 0)
        XCTAssertTrue(attribute.visible)
        XCTAssertTrue(attribute.variation)

        let option1 = attribute.options[0]
        let option2 = attribute.options[1]
        let option3 = attribute.options[2]
        XCTAssertEqual(option1, "Small")
        XCTAssertEqual(option2, "Medium")
        XCTAssertEqual(option3, "Large")
    }

    /// Test that the default product attributes map properly
    ///
    func test_that_default_product_attributes_map_properly() {
        let products = mapLoadAllProductsResponse()
        let product = products[4]
        let defaultAttributes = product.defaultAttributes
        XCTAssertEqual(defaultAttributes.count, 2)

        let attribute1 = defaultAttributes[0]
        XCTAssertEqual(attribute1.attributeID, 0)
        XCTAssertEqual(attribute1.name, "Size")
        XCTAssertEqual(attribute1.option, "Medium")

        let attribute2 = defaultAttributes[1]
        XCTAssert(attribute2.attributeID == 0)
        XCTAssertEqual(attribute2.name, "Color")
        XCTAssertEqual(attribute2.option, "Purple")
    }
}


/// Private Methods.
///
private extension ProductListMapperTests {

    /// Returns the ProductListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProducts(from filename: String) -> [Product] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductListMapper output upon receiving `products-load-all`
    ///
    func mapLoadAllProductsResponse() -> [Product] {
        return mapProducts(from: "products-load-all")
    }
}
