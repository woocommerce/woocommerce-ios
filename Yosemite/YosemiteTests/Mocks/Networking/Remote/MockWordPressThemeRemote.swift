import Foundation
@testable import Networking

/// Mock for `WordPressThemeRemote`.
///
final class MockWordPressThemeRemote {
    private var stubbedSuggestedThemes: [WordPressTheme] = []
    private var stubbedSuggestedThemeError: Error?

    private var stubbedCurrentTheme: WordPressTheme?
    private var stubbedCurrentThemeError: Error?

    func whenLoadingSuggestedTheme(thenReturn result: Result<[Networking.WordPressTheme], Error>) {
        switch result {
        case .success(let themes):
            stubbedSuggestedThemes = themes
        case .failure(let error):
            stubbedSuggestedThemeError = error
        }
    }

    func whenLoadingCurrentTheme(thenReturn result: Result<Networking.WordPressTheme, Error>) {
        switch result {
        case .success(let theme):
            stubbedCurrentTheme = theme
        case .failure(let error):
            stubbedCurrentThemeError = error
        }
    }
}

extension MockWordPressThemeRemote: WordPressThemeRemoteProtocol {
    func loadSuggestedThemes() async throws -> [Networking.WordPressTheme] {
        if let stubbedSuggestedThemeError {
            throw stubbedSuggestedThemeError
        }
        return stubbedSuggestedThemes
    }

    func loadCurrentTheme(siteID: Int64) async throws -> WordPressTheme {
        if let stubbedCurrentThemeError {
            throw stubbedCurrentThemeError
        }
        guard let stubbedCurrentTheme else {
            throw NetworkError.notFound()
        }
        return stubbedCurrentTheme
    }
}
