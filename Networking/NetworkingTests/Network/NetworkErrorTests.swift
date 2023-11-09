import XCTest
@testable import Networking


/// NetworkError Tests
///
final class NetworkErrorTests: XCTestCase {

    /// Verifies that statusCode(s) within the "Successful Range" [200, 299) yield nil errors.
    ///
    func testSuccessStatusCodesYieldNilNetworkErrors() {
        XCTAssertNil(NetworkError(responseData: nil,
                                  statusCode: 200))
        XCTAssertNil(NetworkError(responseData: nil,
                                  statusCode: 299))
    }

    /// Verifies that (not defined) Network Errors are wrapped within a `.unacceptableStatusCode` case
    ///
    func testUnknownErrorsAreCaughtByUnacceptableEnumCase() {
        guard case let .unacceptableStatusCode(statusCode, _)? = NetworkError(responseData: nil,
                                                                           statusCode: 300) else {
            XCTFail()
            return
        }

        XCTAssertEqual(statusCode, 300)
    }

    /// Verifies that NotFound is properly parsed.
    ///
    func testNotFoundErrorIsProperlyParsed() {
        guard case .notFound? = NetworkError(responseData: nil,
                                             statusCode: 404) else {
            XCTFail()
            return
        }
    }

    /// Verifies that provided response data if stored as string
    ///
    func test_response_data_is_stored_as_string() throws {
        // Given
        let error = ["error": "Failed to load"]
        let jsonData = try JSONSerialization.data(withJSONObject: error)

        // When
        guard case let .unacceptableStatusCode(statusCode, response)? = NetworkError(responseData: jsonData,
                                                                                     statusCode: 300) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(statusCode, 300)
        XCTAssertEqual(response, "{\"error\":\"Failed to load\"}")
    }
}
