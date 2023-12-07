import XCTest
@testable import Networking


/// ProductSkuMapper Unit Tests
///
final class ProductSkuMapperTests: XCTestCase {

    /// Verifies that SKU are parsed correctly.
    ///
    func test_sku_is_properly_parsed() async throws {
        let skus = [try await mapLoadSkuResponse(), try await mapLoadSkuResponseWithoutData()]

        for sku in skus {
            XCTAssertEqual(sku, "T-SHIRT-HAPPY-NINJA")
        }
    }
}


/// Private Methods.
///
private extension ProductSkuMapperTests {

    /// Returns the ProductSkuMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSku(from filename: String) async throws -> String {
        guard let response = Loader.contentsOf(filename) else {
            return ""
        }

        return try await ProductSkuMapper().map(response: response)
    }

    /// Returns the ProductSkuMapper output upon receiving `product-search-sku`
    ///
    func mapLoadSkuResponse() async throws -> String {
        try await mapSku(from: "product-search-sku")
    }

    /// Returns the ProductSkuMapper output upon receiving `product-search-sku-without-data`
    ///
    func mapLoadSkuResponseWithoutData() async throws -> String {
        try await mapSku(from: "product-search-sku-without-data")
    }
}
