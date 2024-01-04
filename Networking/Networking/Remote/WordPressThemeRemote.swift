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

    /// Installs the theme with the given ID for the site with the specified ID.
    ///
    func installTheme(themeID: String,
                      siteID: Int64) async throws -> WordPressTheme

    /// Activates the theme with the given ID for the site with the specified ID.
    ///
    func activateTheme(themeID: String,
                       siteID: Int64) async throws -> WordPressTheme
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
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        return try await enqueue(request, mapper: WordPressThemeMapper())
    }

    public func installTheme(themeID: String,
                             siteID: Int64) async throws -> WordPressTheme {
        let path = Paths.install(themeID: themeID, for: siteID)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path)
        do {
            return try await enqueue(request, mapper: WordPressThemeMapper())
        } catch {
            throw InstallThemeError(error) ?? error
        }
    }

    public func activateTheme(themeID: String,
                              siteID: Int64) async throws -> WordPressTheme {
        let path = Paths.currentThemePath(for: siteID)
        let parameters = [
            ParameterKey.theme: themeID,
        ]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: parameters)
        return try await enqueue(request, mapper: WordPressThemeMapper())
    }
}

/// Possible theme installation errors in the Networking layer.
///
public enum InstallThemeError: Error {
    case themeAlreadyInstalled

    init?(_ error: Error) {
        guard let dotcomError = error as? DotcomError,
              case let .unknown(code, _) = dotcomError else {
            return nil
        }

        switch code {
        case Constants.themeAlreadyInstalled:
            self = .themeAlreadyInstalled
        default:
            return nil
        }
    }

    private enum Constants {
        static let themeAlreadyInstalled = "theme_already_installed"
    }
}

private extension WordPressThemeRemote {
    enum Paths {
        static let suggestedThemes = "themes?filter=subject:store&number=100"
        static func currentThemePath(for siteID: Int64) -> String {
            "sites/\(siteID)/themes/mine"
        }

        static func install(themeID: String,
                            for siteID: Int64) -> String {
            "sites/\(siteID)/themes/\(themeID)/install/"
        }
    }

    enum ParameterKey {
        static let theme = "theme"
    }

    enum Values {
        static let filteredThemeIDs = ["tsubaki", "tazza", "amulet", "zaino", "thriving-artist"]
    }
}
