import XCTest
/// UIURL+Woo: Unit Tests
///
import XCTest

@testable import WooCommerce

final class StringWooTests: XCTestCase {
    func testURLsWithSchemeRemainUnchanged() {
        let url = "https://automattic.com"
        let sanitizedURL = url.addHTTPSSchemeIfNecessary()

        XCTAssertEqual(url, sanitizedURL)
    }

    func testSchemeIsAddedToURLsWithoutScheme() {
        let expectedResult = "https://automattic.com"
        let url = "automattic.com"
        let sanitizedURL = url.addHTTPSSchemeIfNecessary()

        XCTAssertEqual(sanitizedURL, expectedResult)
    }
}
