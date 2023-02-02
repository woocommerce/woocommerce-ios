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

    func test_URLs_that_contains_special_characters_when_are_escaped_properly_then_do_not_return_nil() throws {
        // Given
        let urlsWithSpecialCharacters = [
            WooConstants.URLs.inPersonPaymentsCashOnDeliveryFeedback,
            WooConstants.URLs.inPersonPaymentsFirstTransactionFeedback,
            WooConstants.URLs.inPersonPaymentsPowerUsersFeedback
        ]

        let escapedURLsWithSpecialCharacters = [
            "https://automattic.survey.fm/woo-app-%E2%80%93-cod-survey",
            "https://automattic.survey.fm/woo-app-%E2%80%93-ipp-first-transaction-survey",
            "https://automattic.survey.fm/woo-app-%E2%80%93-ipp-survey-for-power-users"
        ]

        // When
        let _ = urlsWithSpecialCharacters.map { trustedURL in
            XCTAssertNotNil(trustedURL)
        }

        // Then
        XCTAssertEqual(urlsWithSpecialCharacters[0].asURL().absoluteString, escapedURLsWithSpecialCharacters[0])
        XCTAssertEqual(urlsWithSpecialCharacters[1].asURL().absoluteString, escapedURLsWithSpecialCharacters[1])
        XCTAssertEqual(urlsWithSpecialCharacters[2].asURL().absoluteString, escapedURLsWithSpecialCharacters[2])
    }
}
