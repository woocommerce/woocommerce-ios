import XCTest
@testable import Networking

/// Unit Tests for `ProductVariationListMapper`
///
final class ProductVariationListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 295

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func testProductVariationFieldsAreProperlyParsed() throws {
        let product = try XCTUnwrap(mapLoadProductVariationListResponse()?.first)

        XCTAssertEqual(product.siteID, dummySiteID)
        XCTAssertEqual(product.productID, dummyProductID)
        XCTAssertEqual(product.permalink, "https://chocolate.com/marble")

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-11-14T12:40:55")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-11-14T13:06:42")
        XCTAssertEqual(product.dateCreated, dateCreated)
        XCTAssertEqual(product.dateModified, dateModified)

        XCTAssertEqual(product.description, "<p>Nutty chocolate marble, 99% and organic.</p>\n")
        XCTAssertEqual(product.sku, "99%-nuts-marble")

        XCTAssertEqual(product.price, "12")
        XCTAssertEqual(product.regularPrice, "12")
        XCTAssertEqual(product.salePrice, "8")
        XCTAssertFalse(product.onSale)

        XCTAssertTrue(product.purchasable)
        XCTAssertFalse(product.virtual)

        XCTAssertTrue(product.downloadable)
        XCTAssertEqual(product.downloadLimit, -1)
        XCTAssertEqual(product.downloadExpiry, 0)

        XCTAssertEqual(product.taxStatusKey, "taxable")
        XCTAssertEqual(product.taxClass, "")

        XCTAssertTrue(product.manageStock)
        XCTAssertEqual(product.stockQuantity, 16)

        XCTAssertEqual(product.backordersKey, "notify")
        XCTAssertTrue(product.backordersAllowed)
        XCTAssertFalse(product.backordered)

        XCTAssertEqual(product.weight, "2.5")
        XCTAssertEqual(product.dimensions, ProductDimensions(length: "10", width: "2.5", height: ""))

        XCTAssertEqual(product.shippingClass, "")
        XCTAssertEqual(product.shippingClassID, 0)

        XCTAssertNotNil(product.image)

        XCTAssertEqual(product.attributes.count, 3)

        XCTAssertEqual(product.menuOrder, 8)
    }

    /// Verifies that the fields of the ProductVariation with alternative types are parsed correctly when they have different types than in the struct.
    /// Currently, `price`, `salePrice` and `manageStock` allow alternative types.
    ///
    func testThatProductAlternativeTypesAreProperlyParsed() throws {
        let product = try XCTUnwrap(mapLoadProductVariationListResponseWithAlternativeTypes()?.first)

        XCTAssertEqual(product.price, "16")
        XCTAssertEqual(product.salePrice, "12.5")
        XCTAssertTrue(product.manageStock)
    }
}

/// Private Helpers
///
private extension ProductVariationListMapperTests {

    /// Returns the ProductVariationListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariations(from filename: String) -> [ProductVariation]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductVariationListMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationListMapper output upon receiving `product`
    ///
    func mapLoadProductVariationListResponse() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-load-all")
    }

    /// Returns the ProductVariationListMapper output upon receiving `product-alternative-types`
    ///
    func mapLoadProductVariationListResponseWithAlternativeTypes() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-load-all-alternative-types")
    }
}
