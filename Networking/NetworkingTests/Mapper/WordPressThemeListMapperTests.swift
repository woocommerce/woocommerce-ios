import XCTest
@testable import Networking

final class WordPressThemeListMapperTests: XCTestCase {

    /// Verifies that the whole list is parsed.
    ///
    func test_WordPressThemeListMapper_parses_all_contents_in_response() throws {
        let themes = try mapLoadWordPressThemeListResponse()
        XCTAssertEqual(themes.count, 2)

        let item = try XCTUnwrap(themes.first)
        XCTAssertEqual(item.id, "organic-stax")
        XCTAssertEqual(item.name, "STAX")
        // swiftlint:disable:next line_length
        XCTAssertEqual(item.description, "STAX is a premium block theme for the WordPress full-site editor. The design is clean, versatile, and totally customizable. Additionally, the setup wizard provides a super simple installation process — so your site will appear exactly as the demo within moments of activation. ")
        XCTAssertEqual(item.demoURI, "https://stax.organicthemes.com/")
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
