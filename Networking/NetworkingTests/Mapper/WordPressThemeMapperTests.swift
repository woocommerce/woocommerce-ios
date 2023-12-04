import XCTest
@testable import Networking

final class WordPressThemeMapperTests: XCTestCase {

    /// Verifies that the object is parsed.
    ///
    func test_WordPressThemeMapper_parses_all_contents_in_response() throws {
        let theme = try XCTUnwrap(mapLoadWordPressThemeResponse())

        XCTAssertEqual(theme.id, "maywood")
        XCTAssertEqual(theme.name, "Maywood")
        XCTAssertEqual(theme.description, "Maywood is a refined theme designed for restaurants and food-related businesses seeking a modern look.")
        XCTAssertEqual(theme.demoURI, "")
    }

}

// MARK: - Test Helpers
//
private extension WordPressThemeMapperTests {

    /// Returns the WordPressThemeMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapWordPressTheme(from filename: String) throws -> WordPressTheme? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try WordPressThemeMapper().map(response: response)
    }

    /// Returns the WordPressThemeMapper output from `theme-mine-success.json`
    ///
    func mapLoadWordPressThemeResponse() throws -> WordPressTheme? {
        return try mapWordPressTheme(from: "theme-mine-success")
    }
}
