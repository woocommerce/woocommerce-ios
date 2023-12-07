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
    func test_ProductVariation_fields_are_properly_parsed() async throws {
        let productVariations = try await mapLoadProductVariationBulkCreateResponse()
        XCTAssertTrue(productVariations.count == 1)

        let variation = try XCTUnwrap(productVariations.first)
        XCTAssertEqual(2783, variation.productVariationID)
    }

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func test_ProductVariation_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let productVariations = try await mapLoadProductVariationBulkCreateResponseWithoutDataEnvelope()
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
    func mapProductVariations(from filename: String) async throws -> [ProductVariation] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await ProductVariationsBulkCreateMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationsBulkCreateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkCreateResponse() async throws -> [ProductVariation] {
        try await mapProductVariations(from: "product-variations-bulk-create")
    }

    /// Returns the ProductVariationsBulkCreateMapper output upon receiving `product`
    ///
    func mapLoadProductVariationBulkCreateResponseWithoutDataEnvelope() async throws -> [ProductVariation] {
        try await mapProductVariations(from: "product-variations-bulk-create-without-data")
    }

    struct FileNotFoundError: Error {}
}
