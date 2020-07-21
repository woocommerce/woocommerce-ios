import XCTest
@testable import Yosemite

/// LeaderboardProductParser unit tests
///
final class LeaderboardProductParserTests: XCTestCase {

    func testProductIDIsInferedFromAValidHTML() {
        // Given
        let html =
        """
        <a href='https://dulces.mystagingwebsite.com/wp-admin/admin.php?page=wc-admin&path=/analytics/products&filter=single_product&products=9'>Aljafor</a>
        """

        // When
        let productID = LeaderboardProductParser.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertEqual(productID, 9)
    }

    func testProductIDIsNotInferedFromAnArbitraryHTML() {
        // Given
        let html =
        """
        <a href='https://dulces.mystagingwebsite.com/wp-admin/admin.php?page=wc-admin&path=/analytics/products&filter=single_product'>Aljafor</a>
        """

        // When
        let productID = LeaderboardProductParser.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertNil(productID)
    }

    func testProductIDIsNotInferedFromAnInvalidHTML() {
        // Given
        let html = ""

        // When
        let productID = LeaderboardProductParser.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertNil(productID)
    }
}
