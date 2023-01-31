import Networking
import XCTest

/// Mock for `DomainRemote`.
///
final class MockDomainRemote {
    /// The results to return in `loadFreeDomainSuggestions`.
    private var loadDomainSuggestionsResult: Result<[FreeDomainSuggestion], Error>?

    /// The results to return in `loadPaidDomainSuggestions`.
    private var loadPaidDomainSuggestionsResult: Result<[PaidDomainSuggestion], Error>?

    /// The results to return in `loadDomainProducts`.
    private var loadDomainProductsResult: Result<[DomainProduct], Error>?

    /// The results to return in `loadDomains`.
    private var loadDomainsResult: Result<[SiteDomain], Error>?

    /// Returns the value when `loadDomainSuggestions` is called.
    func whenLoadingDomainSuggestions(thenReturn result: Result<[FreeDomainSuggestion], Error>) {
        loadDomainSuggestionsResult = result
    }

    /// Returns the value when `loadPaidDomainSuggestions` is called.
    func whenLoadingPaidDomainSuggestions(thenReturn result: Result<[PaidDomainSuggestion], Error>) {
        loadPaidDomainSuggestionsResult = result
    }

    /// Returns the value when `loadDomainProducts` is called.
    func whenLoadingDomainProducts(thenReturn result: Result<[DomainProduct], Error>) {
        loadDomainProductsResult = result
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
        guard let result = loadPaidDomainSuggestionsResult else {
            XCTFail("Could not find result for loading domain suggestions.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadDomainProducts() async throws -> [DomainProduct] {
        guard let result = loadDomainProductsResult else {
            XCTFail("Could not find result for loading domain products.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadDomains(siteID: Int64) async throws -> [SiteDomain] {
        guard let result = loadDomainsResult else {
            XCTFail("Could not find result for loading domains.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
