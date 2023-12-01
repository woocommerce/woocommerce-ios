import Foundation
@testable import Networking

/// Mock for `WordPressThemeRemote`.
///
final class MockWordPressThemeRemote {
    private var stubbedThemes: [WordPressTheme] = []
    private var stubbedError: Error?

    func whenLoadingSuggestedTheme(thenReturn result: Result<[Networking.WordPressTheme], Error>) {
        switch result {
        case .success(let themes):
            stubbedThemes = themes
        case .failure(let error):
            stubbedError = error
        }
    }
}

extension MockWordPressThemeRemote: WordPressThemeRemoteProtocol {
    func loadSuggestedThemes() async throws -> [Networking.WordPressTheme] {
        if let stubbedError {
            throw stubbedError
        }
        return stubbedThemes
    }
}
