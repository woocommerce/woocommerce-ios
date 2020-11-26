import XCTest
@testable import WooCommerce


/// UIURL+Woo: Unit Tests
///
import XCTest

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

    func testSchemeIsTrimmedForURLWithoutPath() {
        let expectedResult = "automattic.com"
        let url = "https://automattic.com"

        XCTAssertEqual(url.trimHTTPScheme(), expectedResult)
    }

    func testSchemeIsTrimmedForURLWithPath() {
        let expectedResult = "automattic.com/work-with-us"
        let url = "https://automattic.com/work-with-us"

        XCTAssertEqual(url.trimHTTPScheme(), expectedResult)
    }

    func testStringIsNotTrimmerIfItIsNotAURL() {
        let expectedResult = "regular string"
        let notAURL = expectedResult

        XCTAssertEqual(notAURL.trimHTTPScheme(), expectedResult)
    }
}
