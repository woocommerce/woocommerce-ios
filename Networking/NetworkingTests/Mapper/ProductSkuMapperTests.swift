import XCTest
@testable import Networking


/// ProductSkuMapper Unit Tests
///
final class ProductSkuMapperTests: XCTestCase {

    /// Verifies that SKU are parsed correctly.
    ///
    func test_sku_is_properly_parsed() {
        let skus = [mapLoadSkuResponse(), mapLoadSkuResponseWithoutData()]

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
    func mapSku(from filename: String) -> String {
        guard let response = Loader.contentsOf(filename) else {
            return ""
        }

        return try! ProductSkuMapper().map(response: response)
    }

    /// Returns the ProductSkuMapper output upon receiving `product-search-sku`
    ///
    func mapLoadSkuResponse() -> String {
        return mapSku(from: "product-search-sku")
    }

    /// Returns the ProductSkuMapper output upon receiving `product-search-sku-without-data`
    ///
    func mapLoadSkuResponseWithoutData() -> String {
        return mapSku(from: "product-search-sku-without-data")
    }
}
