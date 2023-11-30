import Foundation

/// Protocol for `WordPressThemeRemote` mainly used for mocking.
///
public protocol WordPressThemeRemoteProtocol {
    /// Loads suggested themes.
    ///
    func loadSuggestedThemes() async throws -> [WordPressTheme]
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
}

private extension WordPressThemeRemote {
    enum Paths {
        static let suggestedThemes = "themes?filter=subject:store&number=100"
    }

    enum Values {
        static let filteredThemeIDs = ["tsubaki", "tazza", "amulet", "zaino", "thriving-artist", "attar"]
    }
}
