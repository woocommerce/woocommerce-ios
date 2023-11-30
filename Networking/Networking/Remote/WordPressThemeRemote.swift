import Foundation

/// Protocol for `WordPressThemeRemote` mainly used for mocking.
///
public protocol WordPressThemeRemoteProtocol {
    /// Loads suggested themes.
    ///
    func loadSuggestedThemes() async throws -> [WordPressTheme]

    /// Loads the current theme for the site with the specified ID.
    ///
    func loadCurrentTheme(siteID: Int64) async throws -> WordPressTheme
}

/// WordPressThemes: Remote Endpoints
///
public final class WordPressThemeRemote: Remote, WordPressThemeRemoteProtocol {

    public func loadSuggestedThemes() async throws -> [WordPressTheme] {
        let path = Paths.suggestedThemes
        let request = DotcomRequest(wordpressApiVersion: .mark1_2, method: .get, path: path)
        let mapper = WordPressThemeListMapper()
        return try await enqueue(request, mapper: mapper)
            .filter { theme in
                Values.filteredThemeIDs.contains(theme.id)
            }
    }

    public func loadCurrentTheme(siteID: Int64) async throws -> WordPressTheme {
        let path = Paths.currentThemePath(for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .mark1_2, method: .get, path: path)
        return try await enqueue(request, mapper: WordPressThemeMapper())
    }
}

private extension WordPressThemeRemote {
    enum Paths {
        static let suggestedThemes = "themes?filter=subject:store&number=100"
        static func currentThemePath(for siteID: Int64) -> String {
            "sites/\(siteID)/themes/mine"
        }
    }

    enum Values {
        static let filteredThemeIDs = ["tsubaki", "tazza", "amulet", "zaino", "thriving-artist", "attar"]
    }
}
