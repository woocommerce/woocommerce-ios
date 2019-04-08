import XCTest
@testable import Networking


/// ProductVariationMapper Unit Tests
///
class ProductVariationMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID = 282


    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func testProductVariationFieldsAreProperlyParsed() {
        guard let productVariation = mapLoadProductVariationResponse() else {
            XCTFail("Failed to parse product variation")
            return
        }

        XCTAssertEqual(productVariation.siteID, dummySiteID)
        XCTAssertEqual(productVariation.productID, dummyProductID)
        XCTAssertEqual(productVariation.variationID, 215)
        XCTAssertEqual(productVariation.permalink, "https://paperairplane.store/product/paper-airplane/?attribute_color=Black&attribute_length=Short")

        XCTAssertEqual(productVariation.dateCreated, date(with: "2019-02-21T16:56:17"))
        XCTAssertEqual(productVariation.dateModified, date(with: "2019-04-04T22:08:33"))
        XCTAssertEqual(productVariation.dateOnSaleFrom, date(with: "2019-04-01T08:08:44"))
        XCTAssertEqual(productVariation.dateOnSaleTo, date(with: "2019-04-29T01:08:21"))

        XCTAssertEqual(productVariation.statusKey, "publish")
        XCTAssertEqual(productVariation.fullDescription, "Hi there!")
        XCTAssertEqual(productVariation.sku, "345345")

        XCTAssertEqual(productVariation.price, "14.33")
        XCTAssertEqual(productVariation.regularPrice, "12.77")
        XCTAssertEqual(productVariation.salePrice, "14.33")
        XCTAssertTrue(productVariation.onSale)

        XCTAssertTrue(productVariation.purchasable)
        XCTAssertFalse(productVariation.virtual)

        XCTAssertFalse(productVariation.downloadable)
        XCTAssertEqual(productVariation.downloadLimit, -1)
        XCTAssertEqual(productVariation.downloadExpiry, -1)

        XCTAssertEqual(productVariation.taxStatusKey, "taxable")
        XCTAssertEqual(productVariation.taxClass, "a_lot")

        XCTAssertFalse(productVariation.manageStock)
        XCTAssertNil(productVariation.stockQuantity)
        XCTAssertEqual(productVariation.stockStatusKey, "instock")

        XCTAssertEqual(productVariation.backordersKey, "no")
        XCTAssertTrue(productVariation.backordersAllowed)
        XCTAssertFalse(productVariation.backordered)

        XCTAssertEqual(productVariation.weight, "99")
        XCTAssertEqual(productVariation.shippingClass, "Woo!")
        XCTAssertEqual(productVariation.shippingClassID, 99)

        XCTAssertEqual(productVariation.image, sampleImage())
        XCTAssertEqual(productVariation.dimensions, sampleDimensions())
        XCTAssertEqual(productVariation.attributes.count, 2)
        XCTAssertEqual(productVariation.attributes, sampleAttributes())

        XCTAssertEqual(productVariation.menuOrder, 4)
    }
}


/// Private Methods.
///
private extension ProductVariationMapperTests {

    /// Returns the ProductVariationMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariation(from filename: String) -> ProductVariation? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ProductVariationMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationMapper output upon receiving `ProductVariation`
    ///
    func mapLoadProductVariationResponse() -> ProductVariation? {
        return mapProductVariation(from: "product-variation")
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

}
