import XCTest
@testable import Networking


/// ProductVariationListMapper Unit Tests
///
class ProductVariationListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID = 282


    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func testProductVariationFieldsAreProperlyParsed() {
        let productVariations = mapLoadAllProductVariationsResponse().sorted()
        XCTAssertEqual(productVariations.count, 4)

        let secondProductVariation = productVariations[1]
        XCTAssertEqual(secondProductVariation.siteID, dummySiteID)
        XCTAssertEqual(secondProductVariation.productID, dummyProductID)
        XCTAssertEqual(secondProductVariation.variationID, 215)
        XCTAssertEqual(secondProductVariation.permalink, "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Short")
        XCTAssertEqual(secondProductVariation.dateCreated, date(with: "2019-02-21T16:56:17"))
        XCTAssertEqual(secondProductVariation.dateModified, date(with: "2019-04-04T22:08:33"))
        XCTAssertEqual(secondProductVariation.dateOnSaleFrom, date(with: "2019-04-01T08:08:44"))
        XCTAssertEqual(secondProductVariation.dateOnSaleTo, date(with: "2019-04-29T01:08:21"))
        XCTAssertEqual(secondProductVariation.statusKey, "publish")
        XCTAssertEqual(secondProductVariation.fullDescription, "Hi there!")
        XCTAssertEqual(secondProductVariation.sku, "345345")
        XCTAssertEqual(secondProductVariation.price, "14.33")
        XCTAssertEqual(secondProductVariation.regularPrice, "12.77")
        XCTAssertEqual(secondProductVariation.salePrice, "14.33")
        XCTAssertTrue(secondProductVariation.onSale)
        XCTAssertTrue(secondProductVariation.purchasable)
        XCTAssertFalse(secondProductVariation.virtual)
        XCTAssertFalse(secondProductVariation.downloadable)
        XCTAssertEqual(secondProductVariation.downloadLimit, -1)
        XCTAssertEqual(secondProductVariation.downloadExpiry, -1)
        XCTAssertEqual(secondProductVariation.taxStatusKey, "taxable")
        XCTAssertEqual(secondProductVariation.taxClass, "a_lot")
        XCTAssertFalse(secondProductVariation.manageStock)
        XCTAssertNil(secondProductVariation.stockQuantity)
        XCTAssertEqual(secondProductVariation.stockStatusKey, "instock")
        XCTAssertEqual(secondProductVariation.backordersKey, "no")
        XCTAssertTrue(secondProductVariation.backordersAllowed)
        XCTAssertFalse(secondProductVariation.backordered)
        XCTAssertEqual(secondProductVariation.weight, "99")
        XCTAssertEqual(secondProductVariation.shippingClass, "Woo!")
        XCTAssertEqual(secondProductVariation.shippingClassID, 99)
        XCTAssertEqual(secondProductVariation.image, sampleImage())
        XCTAssertEqual(secondProductVariation.dimensions, sampleDimensions())
        XCTAssertEqual(secondProductVariation.attributes.count, 2)
        XCTAssertEqual(secondProductVariation.attributes, sampleAttributes())
        XCTAssertEqual(secondProductVariation.menuOrder, 4)

        let fourthProductVariation = productVariations[3]
        XCTAssertEqual(fourthProductVariation.siteID, dummySiteID)
        XCTAssertEqual(fourthProductVariation.productID, dummyProductID)
        XCTAssertEqual(fourthProductVariation.variationID, 295)
        XCTAssertEqual(fourthProductVariation.permalink, "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Long")
        XCTAssertEqual(fourthProductVariation.dateCreated, date(with: "2019-04-04T22:06:45"))
        XCTAssertEqual(fourthProductVariation.dateModified, date(with: "2019-04-04T22:08:33"))
        XCTAssertNil(fourthProductVariation.dateOnSaleFrom)
        XCTAssertNil(fourthProductVariation.dateOnSaleTo)
        XCTAssertEqual(fourthProductVariation.statusKey, "publish")
        XCTAssertEqual(fourthProductVariation.fullDescription, "")
        XCTAssertEqual(fourthProductVariation.sku, "345345")
        XCTAssertEqual(fourthProductVariation.price, "")
        XCTAssertEqual(fourthProductVariation.regularPrice, "")
        XCTAssertEqual(fourthProductVariation.salePrice, "")
        XCTAssertFalse(fourthProductVariation.onSale)
        XCTAssertFalse(fourthProductVariation.purchasable)
        XCTAssertFalse(fourthProductVariation.virtual)
        XCTAssertTrue(fourthProductVariation.downloadable)
        XCTAssertEqual(fourthProductVariation.downloadLimit, 500)
        XCTAssertEqual(fourthProductVariation.downloadExpiry, 100000239847897)
        XCTAssertEqual(fourthProductVariation.taxStatusKey, "taxable")
        XCTAssertEqual(fourthProductVariation.taxClass, "")
        XCTAssertFalse(fourthProductVariation.manageStock)
        XCTAssertNil(fourthProductVariation.stockQuantity)
        XCTAssertEqual(fourthProductVariation.stockStatusKey, "instock")
        XCTAssertEqual(fourthProductVariation.backordersKey, "no")
        XCTAssertFalse(fourthProductVariation.backordersAllowed)
        XCTAssertFalse(fourthProductVariation.backordered)
        XCTAssertEqual(fourthProductVariation.weight, "")
        XCTAssertEqual(fourthProductVariation.shippingClass, "")
        XCTAssertEqual(fourthProductVariation.shippingClassID, 0)
        XCTAssertEqual(fourthProductVariation.image, sampleImage2())
        XCTAssertEqual(fourthProductVariation.dimensions, sampleDimensions2())
        XCTAssertEqual(fourthProductVariation.attributes.count, 2)
        XCTAssertEqual(fourthProductVariation.attributes, sampleAttributes2())
        XCTAssertEqual(fourthProductVariation.menuOrder, 2)
    }
}


/// Private Methods.
///
private extension ProductVariationListMapperTests {

    /// Returns the ProductVariationListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariations(from filename: String) -> [ProductVariation] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductVariationListMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationListMapper output upon receiving `product-variations-load-all`
    ///
    func mapLoadAllProductVariationsResponse() -> [ProductVariation] {
        return mapProductVariations(from: "product-variations-load-all")
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

    func sampleDimensions() -> ProductDimensions {
        return ProductDimensions(length: "11", width: "22", height: "33")
    }

    func sampleImage() -> ProductImage {
        return ProductImage(imageID: 206,
                            dateCreated: date(with: "2019-01-31T20:38:17"),
                            dateModified: date(with: "2019-02-28T01:38:17"),
                            src: "https://i1.wp.com/paperairplane.store/wp-content/uploads/2019/01/FFXUJ9RIAY1N6DC.LARGE_.jpg?fit=1024%2C853&ssl=1",
                            name: "FFXUJ9RIAY1N6DC.LARGE",
                            alt: "It's a picture! Yaaay!")
    }

    func sampleAttributes() -> [ProductVariationAttribute] {
        let attribute1 = ProductVariationAttribute(attributeID: 0, name: "Color", option: "Black")
        let attribute2 = ProductVariationAttribute(attributeID: 0, name: "Length", option: "Short")

        return [attribute1, attribute2]
    }

    func sampleDimensions2() -> ProductDimensions {
        return ProductDimensions(length: "", width: "", height: "")
    }

    func sampleImage2() -> ProductImage {
        return ProductImage(imageID: 123123,
                            dateCreated: date(with: "2016-11-13T20:38:17"),
                            dateModified: nil,
                            src: "https://i1.wp.com/paperairplane.store/wp-content/uploads/2019/01/FFXUJ9RIAY1N6DC.LARGE_.jpg?fit=1024%2C853&ssl=1",
                            name: "this_is_a_picture",
                            alt: "")
    }

    func sampleAttributes2() -> [ProductVariationAttribute] {
        let attribute1 = ProductVariationAttribute(attributeID: 0, name: "Color", option: "White")
        let attribute2 = ProductVariationAttribute(attributeID: 0, name: "Length", option: "Long")

        return [attribute1, attribute2]
    }
}
