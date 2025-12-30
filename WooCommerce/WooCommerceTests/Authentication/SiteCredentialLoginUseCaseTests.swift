import XCTest
@testable import WooCommerce

final class SiteCredentialLoginUseCaseTests: XCTestCase {

    func test_cookieJar_is_cleared_upon_login() throws {
        // Given
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: "lalala")
        let useCase = SiteCredentialLoginUseCase(siteURL: "https://test.com", cookieJar: cookieJar)
        // confidence check
        let cookies = try XCTUnwrap(cookieJar.cookies)
        XCTAssertTrue(cookies.isNotEmpty)

        // When
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertEqual(cookieJar.cookies?.isEmpty, true)
    }

    func test_basicAuthenticationChallenge_is_detected_from_response_headers() throws {
        // Given
        let response = try XCTUnwrap(makeHTTPURLResponse(
            statusCode: 401,
            headers: ["WWW-Authenticate": "Basic realm=\"Restricted Area\""]
        ))

        // Then
        XCTAssertTrue(response.containsHTTPBasicAuthenticationChallenge)
    }

    func test_basicAuthenticationChallenge_returns_false_when_header_is_missing() throws {
        // Given
        let response = try XCTUnwrap(makeHTTPURLResponse(
            statusCode: 401,
            headers: ["Content-Type": "text/html"]
        ))

        // Then
        XCTAssertFalse(response.containsHTTPBasicAuthenticationChallenge)
    }
}

// MARK: - Helpers
private extension SiteCredentialLoginUseCaseTests {
    func makeHTTPURLResponse(statusCode: Int, headers: [String: String]) -> HTTPURLResponse? {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )
    }
}
