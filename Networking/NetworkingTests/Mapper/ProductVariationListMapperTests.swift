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
        let productVariation = try XCTUnwrap(mapLoadProductVariationListResponse()?.first)

        XCTAssertEqual(productVariation.siteID, dummySiteID)
        XCTAssertEqual(productVariation.productID, dummyProductID)
        XCTAssertEqual(productVariation.productVariationID, 1275)
        XCTAssertEqual(productVariation.permalink, "https://chocolate.com/marble")

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-11-14T12:40:55")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-11-14T13:06:42")
        XCTAssertEqual(productVariation.dateCreated, dateCreated)
        XCTAssertEqual(productVariation.dateModified, dateModified)

        XCTAssertEqual(productVariation.description, "<p>Nutty chocolate marble, 99% and organic.</p>\n")
        XCTAssertEqual(productVariation.sku, "99%-nuts-marble")

        XCTAssertEqual(productVariation.price, "12")
        XCTAssertEqual(productVariation.regularPrice, "12")
        XCTAssertEqual(productVariation.salePrice, "8")
        XCTAssertFalse(productVariation.onSale)

        XCTAssertTrue(productVariation.purchasable)
        XCTAssertFalse(productVariation.virtual)

        XCTAssertTrue(productVariation.downloadable)
        XCTAssertEqual(productVariation.downloadLimit, -1)
        XCTAssertEqual(productVariation.downloadExpiry, 0)

        XCTAssertEqual(productVariation.taxStatusKey, "taxable")
        XCTAssertEqual(productVariation.taxClass, "")

        XCTAssertTrue(productVariation.manageStock)
        XCTAssertEqual(productVariation.stockQuantity, 16)

        XCTAssertEqual(productVariation.backordersKey, "notify")
        XCTAssertTrue(productVariation.backordersAllowed)
        XCTAssertFalse(productVariation.backordered)

        XCTAssertEqual(productVariation.weight, "2.5")
        XCTAssertEqual(productVariation.dimensions, ProductDimensions(length: "10", width: "2.5", height: ""))

        XCTAssertEqual(productVariation.shippingClass, "")
        XCTAssertEqual(productVariation.shippingClassID, 0)

        XCTAssertNotNil(productVariation.image)

        XCTAssertEqual(productVariation.attributes.count, 3)

        XCTAssertEqual(productVariation.menuOrder, 8)
    }

    /// Verifies that the fields of the ProductVariation with alternative types are parsed correctly when they have different types than in the struct.
    /// Currently, `price`, `salePrice` and `manageStock` allow alternative types.
    ///
    func testThatProductVariationAlternativeTypesAreProperlyParsed() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationListResponseWithAlternativeTypes()?.first)

        XCTAssertEqual(productVariation.price, "16")
        XCTAssertEqual(productVariation.salePrice, "12.5")
        XCTAssertTrue(productVariation.manageStock)
    }

    /// Verifies that the `salePrice` field of the ProductVariation is parsed to "0" when the product variation is on sale and the sale price is an empty string
    ///
    func testThatProductVariationSalePriceIsProperlyParsedWhenOnSale() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationOnSaleWithEmptySalePriceResponse()?.first)

        XCTAssertEqual(productVariation.salePrice, "0")
        XCTAssertTrue(productVariation.onSale)
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

    /// Returns the ProductVariationListMapper output upon receiving a product variation on sale, with empty sale price
    ///
    func mapLoadProductVariationOnSaleWithEmptySalePriceResponse() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-load-all-first-on-sale-empty-sale-price")
    }
}
