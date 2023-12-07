import XCTest
@testable import Networking

final class InAppPurchasesOrderResultMapperTests: XCTestCase {
    func test_iap_order_creation_is_decoded_from_json_response() async throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-order-create"))
        let expectedOrderId = 12345

        // When
        let orderId = try await InAppPurchaseOrderResultMapper().map(response: jsonData)

        // Then
        assertEqual(expectedOrderId, orderId)
    }
}
