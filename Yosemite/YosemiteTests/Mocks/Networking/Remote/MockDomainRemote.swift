import Networking
import XCTest

/// Mock for `DomainRemote`.
///
final class MockDomainRemote {
    /// The results to return in `loadDomainSuggestions`.
    private var loadDomainSuggestionsResult: Result<[FreeDomainSuggestion], Error>?

    /// The results to return in `loadDomains`.
    private var loadDomainsResult: Result<[SiteDomain], Error>?

    /// Returns the value when `loadDomainSuggestions` is called.
    func whenLoadingDomainSuggestions(thenReturn result: Result<[FreeDomainSuggestion], Error>) {
        loadDomainSuggestionsResult = result
    }

    /// Returns the value when `loadDomains` is called.
    func whenLoadingDomains(thenReturn result: Result<[SiteDomain], Error>) {
        loadDomainsResult = result
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

    func loadPaidDomainSuggestions(query: String) async throws -> [PaidDomainSuggestion] {
        // TODO: 8558 - Yosemite layer for paid domains
        throw NetworkError.notFound
    }

    func loadDomainProducts() async throws -> [DomainProduct] {
        // TODO: 8558 - Yosemite layer for paid domains
        throw NetworkError.notFound
    }

    func loadDomains(siteID: Int64) async throws -> [SiteDomain] {
        guard let result = loadDomainsResult else {
            XCTFail("Could not find result for loading domains.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
