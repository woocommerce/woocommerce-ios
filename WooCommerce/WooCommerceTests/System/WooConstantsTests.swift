import XCTest
@testable import WooCommerce

final class WooConstantsTests: XCTestCase {

    func testAllThrustedURLsAreValid() {
        // Given
        let allTrustedURLPaths = WooConstants.URLs.allCases

        // When
        let allTrustedURLs = allTrustedURLPaths.map { $0.asURL() }

        // Then
        zip(allTrustedURLPaths, allTrustedURLs).forEach { (path, url) in
            XCTAssertEqual(path.rawValue, url.absoluteString)
        }
    }
}
