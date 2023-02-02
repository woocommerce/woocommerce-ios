import XCTest
@testable import WooCommerce

final class WooConstantsTests: XCTestCase {

    func testAllTrustedURLsAreValid() {
        // Given
        let allTrustedURLPaths = WooConstants.URLs.allCases

        // When
        let allTrustedURLs = allTrustedURLPaths.map { $0.asURL() }

        // Then
        zip(allTrustedURLPaths, allTrustedURLs).forEach { (path, url) in
            XCTAssertEqual(path.asURL().absoluteString, url.absoluteString)
        }
    }

    func test_URL_that_contains_special_characters_when_is_escaped_properly_then_does_not_return_nil() throws {
        // Given
        let urlStringWithSpecialCharacters = "https://test.com/test-–-survey"
        let escapedURLStringWithSpecialCharacter = "https://test.com/test-%E2%80%93-survey"

        // When
        let trustedURL = try urlStringWithSpecialCharacters.asURL()

        // Then
        XCTAssertNotNil(trustedURL)
        XCTAssertEqual(trustedURL.absoluteString, escapedURLStringWithSpecialCharacter)
    }
}
