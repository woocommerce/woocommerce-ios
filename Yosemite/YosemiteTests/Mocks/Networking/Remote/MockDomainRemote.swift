import Networking
import XCTest

/// Mock for `DomainRemote`.
///
final class MockDomainRemote {
    /// The results to return in `loadDomainSuggestions`.
    private var loadDomainSuggestionsResult: Result<[FreeDomainSuggestion], Error>?

    /// Returns the value when `loadDomainSuggestions` is called.
    func whenLoadingDomainSuggestions(thenReturn result: Result<[FreeDomainSuggestion], Error>) {
        loadDomainSuggestionsResult = result
    }
}

extension MockDomainRemote: DomainRemoteProtocol {
    func loadFreeDomainSuggestions(query: String) async throws -> [FreeDomainSuggestion] {
        guard let result = loadDomainSuggestionsResult else {
            XCTFail("Could not find result for loading domain suggestions.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadDomains(siteID: Int64) async throws -> [SiteDomain] {
        // TODO: 8558 - Yosemite layer
        throw NetworkError.notFound
    }
}
