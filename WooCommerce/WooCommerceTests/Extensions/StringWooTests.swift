import XCTest
@testable import WooCommerce


/// UIURL+Woo: Unit Tests
///
import XCTest

final class StringWooTests: XCTestCase {
    func test_URLs_with_scheme_remain_unchanged() {
        let url = "https://automattic.com"
        let sanitizedURL = url.addHTTPSSchemeIfNecessary()

        XCTAssertEqual(url, sanitizedURL)
    }

    func test_scheme_is_added_to_URLs_without_scheme() {
        let expectedResult = "https://automattic.com"
        let url = "automattic.com"
        let sanitizedURL = url.addHTTPSSchemeIfNecessary()

        XCTAssertEqual(sanitizedURL, expectedResult)
    }

    func test_scheme_is_trimmed_for_URL_without_path() {
        let expectedResult = "automattic.com"
        let url = "https://automattic.com"

        XCTAssertEqual(url.trimHTTPScheme(), expectedResult)
    }

    func test_scheme_is_trimmed_for_URL_with_path() {
        let expectedResult = "automattic.com/work-with-us"
        let url = "https://automattic.com/work-with-us"

        XCTAssertEqual(url.trimHTTPScheme(), expectedResult)
    }

    func test_string_is_not_trimmed_if_it_is_not_a_URL() {
        let expectedResult = "regular string"
        let notAURL = expectedResult

        XCTAssertEqual(notAURL.trimHTTPScheme(), expectedResult)
    }
}
