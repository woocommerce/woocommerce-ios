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
}
