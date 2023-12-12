import Foundation
@testable import Networking

/// Mock for `WordPressThemeRemote`.
///
final class MockWordPressThemeRemote {
    private var stubbedSuggestedThemes: [WordPressTheme] = []
    private var stubbedSuggestedThemesError: Error?

    private var stubbedCurrentTheme: WordPressTheme?
    private var stubbedCurrentThemeError: Error?

    private var stubbedInstallTheme: WordPressTheme?
    private var stubbedInstallThemeError: Error?

    func whenLoadingSuggestedTheme(thenReturn result: Result<[Networking.WordPressTheme], Error>) {
        switch result {
        case .success(let themes):
            stubbedSuggestedThemes = themes
        case .failure(let error):
            stubbedSuggestedThemesError = error
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

    func whenInstallingTheme(thenReturn result: Result<Networking.WordPressTheme, Error>) {
        switch result {
        case .success(let theme):
            stubbedInstallTheme = theme
        case .failure(let error):
            stubbedInstallThemeError = error
        }
    }
}

extension MockWordPressThemeRemote: WordPressThemeRemoteProtocol {
    func loadSuggestedThemes() async throws -> [Networking.WordPressTheme] {
        if let stubbedSuggestedThemesError {
            throw stubbedSuggestedThemesError
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

    func installTheme(_ theme: Networking.WordPressTheme, siteID: Int64) async throws -> WordPressTheme {
        if let stubbedInstallThemeError {
            throw stubbedInstallThemeError
        }
        guard let stubbedInstallTheme else {
            throw NetworkError.notFound()
        }
        return stubbedInstallTheme
    }
}
