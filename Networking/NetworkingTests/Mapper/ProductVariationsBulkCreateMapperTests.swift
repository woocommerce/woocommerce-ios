import XCTest
@testable import Networking

/// Unit Tests for `ProductVariationsBulkCreateMapper`
///
final class ProductVariationsBulkCreateMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 295

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed() throws {
        let productVariations = try XCTUnwrap(mapLoadProductVariationBulkCreateResponse())
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let productVariations = try XCTUnwrap(mapLoadProductVariationBulkCreateResponseWithoutDataEnvelope())
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }
}

/// Private Helpers
///
private extension ProductVariationsBulkCreateMapperTests {

    /// Returns the ProductVariationsBulkCreateMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariations(from filename: String) -> [ProductVariation]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductVariationsBulkCreateMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationsBulkCreateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkCreateResponse() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-bulk-create")
    }

    /// Returns the ProductVariationsBulkCreateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkCreateResponseWithoutDataEnvelope() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-bulk-create-without-data")
    }
}
