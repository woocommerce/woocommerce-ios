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
        let parameters: [String: Any] = [
            Keys.filter: Values.suggestedThemeFilter,
            Keys.number: Values.maximumThemeCount
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_2, method: .get, path: path, parameters: parameters)
        let mapper = WordPressThemeListMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

private extension WordPressThemeRemote {
    enum Paths {
        // https://public-api.wordpress.com/rest/v1.2/themes?filter=subject:store&number=100
        static let suggestedThemes = "themes"
    }

    enum Keys {
        static let filter = "filter"
        static let number =  "number"
    }

    enum Values {
        static let suggestedThemeFilter = "subject:store"
        static let maximumThemeCount = 100
    }
}
