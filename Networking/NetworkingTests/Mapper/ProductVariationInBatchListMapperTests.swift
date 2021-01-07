import XCTest
@testable import Networking

/// Unit Tests for `ProductVariationInBatchListMapper`
///
final class ProductVariationInBatchListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 295

    /// Verifies that all of the ProductVariationInBatch Fields are parsed correctly.
    ///
    func test_create_update_delete_fields_are_properly_parsed() throws {
        let productVariationInBatch = try XCTUnwrap(mapLoadProductVariationInBatchListResponse())

        XCTAssertEqual(productVariationInBatch.create.count, 2)
        XCTAssertEqual(productVariationInBatch.update.count, 1)
        XCTAssertEqual(productVariationInBatch.delete.count, 1)
    }
}

/// Private Helpers
///
private extension ProductVariationInBatchListMapperTests {

    /// Returns the ProductVariationInBatchListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariationsInBatch(from filename: String) -> ProductVariationInBatch? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductVariationInBatchListMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationListMapper output upon receiving `product`
    ///
    func mapLoadProductVariationInBatchListResponse() -> ProductVariationInBatch? {
        return mapProductVariationsInBatch(from: "product-variations-create-update-delete-in-batch")
    }

}
