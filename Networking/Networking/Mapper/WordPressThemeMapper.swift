import Foundation

/// Mapper: `WordPressTheme`
///
struct WordPressThemeMapper: Mapper {

    /// (Attempts) to convert a dictionary into `WordPressTheme`.
    ///
    func map(response: Data) throws -> WordPressTheme {
        let decoder = JSONDecoder()
        return try decoder.decode(WordPressTheme.self, from: response)
    }
}
