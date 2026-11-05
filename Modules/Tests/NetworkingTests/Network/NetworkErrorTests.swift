import XCTest
@testable import Networking
@testable import NetworkingCore


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

    // MARK: `notFound`

    /// Verifies that provided response data is returned as a String when notFound
    ///
    func test_description_contains_response_data_as_a_string_when_notFound_error() throws {
        // Given
        let errorDict = ["error": "Failed to load"]
        let jsonData = try JSONSerialization.data(withJSONObject: errorDict)

        // When
        let network = try XCTUnwrap(NetworkError.notFound(response: jsonData))

        // Then
        XCTAssertTrue("\(network)".contains("{\"error\":\"Failed to load\"}"))
    }

    // MARK: `timeout`

    /// Verifies that provided response data is returned as a String when timeout
    ///
    func test_description_contains_response_data_as_a_string_when_timeout_error() throws {
        // Given
        let errorDict = ["error": "Failed to load"]
        let jsonData = try JSONSerialization.data(withJSONObject: errorDict)

        // When
        let network = try XCTUnwrap(NetworkError.timeout(response: jsonData))

        // Then
        XCTAssertTrue("\(network)".contains("{\"error\":\"Failed to load\"}"))
    }

    // MARK: `unacceptableStatusCode`

    /// Verifies that provided response data is stored when unacceptableStatusCode
    ///
    func test_response_data_is_stored_when_unacceptableStatusCode_error() throws {
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
        XCTAssertEqual(response, jsonData)
    }

    func test_errorMessage_when_response_has_message_then_returns_it_for_display_to_merchants() {
        // Given
        let response = Data(#"{"code":"product_invalid_sku","message":"Invalid or duplicated SKU."}"#.utf8)

        // When
        let error = NetworkError.unacceptableStatusCode(statusCode: 400, response: response)

        // Then
        XCTAssertEqual(error.errorMessage, "Invalid or duplicated SKU.")
    }

    func test_errorCode_when_message_is_not_a_string_then_code_is_still_available_for_error_mapping() {
        // Given
        let response = Data(#"{"code":"product_invalid_sku","message":{"nested":"value"}}"#.utf8)

        // When
        let error = NetworkError.unacceptableStatusCode(statusCode: 400, response: response)

        // Then
        XCTAssertEqual(error.errorCode, "product_invalid_sku")
        XCTAssertNil(error.errorMessage)
    }

    /// Verifies that provided response data is returned as a String when unacceptableStatusCode
    ///
    func test_description_contains_response_data_as_a_string_when_unacceptableStatusCode_error() throws {
        // Given
        let errorDict = ["error": "Failed to load"]
        let jsonData = try JSONSerialization.data(withJSONObject: errorDict)

        // When
        let network = try XCTUnwrap(NetworkError(responseData: jsonData, statusCode: 300))

        // Then
        XCTAssertTrue("\(network)".contains("{\"error\":\"Failed to load\"}"))
    }
}
