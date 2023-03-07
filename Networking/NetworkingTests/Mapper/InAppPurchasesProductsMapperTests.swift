import XCTest
@testable import Networking

final class InAppPurchasesProductsMapperTests: XCTestCase {
    func test_iap_products_list_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-products"))
        let expectedProductIdentifiers = [
            "debug.woocommerce.ecommerce.monthly"
        ]

        // When
        let products = try InAppPurchasesProductMapper().map(response: jsonData)

        // Then
        assertEqual(expectedProductIdentifiers, products)
    }
}
