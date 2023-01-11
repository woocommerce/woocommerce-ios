import XCTest
import TestKit
@testable import Networking

final class DomainRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - `loadFreeDomainSuggestions`

    func test_loadFreeDomainSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains/suggestions", filename: "domain-suggestions")

        // When
        let suggestions = try await remote.loadFreeDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(suggestions, [
            .init(name: "domaintestingtips.wordpress.com", isFree: true),
            .init(name: "domaintestingtoday.wordpress.com", isFree: true),
        ])
    }

    func test_loadFreeDomainSuggestions_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadFreeDomainSuggestions(query: "domain")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadDomains`

    func test_loadDomains_returns_domains_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains", filename: "site-domains")

        // When
        let domains = try await remote.loadDomains(siteID: 23)

        // Then
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let renewalDate = try XCTUnwrap(dateFormatter.date(from: "December 10, 2023"))
        XCTAssertEqual(domains, [
            .init(name: "crabparty.wpcomstaging.com", isPrimary: true),
            .init(name: "crabparty.com", isPrimary: false, renewalDate: renewalDate),
            .init(name: "crabparty.wordpress.com", isPrimary: false)
        ])
    }

    func test_loadDomains_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadDomains(siteID: 23)}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }
}
