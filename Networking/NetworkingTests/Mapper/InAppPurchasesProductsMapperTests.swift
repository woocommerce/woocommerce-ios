import XCTest
@testable import Networking

final class InAppPurchasesProductsMapperTests: XCTestCase {
    func test_iap_products_list_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-products"))
        let expectedProductIdentifiers = [
            "woocommerce_entry_monthly",
            "woocommerce_entry_yearly"]

        // When
        let products = try InAppPurchasesProductMapper().map(response: jsonData)

        // Then
        assertEqual(expectedProductIdentifiers, products)
    }

    func test_iap_order_creation_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-order-create"))
        let expectedOrderId = 1234

        // When
        let orderId = try InAppPurchaseOrderResultMapper().map(response: jsonData)

        // Then
        assertEqual(expectedOrderId, orderId)
    }
}
