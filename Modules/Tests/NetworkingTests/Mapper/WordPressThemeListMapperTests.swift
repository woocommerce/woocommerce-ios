import XCTest
@testable import Networking

final class WordPressThemeListMapperTests: XCTestCase {

    /// Verifies that the whole list is parsed.
    ///
    func test_WordPressThemeListMapper_parses_all_contents_in_response() throws {
        let themes = try mapLoadWordPressThemeListResponse()
        XCTAssertEqual(themes.count, 2)

        let item = try XCTUnwrap(themes.first)
        XCTAssertEqual(item.id, "tsubaki")
        XCTAssertEqual(item.name, "Tsubaki")
        // swiftlint:disable:next line_length
        XCTAssertEqual(item.description, "Tsubaki puts the spotlight on your products and your customers.  This theme leverages WooCommerce to provide you with intuitive product navigation and the patterns you need to master digital merchandising.")
        XCTAssertEqual(item.demoURI, "https://tsubakidemo.wpcomstaging.com/")
    }
}

// MARK: - Test Helpers
///
private extension WordPressThemeListMapperTests {

    /// Returns the WordPressThemeListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapWordPressThemeList(from filename: String) throws -> [WordPressTheme] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try WordPressThemeListMapper().map(response: response)
    }

    /// Returns the WordPressThemeListMapper output from `theme-list-success.json`
    ///
    func mapLoadWordPressThemeListResponse() throws -> [WordPressTheme] {
        return try mapWordPressThemeList(from: "theme-list-success")
    }
}
