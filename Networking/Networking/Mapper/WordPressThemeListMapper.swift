import Foundation

/// Mapper: `WordPressTheme` List
///
struct WordPressThemeListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[WordPressTheme]`.
    ///
    func map(response: Data) throws -> [WordPressTheme] {
        let decoder = JSONDecoder()
        return try decoder.decode(WordPressThemeListEnvelope.self, from: response).themes
    }
}


/// WordPressThemeEnvelope Disposable Entity.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct WordPressThemeListEnvelope: Decodable {
    let themes: [WordPressTheme]
}
