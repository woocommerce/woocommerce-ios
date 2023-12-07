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
    func test_ProductVariation_fields_are_properly_parsed() async throws {
        let productVariations = try await mapLoadProductVariationBulkUpdateResponse()
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let productVariations = try await mapLoadProductVariationBulkUpdateResponseWithoutDataEnvelope()
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
    func mapProductVariations(from filename: String) async throws -> [ProductVariation] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await ProductVariationsBulkUpdateMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationsBulkUpdateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkUpdateResponse() async throws -> [ProductVariation] {
        try await mapProductVariations(from: "product-variations-bulk-update")
    }

    /// Returns the ProductVariationsBulkUpdateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkUpdateResponseWithoutDataEnvelope() async throws -> [ProductVariation] {
        try await mapProductVariations(from: "product-variations-bulk-update-without-data")
    }

    struct FileNotFoundError: Error {}
}
