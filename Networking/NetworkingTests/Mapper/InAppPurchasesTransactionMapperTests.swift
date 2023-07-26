import XCTest
@testable import Networking

final class InAppPurchasesTransactionMapperTests: XCTestCase {
    func test_iap_handled_transaction_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-transaction-handled"))
        let expectedSiteID = Int64(1234)

        // When
        let decodedResponse = try InAppPurchasesTransactionMapper().map(response: jsonData)

        // Then
        assertEqual(expectedSiteID, decodedResponse.siteID)
    }

    func test_iap_unhandled_transaction_is_decoded_from_json_response() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("iap-transaction-not-handled"))
        let expectedErrorMessage = "Transaction not found."
        let expectedErrorCode = 404

        // When
        let decodedResponse = try InAppPurchasesTransactionMapper().map(response: jsonData)

        // Then
        assertEqual(expectedErrorMessage, decodedResponse.message)
        assertEqual(expectedErrorCode, decodedResponse.code)
    }
}
