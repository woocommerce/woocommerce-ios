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

    // MARK: - `loadPaidDomainSuggestions`

    func test_loadPaidDomainSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains/suggestions", filename: "domain-suggestions-paid")

        // When
        let suggestions = try await remote.loadPaidDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(suggestions, [
            .init(name: "color.bar", productID: 356, supportsPrivacy: true),
            .init(name: "color.ink", productID: 359, supportsPrivacy: true)
        ])
    }

    func test_loadPaidDomainSuggestions_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadPaidDomainSuggestions(query: "domain")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadDomainProducts`

    func test_loadDomainProducts_returns_products_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "domain-products")

        // When
        // Products are in random order because of the product name mapping.
        // They are sorted here to ensure the same order for unit testing.
        let products = try await remote.loadDomainProducts().sorted(by: { $0.productID < $1.productID })

        // Then
        XCTAssertEqual(products, [
            .init(productID: 355, term: "year", cost: "US$15.00", saleCost: "US$3.90"),
            .init(productID: 356, term: "year", cost: "US$60.00", saleCost: nil)
        ])
    }

    func test_loadDomainProducts_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadDomainProducts()}, errorAssert: { ($0 as? NetworkError) == .notFound })
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
