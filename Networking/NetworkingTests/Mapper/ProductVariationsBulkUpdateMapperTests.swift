import XCTest
@testable import Networking

/// Unit Tests for `ProductVariationsBulkUpdateMapper`
///
final class ProductVariationsBulkUpdateMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 295

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed() throws {
        let productVariations = try XCTUnwrap(mapLoadProductVariationBulkUpdateResponse())
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let productVariations = try XCTUnwrap(mapLoadProductVariationBulkUpdateResponseWithoutDataEnvelope())
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }
}

/// Private Helpers
///
private extension ProductVariationsBulkUpdateMapperTests {

    /// Returns the ProductVariationsBulkUpdateMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariations(from filename: String) -> [ProductVariation]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductVariationsBulkUpdateMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationsBulkUpdateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkUpdateResponse() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-bulk-update")
    }

    /// Returns the ProductVariationsBulkUpdateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkUpdateResponseWithoutDataEnvelope() -> [ProductVariation]? {
        return mapProductVariations(from: "product-variations-bulk-update-without-data")
    }
}
