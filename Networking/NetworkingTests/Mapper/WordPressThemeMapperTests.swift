import XCTest
@testable import Networking

final class WordPressThemeMapperTests: XCTestCase {

    /// Verifies that the object is parsed.
    ///
    func test_WordPressThemeMapper_parses_all_contents_in_response() async throws {
        let theme = try await mapLoadWordPressThemeResponse()

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
    func mapWordPressTheme(from filename: String) async throws -> WordPressTheme {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await WordPressThemeMapper().map(response: response)
    }

    /// Returns the WordPressThemeMapper output from `theme-mine-success.json`
    ///
    func mapLoadWordPressThemeResponse() async throws -> WordPressTheme {
        try await mapWordPressTheme(from: "theme-mine-success")
    }

    struct FileNotFoundError: Error {}
}
