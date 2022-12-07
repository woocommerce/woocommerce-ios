import XCTest
@testable import Networking

final class WordPressOrgRequestTests: XCTestCase {

    private let baseURL = "https://test.com"
    private let path = "/test/request"

    func test_request_url_is_correct() throws {
        // Given
        let request = WordPressOrgRequest(baseURL: baseURL, method: .get, path: path)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        let expectedURL = "https://test.com/wp-json/test/request"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_request_method_is_correct() throws {
        // Given
        let request = WordPressOrgRequest(baseURL: baseURL, method: .get, path: path)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        assertEqual(urlRequest.httpMethod, "GET")
    }
}
